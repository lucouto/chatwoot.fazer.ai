#!/bin/bash
# Script to install staging setup on Coolify server
# Run this via SSH: ssh coolify-vm "bash -s" < deployment/install_staging_on_server.sh

set -e

echo "🚀 Installing staging setup on Coolify server..."
echo "================================================"

# Detect user home
USER_HOME="${HOME:-/home/$USER}"
PATCHES_DIR="${USER_HOME}/chatwoot-staging-patches"
REPO_DIR="/tmp/chatwoot-staging-repo"

echo "📁 Patches directory: ${PATCHES_DIR}"
echo "📁 Repo directory: ${REPO_DIR}"
echo ""

# Clone or update repo
if [ ! -d "${REPO_DIR}/.git" ]; then
    echo "📥 Cloning repository..."
    git clone https://github.com/lucouto/chatwoot.fazer.ai.git "${REPO_DIR}"
else
    echo "🔄 Updating repository..."
    cd "${REPO_DIR}"
    git pull origin main || echo "⚠️  Could not pull, continuing with existing files"
fi

# Run prepare script
echo ""
echo "🔧 Preparing staging files..."
cd "${REPO_DIR}"
chmod +x deployment/prepare_staging_files.sh
export STAGING_PATCHES_DIR="${PATCHES_DIR}"
./deployment/prepare_staging_files.sh

echo ""
echo "✅ Installation complete!"
echo ""
echo "📋 Next steps in Coolify:"
echo "   1. Add environment variable:"
echo "      Name: STAGING_PATCHES_DIR"
echo "      Value: ${PATCHES_DIR}"
echo "   2. Update docker-compose to: docker-compose.staging-simple.yaml"
echo "   3. Deploy!"

