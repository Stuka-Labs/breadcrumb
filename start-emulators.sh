#!/bin/bash

# Start Firebase Emulators for Breadcrumb WMS
# This script starts all necessary emulators for local development

echo "🚀 Starting Firebase Emulators for Breadcrumb WMS..."

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
echo "📚 Firestore will be available at: localhost:8081"
echo "🔐 Auth will be available at: localhost:9099"
echo "📦 Storage will be available at: localhost:9199"
echo ""

# Start Firebase emulators
firebase emulators:start --only firestore,auth,storage,functions
