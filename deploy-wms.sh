#!/bin/bash

# Deploy WMS (breadcrumb-bd857) to Firebase Hosting
# This script builds Flutter web, copies to public, and deploys

set -e

echo "🚀 Starting WMS deployment process..."
echo ""

# Step 1: Clean previous build
echo "📦 Cleaning previous build..."
rm -rf build/web

# Step 2: Build Flutter web
echo "🔨 Building Flutter web application..."
flutter build web --release

# Step 3: Copy build files to public directory
echo "📋 Copying build files to public directory..."
rm -rf public/*
cp -R build/web/* public/

# Step 4: Verify the main file was updated
if [ -f "public/main.dart.js" ]; then
    echo "✅ Build files copied successfully"
    echo "   main.dart.js timestamp: $(stat -f "%Sm" public/main.dart.js)"
else
    echo "❌ Error: main.dart.js not found in public directory"
    exit 1
fi

# Step 5: Fix Firebase CLI template path issue (if exists)
if [ -d "node_modules/firebase-tools/templates" ] && [ ! -d "node_modules/firebase-tools/lib/templates" ]; then
  echo ""
  echo "🔧 Fixing Firebase CLI template paths..."
  cp -r node_modules/firebase-tools/templates node_modules/firebase-tools/lib/ 2>/dev/null || true
fi

# Step 6: Deploy to Firebase
echo ""
echo "🔥 Deploying to Firebase Hosting (breadcrumb-bd857)..."
# Use local installation if available, otherwise use npx
if [ -d "node_modules/firebase-tools" ]; then
  npx firebase-tools deploy --only hosting:breadcrumb-bd857
else
  npx -y firebase-tools@13.20.0 deploy --only hosting:breadcrumb-bd857
fi

echo ""
echo "✅ Deployment complete!"
echo "🌐 Your app is live at: https://breadcrumb-bd857.web.app"
echo ""
echo "💡 If you see an old version, try:"
echo "   - Hard refresh (Cmd+Shift+R on Mac, Ctrl+Shift+R on Windows)"
echo "   - Clear browser cache"
echo "   - Wait 1-2 minutes for CDN propagation"

