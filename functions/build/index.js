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
const express = require('express');
const { createRequestHandler } = require('@remix-run/express');
const remixBuild = require('.');
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
    await admin.firestore().collection('users').doc(userRecord.uid).set({
      email,
      role: role,
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
    await admin.firestore().collection('users').doc(userRecord.uid).set({
      email,
      role: role,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return res.status(200).json({ success: true, uid: userRecord.uid });
  } catch (error) {
    functions.logger.error('Create User Error (HTTP):', error, { stack: error.stack });
    return res.status(500).json({ error: error.message || 'Unknown error', stack: error.stack });
  }
});

exports.migrateUsers = functions.https.onCall(async (data, context) => {
  try {
    console.log('Starting user migration...');
    
    // Get all users from the 'user' collection (singular)
    const userSnapshot = await admin.firestore().collection('user').get();
    console.log(`Found ${userSnapshot.size} users in 'user' collection`);
    
    if (userSnapshot.empty) {
      return { message: 'No users to migrate', count: 0 };
    }
    
    let migratedCount = 0;
    
    // Migrate each user
    for (const doc of userSnapshot.docs) {
      const userData = doc.data();
      console.log(`Migrating user: ${userData.email}`);
      
      // Convert role object to simple string
      let role = 'client'; // default role
      if (userData.role) {
        if (typeof userData.role === 'string') {
          role = userData.role;
        } else if (userData.role.admin) {
          role = 'admin';
        } else if (userData.role.client) {
          role = 'client';
        } else if (userData.role.packer) {
          role = 'packer';
        }
      }
      
      // Create new user document in 'users' collection
      await admin.firestore().collection('users').doc(doc.id).set({
        email: userData.email,
        role: role,
        username: userData.username || '',
        createdAt: userData.createdAt || admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'active',
        warehouseId: userData.warehouseId || '',
        customerId: userData.customerId || '',
        lastLogin: userData.lastLogin || admin.firestore.FieldValue.serverTimestamp()
      });
      
      migratedCount++;
      console.log(`✓ Migrated ${userData.email} with role: ${role}`);
    }
    
    console.log(`Migration completed successfully! Migrated ${migratedCount} users.`);
    return { 
      message: 'Migration completed successfully!', 
      count: migratedCount,
      details: `Migrated ${migratedCount} users from 'user' to 'users' collection`
    };
    
  } catch (error) {
    console.error('Migration failed:', error);
    throw new functions.https.HttpsError('internal', error.message || 'Migration failed');
  }
});

const app = express();

app.all(
  '/',
  createRequestHandler({
    build: remixBuild,
    mode: process.env.NODE_ENV,
  })
);

exports.remix = functions.https.onRequest(app);
