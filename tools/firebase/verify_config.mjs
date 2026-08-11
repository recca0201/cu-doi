import fs from 'node:fs';
import path from 'node:path';

export function verify(root = process.cwd(), { release = false } = {}) {
  const required = ['firebase.json', 'firestore.rules', 'storage.rules', 'firestore.indexes.json'];
  const missing = required.filter((file) => !fs.existsSync(path.join(root, file)));
  const secretPatterns = [/BEGIN PRIVATE KEY/, /APPLE_PRIVATE_KEY/, /refresh_token/i];
  const scanned = required.filter((f) => fs.existsSync(path.join(root, f))).map((f) => fs.readFileSync(path.join(root, f), 'utf8')).join('\n');
  const errors = [...missing.map((f) => `Missing ${f}`)];
  if (secretPatterns.some((p) => p.test(scanned))) errors.push('Repository config contains a secret');
  const androidSettings = read(root, 'android/settings.gradle.kts');
  const androidApp = read(root, 'android/app/build.gradle.kts');
  const androidManifest = read(root, 'android/app/src/main/AndroidManifest.xml');
  const iosInfo = read(root, 'ios/Runner/Info.plist');
  const iosProject = read(root, 'ios/Runner.xcodeproj/project.pbxproj');
  const entitlements = read(root, 'ios/Runner/Runner.entitlements');
  if (!androidSettings.includes('com.google.gms.google-services') || !androidApp.includes('google-services.json')) errors.push('Android Google Services wiring missing');
  if (/READ_MEDIA_IMAGES|READ_EXTERNAL_STORAGE/.test(androidManifest)) errors.push('Eager Android gallery permission is forbidden');
  if (!iosInfo.includes('NSPhotoLibraryUsageDescription')) errors.push('iOS picker purpose copy missing');
  if (!iosInfo.includes('GOOGLE_REVERSED_CLIENT_ID')) errors.push('iOS Google URL scheme contract missing');
  if (!entitlements.includes('com.apple.developer.applesignin') || !iosProject.includes('Runner.entitlements')) errors.push('Apple Sign In capability missing');
  if (release) {
    for (const key of ['CU_DOI_ANDROID_APP_ID','CU_DOI_IOS_BUNDLE_ID','CU_DOI_FIREBASE_PROJECT','CU_DOI_FUNCTIONS_REGION','CU_DOI_SUPPORT_URL']) if (!process.env[key]) errors.push(`Missing release input ${key}`);
  }
  return errors;
}

function read(root, file) {
  const target = path.join(root, file);
  return fs.existsSync(target) ? fs.readFileSync(target, 'utf8') : '';
}

if (process.argv[1] && path.resolve(process.argv[1]) === path.resolve(new URL(import.meta.url).pathname.replace(/^\/(.:)/, '$1'))) {
  const errors = verify(process.cwd(), { release: process.argv.includes('--release') });
  if (errors.length) { console.error(errors.join('\n')); process.exitCode = 1; } else console.log('Firebase configuration structure is valid.');
}
