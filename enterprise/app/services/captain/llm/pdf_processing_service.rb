class Captain::Llm::PdfProcessingService < Llm::LegacyBaseOpenAiService
  include Integrations::LlmInstrumentation

  def initialize(document)
    super()
    @document = document
  end

  def process
    return if document.openai_file_id.present?

    # For Azure, extract text from PDF instead of uploading to OpenAI
    if @is_azure
      extract_pdf_text
    else
      file_id = upload_pdf_to_openai
      raise CustomExceptions::PdfUploadError, I18n.t('captain.documents.pdf_upload_failed') if file_id.blank?
      document.store_openai_file_id(file_id)
    end
  end

  private

  attr_reader :document

  def extract_pdf_text
    text = with_tempfile do |temp_file|
      extract_text_from_pdf(temp_file.path)
    end

    # Store extracted text in document content (max 200,000 chars)
    text = text[0..199_999] if text.length > 200_000
    document.update!(content: text)
    Rails.logger.info "Extracted #{text.length} characters from PDF document #{document.id}"
  rescue StandardError => e
    Rails.logger.error "Failed to extract PDF text: #{e.message}"
    raise CustomExceptions::PdfUploadError, "Failed to extract PDF text: #{e.message}"
  end

  def extract_text_from_pdf(pdf_path)
    # Try using pdf-reader gem first
    if defined?(PDF::Reader)
      extract_with_pdf_reader(pdf_path)
    # Fallback to pdftotext system command if available
    elsif system('which pdftotext > /dev/null 2>&1')
      extract_with_pdftotext(pdf_path)
    # Last resort: try using pdf-reader via require
    else
      begin
        require 'pdf/reader'
        extract_with_pdf_reader(pdf_path)
      rescue LoadError
        raise CustomExceptions::PdfUploadError, 'PDF text extraction requires pdf-reader gem or pdftotext command'
      end
    end
  end

  def extract_with_pdf_reader(pdf_path)
    PDF::Reader.open(pdf_path) do |reader|
      reader.pages.map(&:text).join("\n\n")
    end
  end

  def extract_with_pdftotext(pdf_path)
    output = `pdftotext "#{pdf_path}" - 2>&1`
    raise "pdftotext failed: #{output}" unless $CHILD_STATUS.success?
    output
  end

  def upload_pdf_to_openai
    with_tempfile do |temp_file|
      instrument_file_upload do
        response = @client.files.upload(
          parameters: {
            file: temp_file,
            purpose: 'assistants'
          }
        )
        response['id']
      end
    end
  end

  def instrument_file_upload(&)
    return yield unless ChatwootApp.otel_enabled?

    tracer.in_span('llm.file.upload') do |span|
      span.set_attribute('gen_ai.provider', 'openai')
      span.set_attribute('file.purpose', 'assistants')
      span.set_attribute(ATTR_LANGFUSE_USER_ID, document.account_id.to_s)
      span.set_attribute(ATTR_LANGFUSE_TAGS, ['pdf_upload'].to_json)
      span.set_attribute(format(ATTR_LANGFUSE_METADATA, 'document_id'), document.id.to_s)
      file_id = yield
      span.set_attribute('file.id', file_id) if file_id
      file_id
    end
  end

  def with_tempfile
    Tempfile.create(['pdf_upload', '.pdf'], binmode: true) do |temp_file|
      document.pdf_file.blob.open do |blob_file|
        IO.copy_stream(blob_file, temp_file)
      end

      temp_file.flush
      temp_file.rewind

      yield temp_file
    end
  end
end
