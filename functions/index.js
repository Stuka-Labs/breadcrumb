const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");

// Set global options
setGlobalOptions({
  maxInstances: 10,
  memory: "1GiB",
  timeoutSeconds: 60,
});

// Create request handler for Remix app
const requestHandler = async (req, res) => {
  try {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    // Handle preflight requests
    if (req.method === 'OPTIONS') {
      res.status(200).end();
      return;
    }

    // Import the Remix serverless function dynamically
    const { createRequestHandler } = require("@remix-run/express");
    const { installGlobals } = require("@remix-run/node");
    
    // Install globals
    installGlobals();
    
    // Import the server build
    const serverBuild = require("../breadcrumb/build/server/index.js");
    
    // Create the request handler
    const handler = createRequestHandler(serverBuild, "production");
    
    // Handle the request
    await handler(req, res);
    
  } catch (error) {
    console.error('Function error:', error);
    res.status(500).send('Internal Server Error');
  }
};

// Export the Firebase function
exports.remixApp = onRequest({
  region: "us-central1",
  cors: true,
}, requestHandler);