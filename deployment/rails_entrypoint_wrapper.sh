#!/bin/sh
# Wrapper script to sync custom files before running rails entrypoint

set -e

# Copy custom files if they exist
if [ -d /code ]; then
  echo "Syncing custom files..."
  [ -f /code/app/javascript/dashboard/helper/automationHelper.js ] && cp /code/app/javascript/dashboard/helper/automationHelper.js /app/app/javascript/dashboard/helper/automationHelper.js || true
  [ -f /code/app/javascript/dashboard/routes/dashboard/settings/automation/operators.js ] && cp /code/app/javascript/dashboard/routes/dashboard/settings/automation/operators.js /app/app/javascript/dashboard/routes/dashboard/settings/automation/operators.js || true
  [ -f /code/app/services/filter_service.rb ] && cp /code/app/services/filter_service.rb /app/app/services/filter_service.rb || true
  [ -f /code/config/app.yml ] && cp /code/config/app.yml /app/config/app.yml || true
  [ -f /code/enterprise/app/services/captain/llm/pdf_processing_service.rb ] && cp /code/enterprise/app/services/captain/llm/pdf_processing_service.rb /app/enterprise/app/services/captain/llm/pdf_processing_service.rb || true
  echo "Custom files synced"
fi

# Run original entrypoint with all arguments
exec docker/entrypoints/rails.sh "$@"

