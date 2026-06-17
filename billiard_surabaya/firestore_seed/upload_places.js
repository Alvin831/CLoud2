/**
 * Script upload data biliar ke Firestore
 * 
 * Cara pakai:
 * 1. Install Node.js jika belum ada
 * 2. npm install firebase-admin
 * 3. Download service account key dari Firebase Console:
 *    Project Settings → Service Accounts → Generate New Private Key
 *    Simpan sebagai serviceAccountKey.json di folder ini
 * 4. node upload_places.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
const places = require('./places.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function uploadPlaces() {
  console.log(`Mengupload ${places.length} data biliar ke Firestore...`);
  
  const batch = db.batch();
  
  places.forEach((place, index) => {
    // Gunakan ID otomatis dari Firestore
    const docRef = db.collection('places').doc();
    batch.set(docRef, place);
    console.log(`  [${index + 1}] ${place.name}`);
  });

  await batch.commit();
  console.log('\n✅ Semua data berhasil diupload!');
  console.log(`Collection: places | Total: ${places.length} dokumen`);
  process.exit(0);
}

uploadPlaces().catch((err) => {
  console.error('❌ Error:', err);
  process.exit(1);
});
