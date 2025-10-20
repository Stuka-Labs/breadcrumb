#!/bin/bash

# Firebase Debug Script
# This script enables comprehensive debugging for all Firebase operations

echo "🚀 Starting Firebase Debug Mode..."

# Set Firebase debug environment variables
export FIREBASE_DEBUG=true
export FIRESTORE_DEBUG=true
export FIREBASE_AUTH_DEBUG=true
export FIREBASE_STORAGE_DEBUG=true
export FIREBASE_FUNCTIONS_DEBUG=true
export FIREBASE_ANALYTICS_DEBUG=true
export FIREBASE_PERFORMANCE_DEBUG=true

# Set Flutter debug flags
export FLUTTER_DEBUG=true
export FLUTTER_VERBOSE=true

echo "📊 Firebase Debug Environment Variables Set:"
echo "  FIREBASE_DEBUG: $FIREBASE_DEBUG"
echo "  FIRESTORE_DEBUG: $FIRESTORE_DEBUG"
echo "  FIREBASE_AUTH_DEBUG: $FIREBASE_AUTH_DEBUG"
echo "  FIREBASE_STORAGE_DEBUG: $FIREBASE_STORAGE_DEBUG"
echo "  FIREBASE_FUNCTIONS_DEBUG: $FIREBASE_FUNCTIONS_DEBUG"
echo "  FIREBASE_ANALYTICS_DEBUG: $FIREBASE_ANALYTICS_DEBUG"
echo "  FIREBASE_PERFORMANCE_DEBUG: $FIREBASE_PERFORMANCE_DEBUG"
echo "  FLUTTER_DEBUG: $FLUTTER_DEBUG"
echo "  FLUTTER_VERBOSE: $FLUTTER_VERBOSE"

echo ""
echo "🔍 Starting Firebase Emulator with Debug Logging..."
echo "📝 All Firebase operations will be logged to the terminal"
echo ""

# Start Firebase emulator with debug logging
firebase emulators:start --only firestore,auth,storage,functions --inspect-functions --debug

echo ""
echo "✅ Firebase Debug Mode Started!"
echo "📱 Now run your Flutter app to see all Firebase operations logged in real-time"
echo "🔍 Check the terminal for detailed Firebase operation logs"
