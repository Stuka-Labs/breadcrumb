# WMS Deployment Instructions

## Problem Identified
The deployment wasn't working because:
1. Flutter builds to `build/web/` directory
2. Firebase Hosting deploys from `public/` directory
3. The files weren't being copied from `build/web/` to `public/` before deployment

## Solution
I've created a deployment script that automates this process.

## Quick Deploy
Run this command:
```bash
./deploy-wms.sh
```

## Manual Deploy Steps
If the script doesn't work, follow these steps:

1. **Build Flutter Web:**
   ```bash
   flutter build web --release
   ```

2. **Copy build files to public:**
   ```bash
   rm -rf public/*
   cp -R build/web/* public/
   ```

3. **Verify the copy worked:**
   ```bash
   ls -lh public/main.dart.js
   ```
   The timestamp should be recent (just built).

4. **Deploy to Firebase:**
   ```bash
   firebase deploy --only hosting:breadcrumb-bd857
   ```

## After Deployment
- Wait 1-2 minutes for CDN propagation
- Hard refresh your browser (Cmd+Shift+R on Mac, Ctrl+Shift+R on Windows)
- Clear browser cache if you still see old version

## Verify Deployment
Check the file timestamp in Firebase Console:
- Go to Firebase Console > Hosting
- Check the deployment timestamp
- Verify `main.dart.js` size matches the latest build

