#!/bin/bash
# Script to prepare all custom files for staging deployment
# This creates a single directory with all customizations that can be mounted

set -e

STAGING_PATCHES_DIR="${STAGING_PATCHES_DIR:-/opt/chatwoot-staging-patches}"
REPO_DIR="${REPO_DIR:-/tmp/chatwoot-staging-repo}"

echo "🔧 Preparing staging customizations..."
echo "========================================"

# Create staging patches directory (with sudo if needed)
if [ ! -d "${STAGING_PATCHES_DIR}" ]; then
    echo "📁 Creating staging patches directory..."
    if mkdir -p "${STAGING_PATCHES_DIR}" 2>/dev/null; then
        echo "   ✅ Created: ${STAGING_PATCHES_DIR}"
    else
        echo "   ⚠️  Permission denied, trying with sudo..."
        if sudo mkdir -p "${STAGING_PATCHES_DIR}"; then
            sudo chown -R $USER:$USER "${STAGING_PATCHES_DIR}" 2>/dev/null || true
            echo "   ✅ Created with sudo: ${STAGING_PATCHES_DIR}"
        else
            echo "   ❌ Could not create directory. Please run:"
            echo "      sudo mkdir -p ${STAGING_PATCHES_DIR}"
            echo "      sudo chown -R $USER:$USER ${STAGING_PATCHES_DIR}"
            exit 1
        fi
    fi
else
    echo "   ✅ Directory already exists: ${STAGING_PATCHES_DIR}"
fi

# Clone or update repo if needed
if [ ! -d "${REPO_DIR}/.git" ]; then
    echo "📥 Cloning repository..."
    git clone https://github.com/lucouto/chatwoot.fazer.ai.git "${REPO_DIR}" || {
        echo "⚠️  Could not clone repo, using existing files if available"
    }
else
    echo "🔄 Updating repository..."
    cd "${REPO_DIR}"
    git pull origin main || echo "⚠️  Could not pull, using existing files"
fi

echo ""
echo "📋 Copying custom files..."

# Create directory structure
mkdir -p "${STAGING_PATCHES_DIR}/app/javascript/dashboard/helper"
mkdir -p "${STAGING_PATCHES_DIR}/app/javascript/dashboard/routes/dashboard/settings/automation"
mkdir -p "${STAGING_PATCHES_DIR}/app/services"
mkdir -p "${STAGING_PATCHES_DIR}/config"
mkdir -p "${STAGING_PATCHES_DIR}/enterprise/app/services/llm"
mkdir -p "${STAGING_PATCHES_DIR}/enterprise/app/services/captain/llm"
mkdir -p "${STAGING_PATCHES_DIR}/lib/integrations"

# Copy custom files
echo "  ✓ JavaScript files..."
[ -f "${REPO_DIR}/app/javascript/dashboard/helper/automationHelper.js" ] && \
    cp "${REPO_DIR}/app/javascript/dashboard/helper/automationHelper.js" \
       "${STAGING_PATCHES_DIR}/app/javascript/dashboard/helper/automationHelper.js" && \
    echo "    - automationHelper.js"

[ -f "${REPO_DIR}/app/javascript/dashboard/routes/dashboard/settings/automation/operators.js" ] && \
    cp "${REPO_DIR}/app/javascript/dashboard/routes/dashboard/settings/automation/operators.js" \
       "${STAGING_PATCHES_DIR}/app/javascript/dashboard/routes/dashboard/settings/automation/operators.js" && \
    echo "    - operators.js"

echo "  ✓ Ruby service files..."
[ -f "${REPO_DIR}/app/services/filter_service.rb" ] && \
    cp "${REPO_DIR}/app/services/filter_service.rb" \
       "${STAGING_PATCHES_DIR}/app/services/filter_service.rb" && \
    echo "    - filter_service.rb"

echo "  ✓ Config files..."
[ -f "${REPO_DIR}/config/app.yml" ] && \
    cp "${REPO_DIR}/config/app.yml" \
       "${STAGING_PATCHES_DIR}/config/app.yml" && \
    echo "    - app.yml"

echo "  ✓ Enterprise LLM services..."
[ -f "${REPO_DIR}/enterprise/app/services/llm/legacy_base_open_ai_service.rb" ] && \
    cp "${REPO_DIR}/enterprise/app/services/llm/legacy_base_open_ai_service.rb" \
       "${STAGING_PATCHES_DIR}/enterprise/app/services/llm/legacy_base_open_ai_service.rb" && \
    echo "    - legacy_base_open_ai_service.rb"

[ -f "${REPO_DIR}/enterprise/app/services/captain/llm/pdf_processing_service.rb" ] && \
    cp "${REPO_DIR}/enterprise/app/services/captain/llm/pdf_processing_service.rb" \
       "${STAGING_PATCHES_DIR}/enterprise/app/services/captain/llm/pdf_processing_service.rb" && \
    echo "    - pdf_processing_service.rb"

echo "  ✓ Integrations module..."
if [ -d "${REPO_DIR}/lib/integrations" ]; then
    cp -r "${REPO_DIR}/lib/integrations"/* "${STAGING_PATCHES_DIR}/lib/integrations/" 2>/dev/null && \
    echo "    - lib/integrations/*"
fi

echo ""
echo "✅ Staging patches prepared in: ${STAGING_PATCHES_DIR}"
echo ""
echo "📊 Summary:"
find "${STAGING_PATCHES_DIR}" -type f | wc -l | xargs echo "  Total files:"
du -sh "${STAGING_PATCHES_DIR}" | cut -f1 | xargs echo "  Total size:"
echo ""
echo "💡 Next step: Update docker-compose.staging.yaml to mount this directory"

