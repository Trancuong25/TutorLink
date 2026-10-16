// Chạy cục bộ; service account bắt buộc nằm ngoài repository.
const fs = require('node:fs');
const path = require('node:path');
const { initializeApp, applicationDefault, deleteApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

async function main() {
  const [uid, projectId] = process.argv.slice(2);
  if (!uid || !projectId) throw new Error('Dùng: node scripts/admin/set_admin.js <uid> <project-id>');
  const credentialFile = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  if (!credentialFile) throw new Error('Thiếu GOOGLE_APPLICATION_CREDENTIALS.');
  const repo = fs.realpathSync(path.resolve(__dirname, '../..'));
  const resolved = fs.realpathSync(credentialFile);
  const relative = path.relative(repo, resolved);
  if (!relative.startsWith('..' + path.sep) && !path.isAbsolute(relative)) {
    throw new Error('Service account phải đặt NGOÀI repository.');
  }
  const app = initializeApp({ credential: applicationDefault(), projectId });
  try {
    await getAuth().getUser(uid);
    const ref = getFirestore().collection('users').doc(uid);
    await getFirestore().runTransaction(async tx => {
      const doc = await tx.get(ref);
      if (!doc.exists) throw new Error('Hãy đăng ký và hoàn tất hồ sơ trên app trước.');
      // Không tự mở khóa hoặc chỉnh các trường khác khi cấp vai trò.
      tx.update(ref, { role: 'admin' });
    });
    console.log('Đã cấp admin cho UID ' + uid + ' trong project ' + projectId);
  } finally { await deleteApp(app); }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
