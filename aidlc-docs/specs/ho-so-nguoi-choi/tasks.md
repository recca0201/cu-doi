---
artifact_type: tasks
phase: construction
status: complete
created: 2026-08-11
updated: 2026-08-11
completed: 2026-08-11
unit: ho-so-nguoi-choi
source_artifacts:
  - aidlc-docs/specs/ho-so-nguoi-choi/requirements.md
  - aidlc-docs/specs/ho-so-nguoi-choi/design.md
---

# Tasks: Hồ sơ người chơi

## Implementation Checklist

### 1. Mô hình hồ sơ, tên và số liệu suy ra

- [x] 1.1 Viết test RED cho mô hình hồ sơ và phép tính tổng quan
  - Reference: US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.3, US-2 AC-1.1, US-2 AC-2.1, US-2 AC-2.2, US-2 AC-2.3, US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-3.1, US-4 AC-3.2, US-4 AC-3.3, US-4 AC-3.4, US-4 AC-3.5
  - Files: `test/domain/profile_summary_test.dart`, `lib/domain/player_profile.dart`, `lib/domain/profile_summary.dart`
  - Test tên mặc định theo locale bằng sentinel `customDisplayName == null`, chuẩn hóa khoảng trắng, giới hạn 20 grapheme, 4 chương × 5 màn, 8 huy hiệu, completed chỉ khi có sao, best score và progress cap.
  - Expected: test compile/chạy được nhưng FAIL vì model và hàm suy ra chưa tồn tại.

- [x] 1.2 Chạy test mục tiêu để xác nhận RED đúng nguyên nhân
  - Reference: US-1 AC-2.1, US-1 AC-2.2, US-2 AC-1.1, US-2 AC-2.1, US-4 AC-1.1, US-4 AC-3.1
  - Command: `flutter test test/domain/profile_summary_test.dart`
  - Expected: FAIL do thiếu `PlayerProfile`/`ProfileSummary`, không do fixture, syntax hay localization setup.

- [x] 1.3 Cài đặt tối thiểu model hồ sơ và summary tất định
  - Reference: US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.3, US-2 AC-1.1, US-2 AC-2.1, US-2 AC-2.2, US-2 AC-2.3, US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-3.1, US-4 AC-3.2, US-4 AC-3.3, US-4 AC-3.4, US-4 AC-3.5
  - Files: `lib/domain/player_profile.dart`, `lib/domain/profile_summary.dart`, `pubspec.yaml`
  - Thêm `AvatarKind`, preset fallback, Unicode `characters`, chapter/record/badge view models chỉ suy ra từ `PlayerProgress` và `kChapters`; không lưu aggregate/huy hiệu.

- [x] 1.4 Chạy lại test domain để xác nhận GREEN
  - Reference: US-1 AC-2.1, US-1 AC-2.2, US-2 AC-2.1, US-4 AC-1.2, US-4 AC-3.3, US-4 AC-3.5
  - Command: `flutter test test/domain/profile_summary_test.dart test/domain/chapters_test.dart test/domain/player_progress_test.dart`
  - Expected: PASS và không thay đổi luật mở màn hiện có.

### 2. Gộp tiến trình và serializer cloud

- [x] 2.1 Viết test RED cho truth table gộp và schema dense 20 màn
  - Reference: US-4 AC-2.1, US-4 AC-2.2, US-4 AC-2.3, US-4 AC-2.4, US-4 AC-2.5, US-4 AC-4.1, US-4 AC-4.2, US-4 AC-4.3, US-6 AC-1.1, US-6 AC-1.3, US-6 AC-2.1, US-6 AC-2.2, US-6 AC-2.3, US-6 AC-2.7
  - Files: `test/data/progress_merge_test.dart`, `lib/domain/player_progress.dart`, `lib/data/firebase_sync_repository.dart`
  - Cover max stars/score/losses/coins, skipped bị xóa khi có sao, coin không âm, record không hiện score 0, dense key `1..20`, reject field/key/bounds sai và không tạo lịch sử/timestamp gameplay.

- [x] 2.2 Chạy test merge để xác nhận RED
  - Reference: US-6 AC-2.1, US-6 AC-2.2, US-6 AC-2.3, US-6 AC-2.7
  - Command: `flutter test test/data/progress_merge_test.dart`
  - Expected: FAIL vì merge/serializer/validator chưa được cài đặt.

- [x] 2.3 Cài đặt merge và codec cloud tối thiểu
  - Reference: US-4 AC-2.1, US-4 AC-2.2, US-4 AC-2.3, US-4 AC-2.4, US-4 AC-2.5, US-4 AC-4.1, US-4 AC-4.2, US-4 AC-4.3, US-6 AC-1.1, US-6 AC-1.3, US-6 AC-2.1, US-6 AC-2.2, US-6 AC-2.3, US-6 AC-2.7
  - Files: `lib/domain/player_progress.dart`, `lib/data/firebase_sync_repository.dart`
  - Giữ local sparse, cloud dense; validate schema v2 và `0..2147483647`; không sửa `lib/sim/`, `lib/sim/arenas.dart`, điểm, sao hay campaign.

- [x] 2.4 Xác nhận GREEN và boundary gameplay bất biến
  - Reference: US-4 AC-4.2, US-4 AC-4.3, US-6 AC-2.1, US-6 AC-2.2, US-6 AC-2.3
  - Command: `flutter test test/data/progress_merge_test.dart test/boundary_test.dart test/sim/invariants_test.dart`
  - Expected: PASS; không có event log mới và `lib/sim/` vẫn thuần Dart.

### 3. LocalPlayerStore theo owner, migration và commit chống crash

- [x] 3.1 Viết test RED cho envelope, provenance, migration và process death
  - Reference: US-2 AC-3.1, US-2 AC-3.2, US-3 AC-3.1, US-3 AC-3.4, US-3 AC-3.5, US-6 AC-3.1, US-6 AC-3.2, US-6 AC-3.3, US-6 AC-3.4, US-6 AC-3.5, US-6 AC-4.5
  - Files: `test/data/local_player_store_test.dart`, `lib/data/local_player_store.dart`, `lib/data/progress_repository.dart`
  - Cover two-generation CAS, read-back/pointer flip crash, corrupt quarantine, `progress_v1` migration, unclaimed claim-once, UID hash namespace, UID-derived guest provenance, pending/deletion durability và missing avatar fallback không mất progress.

- [x] 3.2 Chạy test local store để xác nhận RED
  - Reference: US-6 AC-3.1, US-6 AC-3.2, US-6 AC-3.3, US-6 AC-4.5
  - Command: `flutter test test/data/local_player_store_test.dart`
  - Expected: FAIL do owner-scoped envelope/CAS chưa tồn tại.

- [x] 3.3 Cài đặt LocalPlayerStore, OwnerKey/OwnerLease và migration
  - Reference: US-2 AC-3.1, US-2 AC-3.2, US-3 AC-3.1, US-3 AC-3.4, US-3 AC-3.5, US-6 AC-3.1, US-6 AC-3.2, US-6 AC-3.3, US-6 AC-3.4, US-6 AC-3.5, US-6 AC-4.5
  - Files: `lib/data/local_player_store.dart`, `lib/data/progress_repository.dart`, `lib/domain/player_profile.dart`
  - Serialize commit theo owner, chỉ switch active pointer sau read-back; hash UID trong key; giữ old key tới khi migration v2 xác nhận; không xóa last-known-good.

- [x] 3.4 Chạy lại local persistence tests để xác nhận GREEN
  - Reference: US-2 AC-3.2, US-6 AC-3.2, US-6 AC-3.3, US-6 AC-3.4, US-6 AC-3.5, US-6 AC-4.5
  - Command: `flutter test test/data/local_player_store_test.dart test/data/progress_repository_test.dart test/data/progress_roundtrip_test.dart`
  - Expected: PASS cho cả migration, owner isolation và hai điểm process-death.

### 4. ProgressController local-first và lease isolation

- [x] 4.1 Viết test RED cho hàng đợi save và đổi owner giữa callback
  - Reference: US-5 AC-1.1, US-5 AC-1.2, US-6 AC-4.1, US-6 AC-4.2, US-6 AC-4.4, US-6 AC-4.5, US-7 AC-2.3, US-7 AC-2.4, US-7 AC-3.4
  - Files: `test/state/progress_controller_test.dart`, `lib/state/providers.dart`, `lib/data/progress_repository.dart`
  - Cover serialized record/loss/spend/skip/reset, local commit trước publish/queue cloud, offline pending, restart resume, stale owner/deletion epoch không publish và gameplay khách không bị chặn.

- [x] 4.2 Chạy controller test để xác nhận RED
  - Reference: US-6 AC-4.1, US-6 AC-4.2, US-6 AC-4.5, US-7 AC-3.4
  - Command: `flutter test test/state/progress_controller_test.dart`
  - Expected: FAIL ở concurrent save/lease cases, không phải test harness.

- [x] 4.3 Refactor ProgressRepository/ProgressController theo owner lease
  - Reference: US-5 AC-1.1, US-5 AC-1.2, US-6 AC-4.1, US-6 AC-4.2, US-6 AC-4.4, US-6 AC-4.5, US-7 AC-2.3, US-7 AC-2.4, US-7 AC-3.4
  - Files: `lib/data/progress_repository.dart`, `lib/state/providers.dart`, `lib/data/local_player_store.dart`
  - Giữ `progressProvider` làm compatibility surface; mọi mutation đi qua queue per-owner và enqueue một progress snapshot coalesced sau local success.

- [x] 4.4 Xác nhận GREEN cho gameplay/state hiện có
  - Reference: US-5 AC-1.2, US-6 AC-4.1, US-6 AC-4.2, US-6 AC-4.4
  - Command: `flutter test test/state/progress_controller_test.dart test/ui/game_screen_hint_test.dart test/ui/game_screen_skip_test.dart`
  - Expected: PASS và gameplay offline vẫn dùng state local ngay.

### 5. Chỉnh sửa tên và pending profile mutations

- [x] 5.1 Viết test RED cho ProfileController và lỗi lưu tên
  - Reference: US-2 AC-1.2, US-2 AC-1.3, US-2 AC-2.4, US-2 AC-2.5, US-2 AC-3.3, US-2 AC-3.4, US-2 AC-3.5, US-6 AC-2.4, US-6 AC-2.5, US-6 AC-2.6
  - Files: `test/state/profile_controller_test.dart`, `lib/state/profile_controller.dart`
  - Cover edit/cancel, giữ draft khi write fail, local UI update, default account-vs-guest import, stable `mutationId`, pending không bị cloud cũ xóa và total order `(serverCommittedAt, mutationId)`.

- [x] 5.2 Chạy profile controller test để xác nhận RED
  - Reference: US-2 AC-1.2, US-2 AC-1.3, US-2 AC-2.5, US-6 AC-2.5, US-6 AC-2.6
  - Command: `flutter test test/state/profile_controller_test.dart`
  - Expected: FAIL vì controller/pending mutation ordering chưa tồn tại.

- [x] 5.3 Cài đặt ProfileController và local mutation queue tối thiểu
  - Reference: US-2 AC-1.2, US-2 AC-1.3, US-2 AC-2.4, US-2 AC-2.5, US-2 AC-3.3, US-2 AC-3.4, US-2 AC-3.5, US-6 AC-2.4, US-6 AC-2.5, US-6 AC-2.6
  - Files: `lib/state/profile_controller.dart`, `lib/domain/player_profile.dart`, `lib/data/local_player_store.dart`, `lib/state/providers.dart`
  - Commit normalized profile locally trước; dùng base64url UUID ổn định; chỉ clear pending khi remote quan sát cùng ID/order; truncate chỉ ở presentation, không sửa stored value.

- [x] 5.4 Chạy lại profile/name tests để xác nhận GREEN
  - Reference: US-2 AC-1.3, US-2 AC-2.4, US-2 AC-2.5, US-2 AC-3.3, US-2 AC-3.4, US-2 AC-3.5
  - Command: `flutter test test/state/profile_controller_test.dart test/domain/profile_summary_test.dart`
  - Expected: PASS cho cancel/retry/offline/import và Unicode grapheme.

### 6. Pipeline avatar cục bộ và cache app-private

- [x] 6.1 Viết test RED cho xử lý, thay thế và dọn file avatar
  - Reference: US-3 AC-2.3, US-3 AC-2.5, US-3 AC-2.6, US-3 AC-2.7, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4
  - Files: `test/data/avatar_repository_test.dart`, `test/data/local_player_store_test.dart`, `lib/data/avatar_repository.dart`, `lib/data/avatar_cache_repository.dart`
  - Fixtures cover EXIF orientation, crop vuông, 20MB/40MP input bounds, ≤1024px, JPEG/WebP ≤2MB, temp cleanup, atomic rename, old-file delete only after commit và copy custom avatar sang guest.

- [x] 6.2 Chạy avatar data tests để xác nhận RED
  - Reference: US-3 AC-2.3, US-3 AC-2.6, US-3 AC-2.7, US-3 AC-3.3
  - Command: `flutter test test/data/avatar_repository_test.dart`
  - Expected: FAIL do processing/cache repositories chưa tồn tại.

- [x] 6.3 Cài đặt avatar processing/cache tối thiểu
  - Reference: US-3 AC-2.3, US-3 AC-2.5, US-3 AC-2.6, US-3 AC-2.7, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4
  - Files: `lib/data/avatar_repository.dart`, `lib/data/avatar_cache_repository.dart`, `pubspec.yaml`
  - Dùng `image`, `path_provider`, `path`, `crypto`; xử lý ngoài UI isolate khi thực tế; không telemetry/share; fsync/rename rồi mới đổi ref và dọn file cũ/temp.

- [x] 6.4 Xác nhận GREEN cho pipeline và failure recovery
  - Reference: US-3 AC-2.5, US-3 AC-2.6, US-3 AC-2.7, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4
  - Command: `flutter test test/data/avatar_repository_test.dart test/data/local_player_store_test.dart`
  - Expected: PASS; mọi lỗi giữ avatar/progress trước đó và không enqueue file sai chuẩn.

### 7. Firebase bootstrap, emulator và release-config guard

- [x] 7.1 Viết test/validator RED cho bootstrap và đầu vào phát hành
  - Reference: US-5 AC-1.1, US-5 AC-2.3, US-6 AC-5.3, US-6 AC-5.4, US-6 AC-5.5
  - Files: `test/firebase/bootstrap_test.dart`, `tools/firebase/verify_config.mjs`, `test/firebase/verify_config.test.mjs`, `lib/main.dart`
  - Assert guest boot không Firebase/network, emulator dùng `demo-cu-doi`, production thiếu application/bundle/provider/App Check/region/queue/KMS/IAM input thì verifier fail mà không chặn guest build; không secret/token/analytics config.

- [x] 7.2 Chạy bootstrap/config tests để xác nhận RED
  - Reference: US-5 AC-1.1, US-6 AC-5.3, US-6 AC-5.4, US-6 AC-5.5
  - Command: `flutter test test/firebase/bootstrap_test.dart && node --test test/firebase/verify_config.test.mjs`
  - Expected: FAIL vì FirebaseOptions/emulator switch/verifier chưa có.

- [x] 7.3 Thêm dependencies và cấu hình Firebase/emulator tối thiểu
  - Reference: US-5 AC-2.3, US-6 AC-5.3, US-6 AC-5.4, US-6 AC-5.5
  - Files: `pubspec.yaml`, `lib/main.dart`, `lib/firebase_options_emulator.dart`, `firebase.json`, `firestore.indexes.json`, `tools/firebase/verify_config.mjs`
  - Thêm FlutterFire/Auth/App Check/Firestore/Storage/Functions/Google packages; chọn emulator trước khi tạo repository; không tạo anonymous UID, không bật analytics, không commit provider secret.

- [x] 7.4 Xác nhận GREEN cho guest bootstrap và release validator
  - Reference: US-5 AC-1.1, US-5 AC-2.3, US-6 AC-5.3, US-6 AC-5.4, US-6 AC-5.5
  - Command: `flutter test test/firebase/bootstrap_test.dart && node --test test/firebase/verify_config.test.mjs`
  - Expected: PASS bằng dummy emulator config; fixtures production thiếu input bị từ chối đúng thông báo.

### 8. Firestore/Storage Security Rules và schema enforcement

- [x] 8.1 Viết rules tests RED cho allowlist và deny-by-default
  - Reference: US-6 AC-1.1, US-6 AC-1.2, US-6 AC-5.1, US-6 AC-5.2, US-6 AC-5.3, US-6 AC-5.4, US-6 AC-5.5
  - Files: `test/rules/firestore.rules.test.ts`, `test/rules/storage.rules.test.ts`, `firestore.rules`, `storage.rules`, `package.json`
  - Cover own-UID exact read/progress transaction allow; cross-UID/guest/extra field/bad key/type/range/profile mutation/direct Storage write/list deny; lock denial; MIME/2MB/path checks; admin collections deny.

- [x] 8.2 Chạy Emulator rules tests để xác nhận RED
  - Reference: US-6 AC-5.1, US-6 AC-5.2, US-6 AC-5.3
  - Command: `firebase emulators:exec --only firestore,storage "npm test -- --runInBand test/rules" --project demo-cu-doi`
  - Expected: FAIL vì rules/schema test harness chưa được cài đặt, không do emulator port/config.

- [x] 8.3 Cài đặt Firestore/Storage Rules và test harness
  - Reference: US-6 AC-1.1, US-6 AC-1.2, US-6 AC-5.1, US-6 AC-5.2, US-6 AC-5.3, US-6 AC-5.4, US-6 AC-5.5
  - Files: `firestore.rules`, `storage.rules`, `firebase.json`, `package.json`, `test/rules/firestore.rules.test.ts`, `test/rules/storage.rules.test.ts`
  - Enforce dense 1..20 schema, exact v2/ranges, immutable mutation grammar/server time, deletion lock, exact-object Storage get; direct profile/avatar writes remain callable-only.

- [x] 8.4 Xác nhận GREEN cho rules suite
  - Reference: US-6 AC-5.1, US-6 AC-5.2, US-6 AC-5.3, US-6 AC-5.4, US-6 AC-5.5
  - Command: `firebase emulators:exec --only firestore,storage "npm test -- --runInBand test/rules" --project demo-cu-doi`
  - Expected: PASS toàn bộ allow/deny matrix và không có default-allow path.

### 9. Firebase Auth, liên kết provider và state machine danh tính

- [x] 9.1 Viết test RED cho sign-in/link/cancel/conflict/offline restore
  - Reference: US-5 AC-2.1, US-5 AC-2.2, US-5 AC-2.3, US-5 AC-2.4, US-5 AC-3.1, US-5 AC-3.2, US-5 AC-3.3, US-7 AC-1.1, US-7 AC-1.2, US-7 AC-1.3, US-7 AC-1.4, US-7 AC-1.5
  - Files: `test/state/account_controller_test.dart`, `lib/data/firebase_account_repository.dart`, `lib/state/account_controller.dart`
  - Cover Google/Apple separate, claim failure signs out, safe UID snapshot trước authenticated, `cachedAccountOffline`, no email auto-merge, `credential-already-in-use`, provider list unchanged on cancel/fail.

- [x] 9.2 Chạy account tests để xác nhận RED
  - Reference: US-5 AC-2.4, US-5 AC-3.1, US-5 AC-3.2, US-5 AC-3.3, US-7 AC-1.4, US-7 AC-1.5
  - Command: `flutter test test/state/account_controller_test.dart`
  - Expected: FAIL do repository/state machine chưa có.

- [x] 9.3 Cài đặt FirebaseAccountRepository và AccountController tối thiểu
  - Reference: US-5 AC-2.1, US-5 AC-2.2, US-5 AC-2.3, US-5 AC-2.4, US-5 AC-3.1, US-5 AC-3.2, US-5 AC-3.3, US-7 AC-1.1, US-7 AC-1.2, US-7 AC-1.3, US-7 AC-1.4, US-7 AC-1.5
  - Files: `lib/data/firebase_account_repository.dart`, `lib/state/account_controller.dart`, `lib/state/providers.dart`
  - Serialize transitions; Google dùng `google_sign_in`, Apple native/browser qua `AppleAuthProvider`; provider credential chỉ dùng cho Auth/link/reauth và không lưu trong profile/log.

- [x] 9.4 Xác nhận GREEN cho identity transitions
  - Reference: US-5 AC-2.4, US-5 AC-3.1, US-5 AC-3.2, US-5 AC-3.3, US-7 AC-1.2, US-7 AC-1.3, US-7 AC-1.4, US-7 AC-1.5
  - Command: `flutter test test/state/account_controller_test.dart test/state/progress_controller_test.dart`
  - Expected: PASS; auth callback cũ không kích hoạt sai owner.

### 10. Đồng bộ Firestore và mutation callable

- [x] 10.1 Viết test RED cho reconcile, retry và total-order profile mutation
  - Reference: US-2 AC-3.4, US-2 AC-3.5, US-6 AC-2.4, US-6 AC-2.5, US-6 AC-2.6, US-6 AC-3.3, US-6 AC-3.5, US-6 AC-4.1, US-6 AC-4.2, US-6 AC-4.3, US-6 AC-4.4, US-6 AC-4.5
  - Files: `test/data/firebase_sync_repository_test.dart`, `test/state/sync_controller_test.dart`, `functions/test/profile_mutations.test.ts`, `functions/src/profile_mutations.ts`
  - Cover first claim account-wins customization, single trusted timestamp outside retry closure, idempotent mutation ID, no rollback, offline queue/backoff 1s→5min ±20%, cap 100, app-kill resume, retry/manual status.

- [x] 10.2 Chạy client/backend sync tests để xác nhận RED
  - Reference: US-6 AC-2.4, US-6 AC-2.5, US-6 AC-2.6, US-6 AC-4.3, US-6 AC-4.4, US-6 AC-4.5
  - Command: `flutter test test/data/firebase_sync_repository_test.dart test/state/sync_controller_test.dart && npm --prefix functions test -- profile_mutations.test.ts`
  - Expected: FAIL vì repository/controller/callable chưa tồn tại.

- [x] 10.3 Cài đặt SyncController, Firestore transaction và commitProfileMutation
  - Reference: US-2 AC-3.4, US-2 AC-3.5, US-6 AC-2.4, US-6 AC-2.5, US-6 AC-2.6, US-6 AC-3.3, US-6 AC-3.5, US-6 AC-4.1, US-6 AC-4.2, US-6 AC-4.3, US-6 AC-4.4, US-6 AC-4.5
  - Files: `lib/data/firebase_sync_repository.dart`, `lib/state/sync_controller.dart`, `lib/state/providers.dart`, `functions/package.json`, `functions/tsconfig.json`, `functions/src/index.ts`, `functions/src/profile_mutations.ts`, `functions/src/runtime_config.ts`
  - Progress client transaction chỉ cùng UID và lock-aware; profile callable Auth+App Check validate Unicode/payload, dùng một server timestamp ổn định; persist backoff/queue state.

- [x] 10.4 Xác nhận GREEN cho sync và restart cases
  - Reference: US-6 AC-2.5, US-6 AC-2.6, US-6 AC-3.3, US-6 AC-3.5, US-6 AC-4.1, US-6 AC-4.2, US-6 AC-4.3, US-6 AC-4.4, US-6 AC-4.5
  - Command: `flutter test test/data/firebase_sync_repository_test.dart test/state/sync_controller_test.dart && npm --prefix functions test -- profile_mutations.test.ts`
  - Expected: PASS cho concurrent mutation, offline/restart/retry và stale cloud snapshot.

### 11. Avatar cloud callable, restore cache và orphan cleanup

- [x] 11.1 Viết test RED cho upload/reference/delete/download/cleanup
  - Reference: US-3 AC-3.6, US-3 AC-3.7, US-3 AC-3.8, US-3 AC-3.9, US-6 AC-1.2, US-6 AC-5.2
  - Files: `functions/test/avatar_service.test.ts`, `functions/test/avatar_cleanup.test.ts`, `test/data/avatar_cache_repository_test.dart`, `functions/src/avatar_service.ts`, `functions/src/avatar_cleanup.ts`
  - Cover Auth/App Check/owner epoch/lock/MIME/hash/size, immutable object, exact path restore, upload→Firestore ref→old delete, partial retry, orphan >24h recheck, invalid download temp cleanup.

- [x] 11.2 Chạy avatar cloud tests để xác nhận RED
  - Reference: US-3 AC-3.6, US-3 AC-3.7, US-3 AC-3.8, US-3 AC-3.9, US-6 AC-1.2, US-6 AC-5.2
  - Command: `flutter test test/data/avatar_cache_repository_test.dart && npm --prefix functions test -- avatar_service.test.ts avatar_cleanup.test.ts`
  - Expected: FAIL do callable/cache/cleanup chưa tồn tại.

- [x] 11.3 Cài đặt avatar callables, validated cache và scheduled cleanup
  - Reference: US-3 AC-3.6, US-3 AC-3.7, US-3 AC-3.8, US-3 AC-3.9, US-6 AC-1.2, US-6 AC-5.2
  - Files: `lib/data/avatar_cache_repository.dart`, `functions/src/avatar_service.ts`, `functions/src/avatar_cleanup.ts`, `functions/src/index.ts`, `functions/src/runtime_config.ts`
  - Stream exact object vào temp; validate owner/path/JPEG-WebP/≤2MB/≤1024/hash/64MB; callable writes/deletes lock-aware; cleanup dùng generation/checkpoint idempotent.

- [x] 11.4 Xác nhận GREEN cho avatar cloud lifecycle
  - Reference: US-3 AC-3.6, US-3 AC-3.7, US-3 AC-3.8, US-3 AC-3.9, US-6 AC-1.2, US-6 AC-5.2
  - Command: `flutter test test/data/avatar_cache_repository_test.dart && npm --prefix functions test -- avatar_service.test.ts avatar_cleanup.test.ts`
  - Expected: PASS và không có trạng thái trung gian trỏ tới avatar hỏng.

### 12. Backend xóa tài khoản bền vững

- [x] 12.1 Viết test RED cho deletion job, receipt và provider recovery
  - Reference: US-7 AC-3.2, US-7 AC-3.5, US-7 AC-3.6, US-7 AC-3.7
  - Files: `functions/test/account_deletion.test.ts`, `functions/src/account_deletion.ts`
  - Cover recent auth/App Check/idempotency; receipt 256-bit hash/rate limit; Storage→Firestore→provider revoke→refresh-token disable→Auth delete; checkpoints; Apple credential KMS TTL 26h; `providerRecoveryRequired`/`refreshDeletionProof`; 70min sweep; terminal TTL 7d; safe logs.

- [x] 12.2 Chạy deletion backend tests để xác nhận RED
  - Reference: US-7 AC-3.2, US-7 AC-3.5, US-7 AC-3.6, US-7 AC-3.7
  - Command: `npm --prefix functions test -- account_deletion.test.ts`
  - Expected: FAIL vì callable/worker/checkpoint chưa tồn tại.

- [x] 12.3 Cài đặt callables và Cloud Tasks deletion worker tối thiểu
  - Reference: US-7 AC-3.2, US-7 AC-3.5, US-7 AC-3.6, US-7 AC-3.7
  - Files: `functions/src/account_deletion.ts`, `functions/src/index.ts`, `functions/src/runtime_config.ts`, `functions/package.json`, `firebase.json`
  - Resolve UID từ auth context; lock trước enqueue; giữ Auth cho tới provider revoke; status bằng App Check+receipt; retry 24h rồi yêu cầu proof mới; Auth record xóa cuối và final sweep trước terminal.

- [x] 12.4 Xác nhận GREEN cho deletion failure matrix
  - Reference: US-7 AC-3.5, US-7 AC-3.6, US-7 AC-3.7
  - Command: `npm --prefix functions test -- account_deletion.test.ts`
  - Expected: PASS ở mỗi injected checkpoint failure, duplicate begin, expired proof và recreation attempt.

### 13. Client deletion state machine và guest handoff

- [x] 13.1 Viết test RED cho local deletion precommit/freeze/poll/recovery
  - Reference: US-7 AC-3.1, US-7 AC-3.2, US-7 AC-3.3, US-7 AC-3.4, US-7 AC-3.6, US-7 AC-3.7, US-7 AC-3.8
  - Files: `test/state/account_controller_test.dart`, `lib/data/account_deletion_repository.dart`, `lib/state/account_controller.dart`
  - Cover cancel trước pending, snapshot/guest avatar copy failure abort, epoch freeze, auth listener suppression, guest progress tiếp tục, receipt polling 5s→60s/10s deadline, provider proof refresh, support state và cleanup UID metadata chỉ khi terminal.

- [x] 13.2 Chạy deletion controller tests để xác nhận RED
  - Reference: US-7 AC-3.3, US-7 AC-3.4, US-7 AC-3.6, US-7 AC-3.7, US-7 AC-3.8
  - Command: `flutter test test/state/account_controller_test.dart --plain-name "account deletion"`
  - Expected: FAIL do repository/deletion phases chưa có.

- [x] 13.3 Cài đặt AccountDeletionRepository và client transitions
  - Reference: US-7 AC-3.1, US-7 AC-3.2, US-7 AC-3.3, US-7 AC-3.4, US-7 AC-3.6, US-7 AC-3.7, US-7 AC-3.8
  - Files: `lib/data/account_deletion_repository.dart`, `lib/state/account_controller.dart`, `lib/data/local_player_store.dart`, `lib/state/providers.dart`
  - Persist guest snapshot+pending trước callable; mọi edit mới vào guest; giữ session chỉ cho proof recovery; không báo success hay xóa UID cache trước terminal.

- [x] 13.4 Xác nhận GREEN cho deletion client lifecycle
  - Reference: US-7 AC-3.3, US-7 AC-3.4, US-7 AC-3.6, US-7 AC-3.7, US-7 AC-3.8
  - Command: `flutter test test/state/account_controller_test.dart test/data/local_player_store_test.dart`
  - Expected: PASS cho cancel, local-write failure, process restart, provider recovery và terminal cleanup.

### 14. PlayerAvatar và điểm vào Hồ sơ từ menu

- [x] 14.1 Viết widget test RED cho avatar/panel semantics và navigation
  - Reference: US-1 AC-1.1, US-1 AC-1.2, US-1 AC-1.3, US-2 AC-3.3, US-3 AC-4.2
  - Files: `test/ui/menu_profile_entry_test.dart`, `test/ui/player_avatar_test.dart`, `lib/ui/screens/menu_screen.dart`, `lib/ui/widgets/player_avatar.dart`
  - Assert toàn identity card là một control ≥48dp, một semantic label, avatar decorative không focus thừa, settings/coin/star giữ nguyên, back giữ menu state và tên dài co/lược hợp lý.

- [x] 14.2 Chạy menu/avatar widget tests để xác nhận RED
  - Reference: US-1 AC-1.1, US-1 AC-1.2, US-1 AC-1.3, US-3 AC-4.2
  - Command: `flutter test test/ui/menu_profile_entry_test.dart test/ui/player_avatar_test.dart`
  - Expected: FAIL vì route/control/widget chưa tồn tại.

- [x] 14.3 Cài đặt PlayerAvatar và menu profile route
  - Reference: US-1 AC-1.1, US-1 AC-1.2, US-1 AC-1.3, US-2 AC-3.3, US-3 AC-4.2
  - Files: `lib/ui/widgets/player_avatar.dart`, `lib/ui/screens/menu_screen.dart`, `lib/ui/screens/profile_screen.dart`
  - Render preset/app-private/fallback; interactive semantics chỉ khi có action; wrap identity panel mà không gộp settings/counters.

- [x] 14.4 Xác nhận GREEN cho menu navigation regression
  - Reference: US-1 AC-1.1, US-1 AC-1.2, US-1 AC-1.3, US-2 AC-3.3, US-3 AC-4.2
  - Command: `flutter test test/ui/menu_profile_entry_test.dart test/ui/player_avatar_test.dart test/app_smoke_test.dart`
  - Expected: PASS và nút Settings/counters không bị mất.

### 15. Khung ProfileScreen, overview và localization

- [x] 15.1 Viết widget/golden tests RED cho layout và trạng thái tổng quan
  - Reference: US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.3, US-1 AC-2.4, US-1 AC-2.5, US-1 AC-3.1, US-1 AC-3.2, US-1 AC-3.3, US-1 AC-3.4, US-1 AC-3.5
  - Files: `test/ui/profile_screen_test.dart`, `test/ui/profile_screen_golden_test.dart`, `test/l10n/arb_parity_test.dart`, `lib/ui/screens/profile_screen.dart`
  - Cover restoring không flash zero, guest/auth/sync state, zero encouragement, metrics, night-arcade tokens, 390×844/small/tablet/text-scale 2.0, scroll/safe area và status không color-only.

- [x] 15.2 Chạy profile tests để xác nhận RED
  - Reference: US-1 AC-2.4, US-1 AC-2.5, US-1 AC-3.1, US-1 AC-3.2, US-1 AC-3.3, US-1 AC-3.4, US-1 AC-3.5
  - Command: `flutter test test/ui/profile_screen_test.dart test/ui/profile_screen_golden_test.dart test/l10n/arb_parity_test.dart`
  - Expected: FAIL vì screen/ARB strings/states chưa hoàn chỉnh.

- [x] 15.3 Dựng ProfileScreen overview và VI/EN strings
  - Reference: US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.3, US-1 AC-2.4, US-1 AC-2.5, US-1 AC-3.1, US-1 AC-3.2, US-1 AC-3.3, US-1 AC-3.4, US-1 AC-3.5
  - Files: `lib/ui/screens/profile_screen.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`, `lib/l10n/app_localizations*.dart`
  - Reuse `BbCard`/`BbButton`/`BbTokens`, maxWidth 440dp, vertical scroll/reflow, stable restored snapshot; chạy `flutter gen-l10n` sau ARB changes.

- [x] 15.4 Xác nhận GREEN cho overview, golden và ARB parity
  - Reference: US-1 AC-2.1, US-1 AC-2.3, US-1 AC-2.4, US-1 AC-3.1, US-1 AC-3.2, US-1 AC-3.3, US-1 AC-3.4, US-1 AC-3.5
  - Command: `flutter gen-l10n && flutter test test/ui/profile_screen_test.dart test/ui/profile_screen_golden_test.dart test/l10n/arb_parity_test.dart`
  - Expected: PASS ở VI/EN, viewports và text scale đã định.

### 16. UI chương, kỷ lục và huy hiệu

- [x] 16.1 Viết widget tests RED cho 4 accordion, 20 record và 8 badge
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-2.1, US-4 AC-2.2, US-4 AC-2.3, US-4 AC-2.4, US-4 AC-2.5, US-4 AC-3.1, US-4 AC-3.2, US-4 AC-3.3, US-4 AC-3.4, US-4 AC-3.5
  - Files: `test/ui/profile_screen_test.dart`, `lib/ui/screens/profile_screen.dart`, `lib/domain/profile_summary.dart`
  - Assert localized arena names, skipped/unopened/incomplete/completed distinctions, no score-0 record, one default-expanded chapter, lazy rows, numeric progress cap và badge unlocked bằng icon/outline+text.

- [x] 16.2 Chạy profile detail tests để xác nhận RED
  - Reference: US-4 AC-1.2, US-4 AC-2.1, US-4 AC-2.3, US-4 AC-2.4, US-4 AC-3.3, US-4 AC-3.4
  - Command: `flutter test test/ui/profile_screen_test.dart --plain-name "progress details"`
  - Expected: FAIL vì detail sections chưa được nối.

- [x] 16.3 Cài đặt progress/badge/record sections
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-2.1, US-4 AC-2.2, US-4 AC-2.3, US-4 AC-2.4, US-4 AC-2.5, US-4 AC-3.1, US-4 AC-3.2, US-4 AC-3.3, US-4 AC-3.4, US-4 AC-3.5
  - Files: `lib/ui/screens/profile_screen.dart`, `lib/domain/profile_summary.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`
  - Build bốn accessible expansion panels và lazy five-row lists; render chỉ best result/derived badge, không thêm persistence/history.

- [x] 16.4 Xác nhận GREEN cho detail UI và domain consistency
  - Reference: US-4 AC-1.3, US-4 AC-2.2, US-4 AC-2.5, US-4 AC-3.2, US-4 AC-3.5
  - Command: `flutter gen-l10n && flutter test test/ui/profile_screen_test.dart test/domain/profile_summary_test.dart`
  - Expected: PASS và UI dùng cùng một `ProfileSummary` tất định.

### 17. AvatarEditorScreen và system picker

- [x] 17.1 Viết widget tests RED cho preset, picker, crop và error states
  - Reference: US-3 AC-1.1, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.4, US-3 AC-2.5, US-3 AC-2.6, US-3 AC-4.1, US-3 AC-4.2
  - Files: `test/ui/avatar_editor_screen_test.dart`, `lib/ui/screens/avatar_editor_screen.dart`
  - Cover sáu preset (`pangolin|galaxy` × gold/blue/purple), selected check+outline+semantics, confirm/cancel, system picker just-in-time, square preview, deny/cancel no-op, processing failure retry và localized privacy copy.

- [x] 17.2 Chạy avatar editor tests để xác nhận RED
  - Reference: US-3 AC-1.1, US-3 AC-1.2, US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.4
  - Command: `flutter test test/ui/avatar_editor_screen_test.dart`
  - Expected: FAIL vì editor/picker seams chưa tồn tại.

- [x] 17.3 Cài đặt AvatarEditorScreen và nối ProfileController
  - Reference: US-3 AC-1.1, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.4, US-3 AC-2.5, US-3 AC-2.6, US-3 AC-4.1, US-3 AC-4.2
  - Files: `lib/ui/screens/avatar_editor_screen.dart`, `lib/ui/screens/profile_screen.dart`, `lib/state/profile_controller.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`, `pubspec.yaml`
  - Dùng `image_picker` system flow, Flutter crop surface và processing repository; không camera/eager broad-gallery permission; confirm mới commit.

- [x] 17.4 Xác nhận GREEN cho avatar UI và data recovery
  - Reference: US-3 AC-1.3, US-3 AC-2.4, US-3 AC-2.5, US-3 AC-2.6, US-3 AC-4.1, US-3 AC-4.2
  - Command: `flutter gen-l10n && flutter test test/ui/avatar_editor_screen_test.dart test/data/avatar_repository_test.dart`
  - Expected: PASS; cancel/deny/failure không thay avatar đã lưu.

### 18. UI đăng nhập, provider, logout và deletion states

- [x] 18.1 Viết widget tests RED cho account card và destructive flows
  - Reference: US-5 AC-2.1, US-5 AC-2.2, US-5 AC-3.1, US-5 AC-3.2, US-7 AC-1.1, US-7 AC-1.2, US-7 AC-1.4, US-7 AC-1.5, US-7 AC-2.1, US-7 AC-2.2, US-7 AC-2.3, US-7 AC-2.4, US-7 AC-3.1, US-7 AC-3.2, US-7 AC-3.6, US-7 AC-3.7, US-7 AC-3.8
  - Files: `test/ui/profile_screen_test.dart`, `lib/ui/screens/profile_screen.dart`
  - Cover branded Google/Apple actions cả Android/iOS, ≥48dp/semantics, link state/conflict, sign-out confirm/guest copy/pending, deletion confirmation/reauth/submitting/server/retry/providerRecovery/support/completed và request-ID copy fallback.

- [x] 18.2 Chạy account UI tests để xác nhận RED
  - Reference: US-5 AC-2.1, US-5 AC-2.2, US-7 AC-2.1, US-7 AC-3.1, US-7 AC-3.7
  - Command: `flutter test test/ui/profile_screen_test.dart --plain-name "account actions"`
  - Expected: FAIL vì account card/dialog/state rendering chưa đầy đủ.

- [x] 18.3 Cài đặt account card, branded actions và lifecycle dialogs
  - Reference: US-5 AC-2.1, US-5 AC-2.2, US-5 AC-3.1, US-5 AC-3.2, US-7 AC-1.1, US-7 AC-1.2, US-7 AC-1.4, US-7 AC-1.5, US-7 AC-2.1, US-7 AC-2.2, US-7 AC-2.3, US-7 AC-2.4, US-7 AC-3.1, US-7 AC-3.2, US-7 AC-3.6, US-7 AC-3.7, US-7 AC-3.8
  - Files: `lib/ui/screens/profile_screen.dart`, `assets/images/auth/google_sign_in.png`, `assets/images/auth/apple_sign_in.png`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`, `pubspec.yaml`
  - Dùng provider brand resources chính thức; UI không ẩn provider; deletion pending vẫn cho guest gameplay và chỉ báo success ở terminal.

- [x] 18.4 Xác nhận GREEN cho account UI states
  - Reference: US-5 AC-3.1, US-5 AC-3.2, US-7 AC-1.4, US-7 AC-1.5, US-7 AC-2.2, US-7 AC-2.3, US-7 AC-2.4, US-7 AC-3.6, US-7 AC-3.7, US-7 AC-3.8
  - Command: `flutter gen-l10n && flutter test test/ui/profile_screen_test.dart test/state/account_controller_test.dart`
  - Expected: PASS cho mọi AccountPhase và cancel/failure không làm mất dữ liệu.

### 19. Nhắc đăng nhập sau màn đầu và guard Settings

- [x] 19.1 Viết widget tests RED cho reminder và reset guard
  - Reference: US-5 AC-1.3, US-7 AC-2.1, US-7 AC-2.2, US-7 AC-2.3, US-7 AC-2.4
  - Files: `test/ui/game_screen_reminder_test.dart`, `test/ui/settings_profile_guard_test.dart`, `lib/ui/screens/game_screen.dart`, `lib/ui/screens/settings_screen.dart`
  - Assert reminder đúng một lần sau kết quả ổn định, không khi ball bay, Sign in focus account card, dismiss persisted; signed-in/offline/deletion không dùng local reset gây cloud restore; logout tạo full UID-derived guest copy.

- [x] 19.2 Chạy reminder/settings tests để xác nhận RED
  - Reference: US-5 AC-1.3, US-7 AC-2.1, US-7 AC-2.2, US-7 AC-2.4
  - Command: `flutter test test/ui/game_screen_reminder_test.dart test/ui/settings_profile_guard_test.dart`
  - Expected: FAIL ở persisted reminder/account-phase guard.

- [x] 19.3 Cài đặt result-sheet reminder, logout copy và Settings guard
  - Reference: US-5 AC-1.3, US-7 AC-2.1, US-7 AC-2.2, US-7 AC-2.3, US-7 AC-2.4
  - Files: `lib/ui/screens/game_screen.dart`, `lib/ui/screens/settings_screen.dart`, `lib/state/account_controller.dart`, `lib/data/local_player_store.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`
  - Lưu flag trong guest envelope; route Profile có account focus; copy snapshot/avatar nguyên tử trước sign-out, giữ UID pending riêng và cho offline logout.

- [x] 19.4 Xác nhận GREEN và gameplay timing regression
  - Reference: US-5 AC-1.3, US-7 AC-2.2, US-7 AC-2.3, US-7 AC-2.4
  - Command: `flutter gen-l10n && flutter test test/ui/game_screen_reminder_test.dart test/ui/settings_profile_guard_test.dart test/ui/game_screen_feedback_test.dart`
  - Expected: PASS; reminder không ngắt shot/result animation và logout không chuyển pending sang UID khác.

### 20. Platform provider configuration và automated release smoke

- [x] 20.1 Viết/hoàn thiện config tests RED cho Android/iOS provider wiring
  - Reference: US-3 AC-2.1, US-3 AC-4.1, US-5 AC-2.2, US-5 AC-2.3, US-6 AC-5.4
  - Files: `test/firebase/verify_config.test.mjs`, `tools/firebase/verify_config.mjs`, `android/app/build.gradle.kts`, `android/settings.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, `ios/Runner.xcodeproj/project.pbxproj`
  - Assert Google services plugin/URL schemes, Apple entitlement/capability, picker purpose copy, no eager media permission, generated file membership và absence of private keys/secrets.

- [x] 20.2 Chạy platform verifier để xác nhận RED
  - Reference: US-3 AC-2.1, US-3 AC-4.1, US-5 AC-2.2, US-5 AC-2.3
  - Command: `node --test test/firebase/verify_config.test.mjs`
  - Expected: FAIL cụ thể vì Android/iOS wiring/generated-input fixtures còn thiếu.

- [x] 20.3 Thêm platform config có thể kiểm thử, không điền production identity giả
  - Reference: US-3 AC-2.1, US-3 AC-4.1, US-5 AC-2.2, US-5 AC-2.3, US-6 AC-5.4
  - Files: `android/app/build.gradle.kts`, `android/settings.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `android/app/google-services.json`, `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements`, `ios/Runner.xcodeproj/project.pbxproj`, `ios/Runner/GoogleService-Info.plist`, `lib/firebase_options.dart`, `tools/firebase/verify_config.mjs`
  - Wire build files/capabilities and generated-file contracts; giữ production generated files/value inputs ở trạng thái verifier-managed cho tới khi owner chốt IDs, không commit Apple key/KMS secret.

- [x] 20.4 Xác nhận GREEN cho config fixtures và emulator build path
  - Reference: US-3 AC-2.1, US-5 AC-2.3, US-6 AC-5.4
  - Command: `node --test test/firebase/verify_config.test.mjs && flutter test test/firebase/bootstrap_test.dart`
  - Expected: PASS cho emulator/complete fixture; production workspace thiếu external release input được báo có cấu trúc thay vì làm hỏng guest runtime.

### 21. Emulator integration, process-restart và performance guards

- [x] 21.1 Viết integration tests RED cho luồng đa thiết bị và failure injection
  - Reference: US-3 AC-3.6, US-3 AC-3.7, US-3 AC-3.8, US-3 AC-3.9, US-5 AC-2.4, US-6 AC-4.2, US-6 AC-4.3, US-6 AC-4.4, US-6 AC-4.5, US-7 AC-1.3, US-7 AC-3.4, US-7 AC-3.5, US-7 AC-3.7
  - Files: `integration_test/profile_firebase_emulator_test.dart`, `test/performance/profile_sync_performance_test.dart`, `firebase.json`
  - Cover guest claim→merge, two devices, concurrent transaction, offline edit/relaunch/reconnect, custom avatar second-device restore, restart ở từng stage, provider link same UID, deletion lock/recreation và pending sync không chạy trong `Ticker`/painter.

- [x] 21.2 Chạy integration suite để xác nhận RED
  - Reference: US-5 AC-2.4, US-6 AC-4.2, US-6 AC-4.3, US-6 AC-4.4, US-6 AC-4.5, US-7 AC-3.4, US-7 AC-3.5
  - Command: `firebase emulators:exec --only auth,firestore,storage,functions "flutter test integration_test/profile_firebase_emulator_test.dart test/performance/profile_sync_performance_test.dart" --project demo-cu-doi`
  - Expected: FAIL ở unwired integration seams/failure checkpoints, không do production credentials.

- [x] 21.3 Hoàn thiện wiring providers, emulator fixtures và restart hooks
  - Reference: US-3 AC-3.6, US-3 AC-3.7, US-3 AC-3.8, US-3 AC-3.9, US-5 AC-2.4, US-6 AC-4.2, US-6 AC-4.3, US-6 AC-4.4, US-6 AC-4.5, US-7 AC-1.3, US-7 AC-3.4, US-7 AC-3.5, US-7 AC-3.7
  - Files: `lib/main.dart`, `lib/state/providers.dart`, `integration_test/profile_firebase_emulator_test.dart`, `test/performance/profile_sync_performance_test.dart`, `firebase.json`
  - Wire Auth/Firestore/Storage/Functions repositories only after local restore/emulator selection; add deterministic fake clocks/process-restart/failure injection; tránh Firebase work trong gameplay frame loop.

- [x] 21.4 Xác nhận GREEN cho integration và performance budgets
  - Reference: US-6 AC-4.2, US-6 AC-4.3, US-6 AC-4.4, US-6 AC-4.5, US-7 AC-3.4, US-7 AC-3.5, US-7 AC-3.7
  - Command: `firebase emulators:exec --only auth,firestore,storage,functions "flutter test integration_test/profile_firebase_emulator_test.dart test/performance/profile_sync_performance_test.dart" --project demo-cu-doi`
  - Expected: PASS; pending sync không làm thay đổi frame-work assertions và deletion lock chặn recreate.

### 22. Hoàn thiện generated files và regression suite

- [x] 22.1 Thêm boundary/regression assertions còn thiếu trước khi final wiring
  - Reference: US-1 AC-3.5, US-3 AC-2.3, US-4 AC-4.2, US-4 AC-4.3, US-6 AC-5.1, US-6 AC-5.2, US-6 AC-5.3, US-6 AC-5.4, US-6 AC-5.5
  - Files: `test/boundary_test.dart`, `test/l10n/arb_parity_test.dart`, `test/app_smoke_test.dart`, `test/firebase/bootstrap_test.dart`
  - Assert `lib/sim/` không import Flutter/Firebase, không event-log/analytics dependency, ARB parity, guest smoke không mạng, avatar bounds và Firebase protected paths.

- [x] 22.2 Chạy targeted regression để bắt RED còn lại
  - Reference: US-1 AC-3.5, US-4 AC-4.2, US-4 AC-4.3, US-6 AC-5.3, US-6 AC-5.5
  - Command: `flutter test test/boundary_test.dart test/l10n/arb_parity_test.dart test/app_smoke_test.dart test/firebase/bootstrap_test.dart`
  - Expected: mọi assertion mới phải FAIL đúng ở wiring/generated output còn thiếu trước khi chỉnh production code.

- [x] 22.3 Sinh localization, sửa wiring tối thiểu và khóa phạm vi
  - Reference: US-1 AC-3.5, US-3 AC-2.3, US-4 AC-4.2, US-4 AC-4.3, US-6 AC-5.1, US-6 AC-5.2, US-6 AC-5.3, US-6 AC-5.4, US-6 AC-5.5
  - Files: `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_vi.dart`, `lib/state/providers.dart`, `lib/main.dart`, `pubspec.yaml`
  - Chạy generator và chỉ sửa integration gaps có failing test; không sửa `lib/sim/`, solver, campaign, balance hoặc thêm analytics/social/history.

- [x] 22.4 Chạy toàn bộ static analysis, Flutter, Functions và rules tests
  - Reference: US-1 AC-3.5, US-3 AC-2.3, US-4 AC-4.2, US-4 AC-4.3, US-6 AC-5.1, US-6 AC-5.2, US-6 AC-5.3, US-6 AC-5.4, US-6 AC-5.5
  - Command: `flutter gen-l10n && flutter analyze && flutter test && npm --prefix functions test && firebase emulators:exec --only firestore,storage "npm test -- --runInBand test/rules" --project demo-cu-doi`
  - Expected: PASS toàn bộ; production provider/device E2E vẫn được release verifier nhận diện là external input, không được giả lập bằng secret trong repo.

## Next Steps

Once this task plan is approved, proceed to Phase 4: Task Execution.

**What to do next:**
1. Use the slash command: `/aidlc.construction.execute-task [task-number]`
2. The agent will automatically read:
   - `requirements.md` - Feature requirements
   - `design.md` - Design decisions
   - `tasks.md` - This task list
   - `mockup.html` - HTML UI handoff (if present, read before any UI task)
   - `references/phase-4-execution.md` - Execution workflow instructions
   - Foundation docs for implementation patterns
3. Tasks will be marked complete with checkboxes after execution

**Example**: To execute task 1.1, use `/aidlc.construction.execute-task 1.1`
