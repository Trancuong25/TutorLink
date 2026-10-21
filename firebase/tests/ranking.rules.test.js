import {readFileSync} from 'node:fs';
import {beforeAll,afterAll,beforeEach,it} from 'vitest';
import {initializeTestEnvironment,assertFails,assertSucceeds} from '@firebase/rules-unit-testing';
import {doc,setDoc,getDoc,updateDoc,deleteDoc} from 'firebase/firestore';
let env;
const defaults=JSON.parse(readFileSync('config/ranking_defaults.json','utf8'));
const db=uid=>env.authenticatedContext(uid).firestore();
beforeAll(async()=>{env=await initializeTestEnvironment({projectId:'demo-tutorlink-ranking-tests',firestore:{rules:readFileSync('firestore.rules','utf8')}});});
afterAll(async()=>env?.cleanup());
beforeEach(async()=>{
 await env.clearFirestore();await env.withSecurityRulesDisabled(async c=>{
  for(const [uid,role,isLocked] of [['a','admin',false],['locked','admin',true],['l','learner',false],['t','tutor',false]]){
   await setDoc(doc(c.firestore(),'users',uid),{role,isLocked});
  }
 });
});
it('admin ghi, user không khóa đọc, khách bị chặn',async()=>{
 await assertSucceeds(setDoc(doc(db('a'),'config/ranking_weights'),defaults));
 for(const uid of ['l','t','a'])await assertSucceeds(getDoc(doc(db(uid),'config/ranking_weights')));
 await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'config/ranking_weights')));
});
it('chặn đọc config khi learner, tutor hoặc admin bị khóa hoặc chưa có user',async()=>{
 await assertSucceeds(setDoc(doc(db('a'),'config/ranking_weights'),defaults));
 for(const uid of ['l','t','a']) {
  await env.withSecurityRulesDisabled(c=>updateDoc(doc(c.firestore(),'users',uid),{isLocked:true}));
  await assertFails(getDoc(doc(db(uid),'config/ranking_weights')));
 }
 await assertFails(getDoc(doc(db('missing'),'config/ranking_weights')));
});
it('chặn learner/tutor và admin bị khóa ghi hoặc xóa',async()=>{
 for(const uid of ['l','t','locked'])await assertFails(setDoc(doc(db(uid),'config/ranking_weights'),defaults));
 await assertSucceeds(setDoc(doc(db('a'),'config/ranking_weights'),defaults));
 await assertFails(deleteDoc(doc(db('a'),'config/ranking_weights')));
});
it('chặn số âm, thiếu field, sai tổng, C sai; cho đổi AHP hợp lệ',async()=>{
 for(const data of [{...defaults,subject:-1},{...defaults,subject:0.8},{subject:1},{...defaults,systemRatingMean:6},{...defaults,extra:true}]){
  await assertFails(setDoc(doc(db('a'),'config/ranking_weights'),data));
 }
 await assertSucceeds(setDoc(doc(db('a'),'config/ranking_weights'),defaults));
 await assertSucceeds(updateDoc(doc(db('a'),'config/ranking_weights'),{subject:.35,distance:.15}));
});
