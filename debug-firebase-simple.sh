#!/bin/bash

# Simple Firebase Debug Script
# Shows all Firebase operations in real-time

echo "🚀 Starting Firebase Debug Mode for Breadcrumb WMS..."

# Set debug environment variables
export FIREBASE_DEBUG=true
export FIRESTORE_DEBUG=true
export FIREBASE_AUTH_DEBUG=true
export FIREBASE_STORAGE_DEBUG=true

echo "📊 Debug Environment Set:"
echo "  🔥 FIREBASE_DEBUG: $FIREBASE_DEBUG"
echo "  📚 FIRESTORE_DEBUG: $FIRESTORE_DEBUG"
echo "  🔐 FIREBASE_AUTH_DEBUG: $FIREBASE_AUTH_DEBUG"
echo "  📦 FIREBASE_STORAGE_DEBUG: $FIREBASE_STORAGE_DEBUG"

echo ""
echo "🔍 Starting Firebase Emulators..."
echo "📝 All Firebase operations will be logged to the terminal"
echo "🌐 Emulator UI will be available at: http://localhost:4000"
echo ""

# Start Firebase emulators
firebase emulators:start --only firestore,auth,storage,functions
