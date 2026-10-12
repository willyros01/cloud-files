#!/usr/bin/env node
'use strict';
// Deterministic Cloud Files browser/native-adapter tests using shipped HTML.
const fs=require('node:fs'), vm=require('node:vm'), assert=require('node:assert/strict');
const html=fs.readFileSync('www/index.html','utf8');
const script=(html.match(/<script>([\s\S]*?)<\/script>/)||[])[1];
assert(script,'Cloud Files app script missing');
new vm.Script(script); // Whole shipped JS must parse.
assert(html.includes('id="pickBtn"') && html.includes('id="fileArea"'));
assert(html.includes('id="openUploadIcloud"') && html.includes('id="openDownloadIcloud"'));
const from=script.indexOf('const cap = window.Capacitor || null;');
const until=script.indexOf('function esc(t)',from);
assert(from>=0 && until>from,'External browser adapter missing');
const adapter=script.slice(from,until);
function mock(native,pluginMode){
  const events={native:0,web:0,alerts:[],hrefs:[],nativeClass:false};
  const buttons={openUploadIcloud:{},openDownloadIcloud:{}};
  const links={};
  if(pluginMode==='present'||pluginMode==='reject')links.CloudFilesLinks={openICloud:()=>{events.native++;if(pluginMode==='reject')return Promise.reject(new Error('Browser unavailable'));return Promise.resolve();}};
  const cap=native?{isNativePlatform:()=>true,getPlatform:()=> 'android',Plugins:links}:null;
  const doc={documentElement:{classList:{add:x=>{if(x==='android-native')events.nativeClass=true;}}},
    querySelector:()=>({textContent:''}),getElementById:id=>buttons[id]};
  const ctx={window:{Capacitor:cap,open:url=>{events.web++;events.hrefs.push(url);}},
    document:doc,alert:s=>events.alerts.push(s),Promise,String};
  // The adapter references $ defined in the original app.
  const scriptToRun='const $=id=>document.getElementById(id);\n'+adapter
     +'\nconst downloadOpen=document.getElementById("openDownloadIcloud");if(downloadOpen)downloadOpen.onclick=openICloudDrive;';
  vm.runInNewContext(scriptToRun,ctx);
  return {events,buttons};
}
async function main(){
  let v=mock(true,'present');
  v.buttons.openUploadIcloud.onclick();
  v.buttons.openDownloadIcloud.onclick();
  await new Promise(resolve=>setImmediate(resolve));
  assert.equal(v.events.native,2);assert.equal(v.events.web,0);assert.equal(v.events.alerts.length,0);
  assert.equal(v.events.nativeClass,true);
  console.log('PASS: Native Android opens both iCloud actions in Fire OS browser');

  v=mock(true,'absent');
  v.buttons.openUploadIcloud.onclick();
  assert.equal(v.events.web,0);assert.equal(v.events.native,0);
  assert.match(v.events.alerts.join(' '),/browser component is unavailable/);
  console.log('PASS: Missing native adapter fails visibly, not into embedded WebView');

  v=mock(true,'reject');
  v.buttons.openDownloadIcloud.onclick();
  await new Promise(resolve=>setImmediate(resolve));
  assert.equal(v.events.web,0);
  assert.match(v.events.alerts.join(' '),/Browser unavailable/);
  console.log('PASS: Browser launch failure is reported');

  v=mock(false,'absent');
  v.buttons.openUploadIcloud.onclick();
  assert.equal(v.events.web,1);
  assert.equal(v.events.hrefs[0],'https://www.icloud.com/iclouddrive/');
  console.log('PASS: Existing web iCloud link behaviour preserved');

  const java=fs.readFileSync('build/android-native.sh','utf8');
  assert(java.includes('Intent.ACTION_VIEW'));
  assert(java.includes('Intent.CATEGORY_BROWSABLE'));
  assert(java.includes('https://www.icloud.com/iclouddrive/'));
  assert(!java.includes('WebView.loadUrl'));
  console.log('PASS: Native opens fixed Apple URL via external Android Intent');
}
main().catch(e=>{console.error(e);process.exitCode=1;});
