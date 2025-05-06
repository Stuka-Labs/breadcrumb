const admin = require('firebase-admin');
admin.initializeApp();

async function setAdminClaim() {
  const uid = '2x2vUr1QcZc0R9ofPeJzSbQJLx83'; // fed@gmail.com
  await admin.auth().setCustomUserClaims(uid, { admin: true });
  console.log('Admin claim set for fed@gmail.com');
}

setAdminClaim().then(() => process.exit(0)); 