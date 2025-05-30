const functions = require('firebase-functions');
const { createRequestHandler } = require('@remix-run/express');
const express = require('express');
const admin = require('firebase-admin');
const remixBuild = require('./build');

admin.initializeApp();

const app = express();

// Middleware to check Firebase Auth token
app.use(async (req, res, next) => {
  // Allow preflight CORS requests through (for OPTIONS)
  if (req.method === 'OPTIONS') return next();

  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).send('Unauthorized: Missing or invalid Authorization header');
  }
  const idToken = authHeader.split('Bearer ')[1];
  try {
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    req.user = decodedToken;
    next();
  } catch (err) {
    return res.status(401).send('Unauthorized: Invalid token');
  }
});

app.all(
  '*',
  createRequestHandler({
    build: remixBuild,
    mode: process.env.NODE_ENV,
  })
);

exports.remix = functions.https.onRequest(app); 