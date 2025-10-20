#!/bin/bash

# Run Flutter App with Comprehensive Firebase Debugging
# This will show ALL Firebase operations in real-time

echo "🚀 Starting Breadcrumb WMS with Comprehensive Firebase Debugging..."
echo ""

# Set debug environment variables
export FIREBASE_DEBUG=true
export FIRESTORE_DEBUG=true
export FIREBASE_AUTH_DEBUG=true
export FIREBASE_STORAGE_DEBUG=true
export FLUTTER_DEBUG=true
export FLUTTER_VERBOSE=true

echo "📊 Debug Environment Configured:"
echo "  🔥 FIREBASE_DEBUG: $FIREBASE_DEBUG"
echo "  📚 FIRESTORE_DEBUG: $FIRESTORE_DEBUG"
echo "  🔐 FIREBASE_AUTH_DEBUG: $FIREBASE_AUTH_DEBUG"
echo "  📦 FIREBASE_STORAGE_DEBUG: $FIREBASE_STORAGE_DEBUG"
echo "  📱 FLUTTER_DEBUG: $FLUTTER_DEBUG"
echo "  🔍 FLUTTER_VERBOSE: $FLUTTER_VERBOSE"

echo ""
echo "🔍 Starting Flutter app with comprehensive Firebase debugging..."
echo "📝 ALL Firebase operations will be logged to the terminal in real-time"
echo "🔍 Check the terminal for detailed Firebase operation logs"
echo ""

# Run Flutter app with maximum debugging
flutter run --debug --verbose
