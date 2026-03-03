const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();
const db = admin.firestore();

// ──────────────── Send OTP ────────────────
exports.sendOTP = functions.https.onCall(async (data, context) => {
  const { email } = data;

  if (!email || typeof email !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Email is required.');
  }

  // Generate 6-digit OTP
  const otp = crypto.randomInt(100000, 999999).toString();
  const expiresAt = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + 5 * 60 * 1000) // 5 minutes
  );

  // Store OTP in Firestore
  await db.collection('otps').doc(email).set({
    otp,
    email,
    expiresAt,
    attempts: 0,
    verified: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // TODO: Send email via SendGrid
  // const sgMail = require('@sendgrid/mail');
  // sgMail.setApiKey(functions.config().sendgrid.key);
  // await sgMail.send({
  //   to: email,
  //   from: 'noreply@yourapp.com',
  //   subject: 'Your OTP for Face Detection Pro',
  //   text: `Your OTP is: ${otp}. It expires in 5 minutes.`,
  // });

  console.log(`OTP for ${email}: ${otp}`);
  return { success: true, message: 'OTP sent successfully.' };
});

// ──────────────── Verify OTP ────────────────
exports.verifyOTP = functions.https.onCall(async (data, context) => {
  const { email, otp } = data;

  if (!email || !otp) {
    throw new functions.https.HttpsError('invalid-argument', 'Email and OTP are required.');
  }

  const otpDoc = await db.collection('otps').doc(email).get();
  if (!otpDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'OTP not found. Please request a new one.');
  }

  const otpData = otpDoc.data();
  const attempts = otpData.attempts || 0;

  // Rate limit: max 3 attempts
  if (attempts >= 3) {
    throw new functions.https.HttpsError('resource-exhausted', 'Too many attempts. Request a new OTP.');
  }

  // Check expiry
  const expiresAt = otpData.expiresAt.toDate();
  if (new Date() > expiresAt) {
    throw new functions.https.HttpsError('deadline-exceeded', 'OTP has expired. Please request a new one.');
  }

  // Increment attempts
  await db.collection('otps').doc(email).update({ attempts: attempts + 1 });

  // Validate OTP
  if (otpData.otp !== otp) {
    throw new functions.https.HttpsError('unauthenticated', 'Invalid OTP.');
  }

  // Mark as verified
  await db.collection('otps').doc(email).update({ verified: true });

  // Update user emailVerified status
  const usersSnap = await db.collection('users')
    .where('email', '==', email)
    .limit(1)
    .get();

  if (!usersSnap.empty) {
    await usersSnap.docs[0].ref.update({
      emailVerified: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  return { success: true };
});

// ──────────────── Cleanup Expired OTPs ────────────────
exports.cleanupExpiredOTPs = functions.pubsub
  .schedule('every 60 minutes')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const snapshot = await db.collection('otps')
      .where('expiresAt', '<', now)
      .get();

    const batch = db.batch();
    snapshot.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();

    console.log(`Deleted ${snapshot.size} expired OTPs.`);
    return null;
  });
