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
    if (!context.auth || !context.auth.token.admin) {
      throw new functions.https.HttpsError('permission-denied', 'Not authorized');
    }
    const { email, password, role } = data;
    if (!email || !password || !role) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }
    const userRecord = await admin.auth().createUser({ email, password });
    await admin.auth().setCustomUserClaims(userRecord.uid, { role });
    await admin.firestore().collection('users').doc(userRecord.uid).set({
      email,
      role,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { success: true, uid: userRecord.uid };
  } catch (error) {
    functions.logger.error('Create User Error:', error);
    throw new functions.https.HttpsError('internal', error.message);
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
