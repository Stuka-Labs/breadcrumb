/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.createUserWithRole = functions.https.onCall(async (data, context) => {
  try {
    // No authentication check: allow unauthenticated invocations
    const { email, password, role } = data;
    if (!email || !password || !role) {
      functions.logger.error('Missing required fields', { email, password, role });
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    // Build role object
    const roleObj = {
      admin: role === 'admin',
      client: role === 'client',
      packer: role === 'packer',
    };

    functions.logger.info('Creating user', { email, roleObj });
    const userRecord = await admin.auth().createUser({ email, password });
    // No custom claims set
    await admin.firestore().collection('user').doc(userRecord.uid).set({
      email,
      role: roleObj,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    functions.logger.info('User created successfully', { uid: userRecord.uid });
    return { success: true, uid: userRecord.uid };
  } catch (error) {
    functions.logger.error('Create User Error:', error, { stack: error.stack });
    throw new functions.https.HttpsError('internal', error.message || 'Unknown error', { stack: error.stack });
  }
});

exports.debugAuthContext = functions.https.onCall(async (data, context) => {
  try {
    return {
      auth: context.auth,
      token: context.auth ? context.auth.token : null,
    };
  } catch (error) {
    functions.logger.error('Error in debugAuthContext:', error);
    throw new functions.https.HttpsError('internal', error.message || 'Unknown error');
  }
});

exports.createUserWithRoleHttp = functions.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') {
      return res.status(405).send('Method Not Allowed');
    }
    const { email, password, role } = req.body;
    if (!email || !password || !role) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    const roleObj = {
      admin: role === 'admin',
      client: role === 'client',
      packer: role === 'packer',
    };
    const userRecord = await admin.auth().createUser({ email, password });
    await admin.firestore().collection('user').doc(userRecord.uid).set({
      email,
      role: roleObj,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return res.status(200).json({ success: true, uid: userRecord.uid });
  } catch (error) {
    functions.logger.error('Create User Error (HTTP):', error, { stack: error.stack });
    return res.status(500).json({ error: error.message || 'Unknown error', stack: error.stack });
  }
});
