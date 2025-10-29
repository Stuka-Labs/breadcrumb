#!/bin/bash
echo "====================================="
echo "Deploying to Shopify - Follow prompts"
echo "====================================="
cd /Users/sammy/Desktop/breadcrumb

# Deploy to Shopify
npx shopify app deploy

echo ""
echo "Deployment complete!"
