const functions = require('firebase-functions');
const { createRequestHandler } = require('@remix-run/express');
const express = require('express');
const admin = require('firebase-admin');
const remixBuild = require('./build');
const nodemailer = require('nodemailer');

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

// Configure your email transport (example: Gmail, replace with your SMTP)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.NOTIFY_EMAIL_USER,
    pass: process.env.NOTIFY_EMAIL_PASS,
  },
});

exports.notifyOrderFulfilled = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status !== 'fulfilled' && after.status === 'fulfilled') {
      const clientEmail = after.customer?.email;
      if (!clientEmail) return null;
      const mailOptions = {
        from: process.env.NOTIFY_EMAIL_USER,
        to: clientEmail,
        subject: `Your Order ${after.name} Has Been Fulfilled!`,
        text: `Hello,\n\nYour order ${after.name} has been fulfilled and is on its way!\n\nThank you for using Breadcrumb.`,
      };
      try {
        await transporter.sendMail(mailOptions);
        await admin.firestore().collection('logs').add({
          type: 'notification',
          action: 'order_fulfilled_email',
          orderId: context.params.orderId,
          email: clientEmail,
          timestamp: new Date().toISOString(),
        });
      } catch (error) {
        await admin.firestore().collection('logs').add({
          type: 'notification',
          action: 'order_fulfilled_email_failed',
          orderId: context.params.orderId,
          email: clientEmail,
          error: error.message || String(error),
          timestamp: new Date().toISOString(),
        });
      }
    }
    return null;
  });

// Import the test user setup function
const { setupTestUser } = require('./setupTestUser');

// Export the test user setup function
exports.setupTestUser = setupTestUser;

exports.remix = functions.https.onRequest(app); 