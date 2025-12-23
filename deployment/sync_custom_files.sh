#!/bin/sh
# Sync custom files from git repo to app directory
# This allows using fazer-ai pre-built image with custom modifications

set -e

CUSTOM_CODE_DIR=${CUSTOM_CODE_DIR:-/code}
APP_DIR=${APP_DIR:-/app}

# List of files/directories to sync (only your custom modifications)
FILES_TO_SYNC="
app/javascript/dashboard/helper/automationHelper.js
app/javascript/dashboard/routes/dashboard/settings/automation/operators.js
app/services/filter_service.rb
config/app.yml
enterprise/app/services/captain/llm/pdf_processing_service.rb
"

echo "Syncing custom files from ${CUSTOM_CODE_DIR} to ${APP_DIR}..."

for file in ${FILES_TO_SYNC}; do
  src="${CUSTOM_CODE_DIR}/${file}"
  dest="${APP_DIR}/${file}"
  
  if [ -f "${src}" ]; then
    # Create destination directory if needed
    mkdir -p "$(dirname "${dest}")"
    # Copy file
    cp -f "${src}" "${dest}"
    echo "✓ Synced: ${file}"
  elif [ -d "${src}" ]; then
    # For directories, copy recursively
    mkdir -p "${dest}"
    cp -rf "${src}"/* "${dest}/" 2>/dev/null || true
    echo "✓ Synced directory: ${file}"
  else
    echo "⚠ Warning: ${file} not found in custom code"
  fi
done

echo "Custom files sync completed!"

