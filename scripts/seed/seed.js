const fs=require('node:fs');
const path=require('node:path');
const {parseArgs}=require('node:util');
const {initializeApp,applicationDefault,deleteApp}=require('firebase-admin/app');
const {getFirestore,GeoPoint,FieldValue}=require('firebase-admin/firestore');
const {distance,blur,geohash}=require('./geo');
const center={lat:10.9804,lon:106.6666};
function generate() {
  let state=20261019;
  const random=()=>{state^=state<<13;state^=state>>>17;state^=state<<5;return (state>>>0)/4294967296;};
  const subjects=['math','literature','english','physics','chemistry','biology','informatics'];
  const levels=['primary','secondary','high','university','other'];
  const pick=(items)=>items.filter(()=>random()<0.35);
  return Array.from({length:150},(_,i)=>{
    const uid='mock_'+String(i+1).padStart(3,'0');
    const radius=Math.sqrt(random())*(random()<0.65?2500:10000),angle=random()*2*Math.PI;
    const exact={lat:center.lat+radius*Math.cos(angle)/111195,
      lon:center.lon+radius*Math.sin(angle)/(111195*Math.cos(center.lat*Math.PI/180))};
    const approx=blur(uid,exact),subs=pick(subjects),lvls=pick(levels),slots=[];
    if(!subs.length)subs.push(subjects[i%subjects.length]);
    if(!lvls.length)lvls.push(levels[i%levels.length]);
    for(let slot=0;slot<21;slot++)if(random()<(slot>=15||slot%3===2?0.65:0.2))slots.push(slot);
    if(!slots.length)slots.push(2);
    return {uid,exact,approx,profile:{
      displayName:'Gia sư thử nghiệm '+String(i+1).padStart(3,'0'),
      bio:'Hồ sơ giả phục vụ nghiên cứu TutorLink, không phải gia sư thật.',
      subjects:subs,levels:lvls,hourlyRate:80000+Math.floor(random()*45)*5000,
      availability:slots,teachingMode:['offline','online','both'][i%3],
      isAvailable:random()>0.15,isHidden:false,ratingAvg:Math.round((3+random()*2)*10)/10,
      ratingCount:5+Math.floor(random()*96),isMock:true,geohash:geohash(approx),
    }};
  });
}
function statistics(rows) {
  const subjects={},distances={'0–2km':0,'2–5km':0,'5–10km':0};
  const prices={'80–<150k':0,'150–<220k':0,'220–300k':0};
  for(const r of rows) {
    for(const s of r.profile.subjects)subjects[s]=(subjects[s]||0)+1;
    const d=distance(center,r.exact);
    distances[d<2000?'0–2km':d<5000?'2–5km':'5–10km']++;
    prices[r.profile.hourlyRate<150000?'80–<150k':r.profile.hourlyRate<220000?'150–<220k':'220–300k']++;
  }
  return {count:rows.length,subjects,distances,prices};
}
async function seed(db) {
  const rows=generate();
  const refs=rows.flatMap(r=>[db.doc('tutors/'+r.uid),db.doc('private_locations/'+r.uid)]);
  // Kiểm tra toàn bộ trước khi ghi; không ghi đè dữ liệu thật trùng ID.
  const docs=await db.getAll(...refs);
  if(docs.some(d=>d.exists&&d.data().isMock!==true))throw Error('UID trùng dữ liệu không phải mock. Dừng seed.');
  const batch=db.batch();
  for(const r of rows) {
    batch.set(db.doc('tutors/'+r.uid),{...r.profile,
      approxLocation:new GeoPoint(r.approx.lat,r.approx.lon),updatedAt:FieldValue.serverTimestamp()});
    batch.set(db.doc('private_locations/'+r.uid),{
      location:new GeoPoint(r.exact.lat,r.exact.lon),source:'manual',
      consentVersion:'mock-only',isMock:true,updatedAt:FieldValue.serverTimestamp()});
  }
  await batch.commit(); return statistics(rows);
}
async function clean(db) {
  let removed=0;
  for(const name of ['tutors','private_locations']) {
    while(true) {
      const snapshot=await db.collection(name).where('isMock','==',true).limit(200).get();
      if(snapshot.empty)break;
      const batch=db.batch();snapshot.docs.forEach(d=>batch.delete(d.ref));
      await batch.commit();removed+=snapshot.size;
    }
  }
  return {removed};
}
async function main() {
  const {values}=parseArgs({options:{
    emulator:{type:'boolean',default:false},project:{type:'string'},clean:{type:'boolean',default:false},
  },strict:true});
  let options;
  if(values.emulator) {
    if(values.project&&values.project!=='demo-tutorlink')throw Error('--emulator chỉ dùng demo-tutorlink.');
    process.env.FIRESTORE_EMULATOR_HOST='127.0.0.1:8080';
    options={projectId:'demo-tutorlink'};
  } else {
    if(!values.project||values.project.startsWith('demo-'))throw Error('Cần --project <id> hoặc --emulator.');
    if(process.env.FIRESTORE_EMULATOR_HOST)throw Error('Bỏ FIRESTORE_EMULATOR_HOST khi dùng project thật.');
    const credential=process.env.GOOGLE_APPLICATION_CREDENTIALS;
    if(!credential)throw Error('Cần service account NGOÀI repo qua GOOGLE_APPLICATION_CREDENTIALS.');
    const root=fs.realpathSync(path.resolve(__dirname,'../..'));
    const rel=path.relative(root,fs.realpathSync(credential));
    if(!rel.startsWith('..'+path.sep)&&!path.isAbsolute(rel))throw Error('Service account phải ở ngoài repo.');
    options={projectId:values.project,credential:applicationDefault()};
  }
  const app=initializeApp(options);
  try {
    console.log('Project: '+options.projectId+(values.emulator?' (EMULATOR)':' (THẬT)'));
    console.log(JSON.stringify(await (values.clean?clean(getFirestore(app)):seed(getFirestore(app))),null,2));
  } finally {await deleteApp(app);}
}
if(require.main===module)main().catch(e=>{console.error(e.message);process.exitCode=1;});
module.exports={generate,statistics,seed,clean};
