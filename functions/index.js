const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');

admin.initializeApp();

// Configure your email transport (example: Gmail, replace with your SMTP)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.NOTIFY_EMAIL_USER,
    pass: process.env.NOTIFY_EMAIL_PASS,
  },
});

exports.notifyOrderFulfilled = onDocumentUpdated('orders/{orderId}', async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
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
          orderId: event.params.orderId,
          email: clientEmail,
          timestamp: new Date().toISOString(),
        });
      } catch (error) {
        await admin.firestore().collection('logs').add({
          type: 'notification',
          action: 'order_fulfilled_email_failed',
          orderId: event.params.orderId,
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

// Add the missing functions that are already deployed
exports.createUserWithRole = functions.https.onCall(async (data, context) => {
  try {
    const { email, password, role } = data;
    if (!email || !password || !role) {
      functions.logger.error('Missing required fields', { email, password, role });
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    const roleObj = {
      admin: role === 'admin',
      client: role === 'client',
      packer: role === 'packer',
    };

    functions.logger.info('Creating user', { email, roleObj });
    const userRecord = await admin.auth().createUser({ email, password });
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
    
    const userSnapshot = await admin.firestore().collection('user').get();
    console.log(`Found ${userSnapshot.size} users in 'user' collection`);
    
    if (userSnapshot.empty) {
      return { message: 'No users to migrate', count: 0 };
    }
    
    let migratedCount = 0;
    
    for (const doc of userSnapshot.docs) {
      const userData = doc.data();
      console.log(`Migrating user: ${userData.email}`);
      
      let role = 'client';
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

// Simple remix function placeholder
exports.remix = functions.https.onRequest((req, res) => {
  res.status(200).json({ message: 'Remix function is running' });
}); 