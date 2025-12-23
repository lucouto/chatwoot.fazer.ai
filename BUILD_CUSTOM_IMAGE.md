# Building Custom Docker Image with Azure OpenAI Support

## The Situation

You're using the pre-built image `ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee`, so local code changes won't be in your container. We need to build a custom image with the Azure OpenAI fix.

## Option 1: Build Custom Image (Recommended)

### Step 1: Fork and Clone

```bash
# If you haven't already forked fazer-ai/chatwoot
# Fork it on GitHub, then:
git clone https://github.com/YOUR-USERNAME/chatwoot.git
cd chatwoot
```

### Step 2: Apply Azure Fix

Copy the modified `base_open_ai_service.rb` to your fork:

```bash
# The file is already modified in your local fork
# Just commit and push it
git add enterprise/app/services/llm/base_open_ai_service.rb
git commit -m "Add Azure OpenAI support to Captain AI"
git push origin main
```

### Step 3: Build Docker Image

```bash
# Build the image
docker build -t your-registry/chatwoot:v4.8.0-fazer-ai.2-ee-azure \
  -f docker/Dockerfile .

# Tag it
docker tag your-registry/chatwoot:v4.8.0-fazer-ai.2-ee-azure \
  your-registry/chatwoot:latest-ee-azure
```

### Step 4: Push to Registry

```bash
# Push to your registry (Docker Hub, GitHub Container Registry, etc.)
docker push your-registry/chatwoot:v4.8.0-fazer-ai.2-ee-azure
docker push your-registry/chatwoot:latest-ee-azure
```

### Step 5: Update Coolify

In your docker-compose, change:
```yaml
image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee'
```

To:
```yaml
image: 'your-registry/chatwoot:v4.8.0-fazer-ai.2-ee-azure'
```

---

## Option 2: Volume Mount (Temporary/Quick Fix)

Mount the modified file as a volume in Coolify:

### Step 1: Copy File to Your VPS

```bash
# On your VPS, create directory
mkdir -p /path/to/chatwoot-patches/enterprise/app/services/llm

# Copy the modified file
# (You'll need to get the file content and save it)
```

### Step 2: Update docker-compose in Coolify

Add volume mount to `rails` and `sidekiq` services:

```yaml
rails:
  image: 'ghcr.io/fazer-ai/chatwoot:v4.8.0-fazer-ai.2-ee'
  volumes:
    - 'storage:/app/storage'
    - 'assets:/app/public/assets'
    - '/path/to/chatwoot-patches/enterprise/app/services/llm/base_open_ai_service.rb:/app/enterprise/app/services/llm/base_open_ai_service.rb:ro'
  # ... rest of config
```

**⚠️ Warning:** This is fragile and may break on updates. Not recommended for production.

---

## Option 3: Use GitHub Actions (Automated)

If you fork the repository, you can set up GitHub Actions to automatically build and push images when you push changes.

---

## Recommended: Option 1 (Custom Image)

This is the cleanest approach:

1. ✅ Permanent solution
2. ✅ Easy to maintain
3. ✅ Works with Coolify
4. ✅ Can update fazer-ai base and reapply fix

### Quick Build Script

```bash
#!/bin/bash
# build-azure-image.sh

VERSION="v4.8.0-fazer-ai.2-ee-azure"
REGISTRY="your-registry"  # Change to your registry

echo "Building custom image with Azure OpenAI support..."
docker build -t ${REGISTRY}/chatwoot:${VERSION} -f docker/Dockerfile .

echo "Tagging as latest..."
docker tag ${REGISTRY}/chatwoot:${VERSION} ${REGISTRY}/chatwoot:latest-ee-azure

echo "Pushing to registry..."
docker push ${REGISTRY}/chatwoot:${VERSION}
docker push ${REGISTRY}/chatwoot:latest-ee-azure

echo "Done! Update Coolify to use: ${REGISTRY}/chatwoot:${VERSION}"
```

---

## Which Registry to Use?

### GitHub Container Registry (Recommended if you fork on GitHub)

```bash
# Login
echo $GITHUB_TOKEN | docker login ghcr.io -u YOUR-USERNAME --password-stdin

# Build and push
docker build -t ghcr.io/YOUR-USERNAME/chatwoot:v4.8.0-fazer-ai.2-ee-azure -f docker/Dockerfile .
docker push ghcr.io/YOUR-USERNAME/chatwoot:v4.8.0-fazer-ai.2-ee-azure
```

### Docker Hub

```bash
docker build -t YOUR-USERNAME/chatwoot:v4.8.0-fazer-ai.2-ee-azure -f docker/Dockerfile .
docker push YOUR-USERNAME/chatwoot:v4.8.0-fazer-ai.2-ee-azure
```

### Private Registry

Use your own registry URL.

---

## After Building

1. Update Coolify docker-compose to use your custom image
2. Redeploy
3. Test Captain playground with Azure OpenAI

---

## Maintenance

When fazer-ai releases a new version:

1. Pull their latest changes
2. Reapply the Azure fix
3. Rebuild image with new version tag
4. Update Coolify

---

## Need Help?

If you need help with:
- Setting up the build process
- Choosing a registry
- Creating the build script
- Applying the fix to your fork

Let me know!


