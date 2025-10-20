#!/bin/bash

# Run Flutter App with Maximum Firebase Debugging
# This script enables comprehensive debugging for all Firebase operations

echo "🚀 Starting Breadcrumb WMS with Maximum Firebase Debugging..."

# Set comprehensive debug environment variables
export FIREBASE_DEBUG=true
export FIRESTORE_DEBUG=true
export FIREBASE_AUTH_DEBUG=true
export FIREBASE_STORAGE_DEBUG=true
export FIREBASE_FUNCTIONS_DEBUG=true
export FIREBASE_ANALYTICS_DEBUG=true
export FIREBASE_PERFORMANCE_DEBUG=true
export FLUTTER_DEBUG=true
export FLUTTER_VERBOSE=true

# Set Firebase project
export FIREBASE_PROJECT_ID="breadcrumb-bd857"

echo "📊 Debug Environment Configured:"
echo "  🔥 FIREBASE_DEBUG: $FIREBASE_DEBUG"
echo "  📚 FIRESTORE_DEBUG: $FIRESTORE_DEBUG"
echo "  🔐 FIREBASE_AUTH_DEBUG: $FIREBASE_AUTH_DEBUG"
echo "  📦 FIREBASE_STORAGE_DEBUG: $FIREBASE_STORAGE_DEBUG"
echo "  ⚡ FIREBASE_FUNCTIONS_DEBUG: $FIREBASE_FUNCTIONS_DEBUG"
echo "  📈 FIREBASE_ANALYTICS_DEBUG: $FIREBASE_ANALYTICS_DEBUG"
echo "  🚀 FIREBASE_PERFORMANCE_DEBUG: $FIREBASE_PERFORMANCE_DEBUG"
echo "  📱 FLUTTER_DEBUG: $FLUTTER_DEBUG"
echo "  🔍 FLUTTER_VERBOSE: $FLUTTER_VERBOSE"
echo "  🏢 FIREBASE_PROJECT_ID: $FIREBASE_PROJECT_ID"

echo ""
echo "🔍 Starting Firebase Emulator with Debug Logging..."
echo "📝 All Firebase operations will be logged to the terminal"
echo ""

# Start Firebase emulator in background
firebase emulators:start --only firestore,auth,storage,functions --inspect-functions &
FIREBASE_PID=$!

echo "🔥 Firebase Emulator started with PID: $FIREBASE_PID"
echo "⏳ Waiting for Firebase emulator to be ready..."

# Wait for Firebase emulator to be ready
sleep 8

echo ""
echo "📱 Starting Flutter app with maximum debugging..."
echo "🔍 Check the terminal for detailed Firebase operation logs"
echo ""

# Run Flutter app with maximum debugging (fixed command)
flutter run --debug --verbose

echo ""
echo "🛑 Stopping Firebase emulator..."
kill $FIREBASE_PID 2>/dev/null || true

echo "✅ Debug session completed!"
