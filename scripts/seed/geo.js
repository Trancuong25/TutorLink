// Cùng quy tắc lưới với location_privacy.dart; không phải thuật toán mã hóa.
const R=6371000, rad=Math.PI/180;
function distance(a,b) {
  const h=Math.sin((b.lat-a.lat)*rad/2)**2+Math.cos(a.lat*rad)*Math.cos(b.lat*rad)*Math.sin((b.lon-a.lon)*rad/2)**2;
  return 2*R*Math.asin(Math.sqrt(Math.min(1,h)));
}
function blur(uid,p) {
  let hash=2166136261;
  for(let i=0;i<uid.length;i++) hash=Math.imul(hash^uid.charCodeAt(i),16777619)>>>0;
  const jx=hash%81-40,jy=Math.floor(hash/81)%81-40,mLat=R*rad,mLon=mLat*Math.cos(11*rad);
  const gx=Math.round(p.lon*mLon/400),gy=Math.round(p.lat*mLat/400),c=[];
  for(let x=-4;x<=4;x++) for(let y=-2;y<=2;y++) {
    const lon=((gx+x)*400+jx)/mLon;
    const q={lat:((gy+y)*400+jy)/mLat,lon:((lon+180)%360+360)%360-180};
    const d=distance(p,q); if(Math.abs(q.lat)<=60&&d>=200&&d<=500)c.push(q);
  }
  if(!c.length) throw Error('Không có tâm làm mờ phù hợp.');
  return c[hash%c.length];
}
function geohash(p) {
  const chars='0123456789bcdefghjkmnpqrstuvwxyz';
  let a=-90,b=90,c=-180,d=180,even=true,bits=0,value=0,out='';
  while(out.length<6) {
    const mid=even?(c+d)/2:(a+b)/2,high=(even?p.lon:p.lat)>=mid;
    value=(value<<1)|(high?1:0);
    if(even){if(high)c=mid;else d=mid;}else{if(high)a=mid;else b=mid;}
    even=!even;
    if(++bits===5){out+=chars[value];bits=0;value=0;}
  }
  return out;
}
module.exports={distance,blur,geohash};
