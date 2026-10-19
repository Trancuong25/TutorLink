import {it,expect} from 'vitest';
import {createRequire} from 'node:module';
import {initializeApp,deleteApp} from 'firebase-admin/app';
import {getFirestore} from 'firebase-admin/firestore';
const require=createRequire(import.meta.url);
const {seed,clean,generate}=require('../../scripts/seed/seed');
const {distance}=require('../../scripts/seed/geo');
it('seed tái lập, đủ 150 cặp, cleanup giữ nguyên dữ liệu thật',async()=>{
  expect(generate()).toEqual(generate());
  const rows=generate();
  for(const r of rows) {
    expect(distance({lat:10.9804,lon:106.6666},r.exact)).toBeLessThan(10010);
    expect(distance(r.exact,r.approx)).toBeGreaterThanOrEqual(200);
    expect(distance(r.exact,r.approx)).toBeLessThanOrEqual(500);
    expect(r.profile.hourlyRate).toBeGreaterThanOrEqual(80000);
    expect(r.profile.hourlyRate).toBeLessThanOrEqual(300000);
  }
  if(!process.env.FIRESTORE_EMULATOR_HOST)throw Error('Chỉ chạy test trên emulator.');
  const app=initializeApp({projectId:'demo-tutorlink-seed-tests'},'seed-test');
  const db=getFirestore(app);
  try {
    await clean(db);
    await db.doc('tutors/real').set({isMock:false});
    await db.doc('private_locations/real').set({isMock:false});
    expect((await seed(db)).count).toBe(150);
    expect((await db.collection('tutors').where('isMock','==',true).get()).size).toBe(150);
    expect((await db.collection('private_locations').where('isMock','==',true).get()).size).toBe(150);
    await seed(db);
    expect((await clean(db)).removed).toBe(300);
    expect((await db.doc('tutors/real').get()).exists).toBe(true);
    expect((await db.doc('private_locations/real').get()).exists).toBe(true);
    await db.doc('tutors/real').delete();await db.doc('private_locations/real').delete();
  } finally {await deleteApp(app);}
},30000);
