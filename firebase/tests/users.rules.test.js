import { readFileSync } from 'node:fs';
import { beforeAll, afterAll, beforeEach, describe, it } from 'vitest';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc, getDoc, getDocs, collection, deleteDoc, serverTimestamp, Timestamp } from 'firebase/firestore';

let env;
const user = (role = 'learner', extra = {}) => ({
  displayName: 'Người thử nghiệm', email: 'user@example.com', role,
  isLocked: false, createdAt: serverTimestamp(), ...extra,
});
const db = (uid = 'u', email = 'user@example.com') => env.authenticatedContext(uid, {email}).firestore();
beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-tutorlink',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
});
afterAll(async () => { await env?.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });
async function seed(uid, role = 'learner', isLocked = false) {
  await env.withSecurityRulesDisabled(async context => {
    await setDoc(doc(context.firestore(), 'users', uid), user(role, {isLocked}));
  });
}
describe('users: tạo tài khoản', () => {
  for (const role of ['learner', 'tutor']) {
    it('cho phép tự tạo ' + role, async () => {
      await assertSucceeds(setDoc(doc(db(), 'users/u'), user(role)));
    });
  }
  it('chặn tự cấp admin', async () => {
    await assertFails(setDoc(doc(db(), 'users/u'), user('admin')));
  });
  it('chặn tạo với trạng thái khóa', async () => {
    await assertFails(setDoc(doc(db(), 'users/u'), user('tutor', {isLocked: true})));
  });
  it('chặn ghi thay UID khác', async () => {
    await assertFails(setDoc(doc(db(), 'users/other'), user()));
  });
  it('chặn giả email hoặc thời gian', async () => {
    await assertFails(setDoc(doc(db(), 'users/u'), user('learner', {email: 'fake@example.com'})));
    await assertFails(setDoc(doc(db(), 'users/u'), user('learner', {createdAt: Timestamp.fromMillis(0)})));
  });
  it('chặn trường thừa và thiếu trường', async () => {
    await assertFails(setDoc(doc(db(), 'users/u'), user('learner', {permissions: ['admin']})));
    const missing = user(); delete missing.isLocked;
    await assertFails(setDoc(doc(db(), 'users/u'), missing));
  });
  it('chặn khách chưa đăng nhập', async () => {
    await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), 'users/u'), user()));
  });
});
describe('users: cập nhật và đọc', () => {
  beforeEach(async () => { await seed('u'); await seed('a', 'admin'); });
  it('chủ tài khoản đổi tên được', async () => {
    await assertSucceeds(updateDoc(doc(db(), 'users/u'), {displayName: 'Tên mới'}));
  });
  it('chặn đổi role sang tutor hoặc admin', async () => {
    for (const role of ['tutor', 'admin']) {
      await assertFails(updateDoc(doc(db(), 'users/u'), {role}));
    }
  });
  it('chặn tự đổi isLocked và thay thế document', async () => {
    await assertFails(updateDoc(doc(db(), 'users/u'), {isLocked: true}));
    await assertFails(setDoc(doc(db(), 'users/u'), user('admin')));
  });
  it('chỉ admin hoạt động được khóa/mở khóa', async () => {
    await assertSucceeds(updateDoc(doc(db('a'), 'users/u'), {isLocked: true}));
    await assertFails(updateDoc(doc(db(), 'users/u'), {isLocked: false}));
    await assertFails(updateDoc(doc(db(), 'users/u'), {displayName: 'Khác'}));
    await assertSucceeds(getDoc(doc(db(), 'users/u')));
    await assertSucceeds(updateDoc(doc(db('a'), 'users/u'), {isLocked: false}));
  });
  it('admin không đổi role qua client', async () => {
    await assertFails(updateDoc(doc(db('a'), 'users/u'), {role: 'admin'}));
    await assertFails(updateDoc(doc(db('a'), 'users/u'), {isLocked: true, displayName: 'Khác'}));
  });
  it('admin khóa không có quyền quản trị', async () => {
    await seed('a', 'admin', true);
    await assertFails(updateDoc(doc(db('a'), 'users/u'), {isLocked: true}));
    await assertFails(getDocs(collection(db('a'), 'users')));
  });
  it('chỉ chủ sở hữu/admin đọc hồ sơ; chỉ admin liệt kê', async () => {
    await assertSucceeds(getDoc(doc(db(), 'users/u')));
    await assertSucceeds(getDoc(doc(db('a'), 'users/u')));
    await assertFails(getDoc(doc(db('other'), 'users/u')));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'users/u')));
    await assertFails(getDocs(collection(db(), 'users')));
    await assertSucceeds(getDocs(collection(db('a'), 'users')));
  });
  it('chặn xóa, sửa email, ghi collection chưa triển khai', async () => {
    await assertFails(deleteDoc(doc(db(), 'users/u')));
    await assertFails(deleteDoc(doc(db('a'), 'users/u')));
    await assertFails(updateDoc(doc(db(), 'users/u'), {email: 'x@example.com'}));
    await assertFails(setDoc(doc(db('a'), 'tutors/u'), {role: 'admin'}));
  });
});
