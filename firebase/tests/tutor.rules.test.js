import {readFileSync} from 'node:fs';
import {beforeAll,afterAll,beforeEach,it,expect} from 'vitest';
import {initializeTestEnvironment,assertFails,assertSucceeds} from '@firebase/rules-unit-testing';
import {doc,setDoc,updateDoc,getDoc,getDocs,collection,query,where,writeBatch,GeoPoint,serverTimestamp,deleteDoc} from 'firebase/firestore';
let env;
const db=(uid)=>env.authenticatedContext(uid).firestore();
const profile=()=>({displayName:'Gia sư',bio:'Giới thiệu',subjects:['math'],levels:['high'],
  hourlyRate:150000,availability:[2,5,8],teachingMode:'both',isAvailable:true,
  approxLocation:null,geohash:null,ratingAvg:0,ratingCount:0,isMock:false,isHidden:false,updatedAt:serverTimestamp()});
beforeAll(async()=>{env=await initializeTestEnvironment({projectId:'demo-tutorlink-tutor-tests',
  firestore:{rules:readFileSync('firestore.rules','utf8')}});});
afterAll(async()=>env?.cleanup());
beforeEach(async()=>{
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async c=>{
    for(const [uid,role] of [['t','tutor'],['b','tutor'],['l','learner'],['a','admin']]) {
      await setDoc(doc(c.firestore(),'users',uid),{role,isLocked:false});
    }
  });
});
async function create(){await assertSucceeds(setDoc(doc(db('t'),'tutors/t'),profile()));}
async function locate() {
  const d=db('t'),batch=writeBatch(d);
  batch.set(doc(d,'private_locations/t'),{location:new GeoPoint(10.9804,106.6666),source:'gps',consentVersion:'location-v1',updatedAt:serverTimestamp()});
  batch.update(doc(d,'tutors/t'),{approxLocation:new GeoPoint(10.983,106.668),geohash:'w3gv4s',updatedAt:serverTimestamp()});
  return batch.commit();
}
it('tutor tạo/sửa; learner không tạo; tutor khác không sửa',async()=>{
  await create();
  await assertSucceeds(updateDoc(doc(db('t'),'tutors/t'),{bio:'Mới',updatedAt:serverTimestamp()}));
  await assertFails(setDoc(doc(db('l'),'tutors/l'),profile()));
  await assertFails(updateDoc(doc(db('b'),'tutors/t'),{bio:'Xâm nhập',updatedAt:serverTimestamp()}));
});
it('rating và isMock không được giả lúc tạo hoặc sửa',async()=>{
  for(const extra of [{ratingAvg:5},{ratingCount:1},{isMock:true},{isHidden:true}]) {
    await assertFails(setDoc(doc(db('t'),'tutors/t'),{...profile(),...extra}));
  }
  await create();
  for(const extra of [{ratingAvg:5},{ratingCount:20},{isMock:true}]) {
    await assertFails(updateDoc(doc(db('t'),'tutors/t'),{...extra,updatedAt:serverTimestamp()}));
    await assertFails(updateDoc(doc(db('a'),'tutors/t'),{...extra,updatedAt:serverTimestamp()}));
  }
});
it('validate môn/cấp/lịch/giá/field thừa',async()=>{
  for(const extra of [{subjects:[]},{subjects:['invalid']},{levels:[]},{hourlyRate:49999},
    {hourlyRate:1000001},{availability:[21]},{availability:[2,2]},{secret:'GPS'}]) {
    await assertFails(setDoc(doc(db('t'),'tutors/t'),{...profile(),...extra}));
  }
});
it('chỉ owner đọc private; admin cũng không đọc',async()=>{
  await create();await assertSucceeds(locate());
  await assertSucceeds(getDoc(doc(db('t'),'private_locations/t')));
  for(const uid of ['l','b','a'])await assertFails(getDoc(doc(db(uid),'private_locations/t')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'private_locations/t')));
  await assertFails(updateDoc(doc(db('b'),'private_locations/t'),{source:'manual'}));
});
it('không ghi lẻ tọa độ riêng/công khai, không công khai tọa độ gốc',async()=>{
  await create();
  await assertFails(setDoc(doc(db('t'),'private_locations/t'),{location:new GeoPoint(11,106),source:'gps',consentVersion:'location-v1',updatedAt:serverTimestamp()}));
  await assertFails(updateDoc(doc(db('t'),'tutors/t'),{approxLocation:new GeoPoint(11,106),geohash:'w3gv4s',updatedAt:serverTimestamp()}));
  const d=db('t'),batch=writeBatch(d),p=new GeoPoint(11,106);
  batch.set(doc(d,'private_locations/t'),{location:p,source:'gps',consentVersion:'location-v1',updatedAt:serverTimestamp()});
  batch.update(doc(d,'tutors/t'),{approxLocation:p,geohash:'w3gv4s',updatedAt:serverTimestamp()});
  await assertFails(batch.commit());
});
it('thu hồi phải xóa cả hai, kể cả tài khoản bị khóa',async()=>{
  await create();await locate();
  await assertFails(deleteDoc(doc(db('t'),'private_locations/t')));
  await env.withSecurityRulesDisabled(c=>updateDoc(doc(c.firestore(),'users/t'),{isLocked:true}));
  await assertFails(updateDoc(doc(db('t'),'tutors/t'),{bio:'Khóa',updatedAt:serverTimestamp()}));
  const d=db('t'),batch=writeBatch(d);
  batch.delete(doc(d,'private_locations/t'));
  batch.update(doc(d,'tutors/t'),{approxLocation:null,geohash:null,updatedAt:serverTimestamp()});
  await assertSucceeds(batch.commit());
  expect((await getDoc(doc(d,'private_locations/t'))).exists()).toBe(false);
});
it('admin ẩn; owner không tự hiện; learner chỉ đọc hồ sơ không ẩn',async()=>{
  await create();
  await assertSucceeds(getDoc(doc(db('l'),'tutors/t')));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'tutors/t')));
  await assertSucceeds(updateDoc(doc(db('a'),'tutors/t'),{isHidden:true,updatedAt:serverTimestamp()}));
  await assertFails(getDoc(doc(db('l'),'tutors/t')));
  await assertSucceeds(getDoc(doc(db('t'),'tutors/t')));
  await assertFails(updateDoc(doc(db('t'),'tutors/t'),{isHidden:false,updatedAt:serverTimestamp()}));
  await assertSucceeds(getDocs(query(collection(db('l'),'tutors'),where('isHidden','==',false))));
  await assertFails(getDocs(collection(db('l'),'tutors')));
});
