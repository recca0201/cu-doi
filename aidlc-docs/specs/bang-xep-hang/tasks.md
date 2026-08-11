---
artifact_type: tasks
phase: construction
status: approved
created: 2026-08-11
updated: 2026-08-11
unit: bang-xep-hang
source_artifacts:
  - aidlc-docs/specs/bang-xep-hang/requirements.md
  - aidlc-docs/specs/bang-xep-hang/design.md
---

# Tasks: Bảng xếp hạng theo màn

## Implementation Checklist

### 1. Chính sách điểm và kết quả lưu tiến trình

- [x] 1.1 Viết test đỏ cho chính sách điểm hợp lệ và kết quả ghi tiến trình
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-3.1, US-4 AC-3.2
  - Files: `test/domain/leaderboard_score_policy_test.dart`, `test/state/progress_controller_test.dart`, `lib/domain/leaderboard_score_policy.dart`, `lib/state/providers.dart`
  - Bao phủ arena 1..20; thắng/bỏ qua/thua; điểm 0, không bằng kỷ lục, vượt `targetCount × 100 × kMaxMultiplier`; và `RecordOutcome` chỉ báo kỷ lục mới sau khi lưu thành công.
  - Expected: test thất bại vì policy và `RecordOutcome` chưa tồn tại.

- [x] 1.2 Chạy test mục tiêu và xác nhận đúng trạng thái đỏ
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-3.1, US-4 AC-3.2
  - Command: `flutter test test/domain/leaderboard_score_policy_test.dart test/state/progress_controller_test.dart`
  - Expected: FAIL do thiếu hành vi mới, không phải lỗi fixture, font hay cấu hình Flutter.

- [x] 1.3 Cài đặt model leaderboard, policy thuần Dart và `RecordOutcome`
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-3.1, US-4 AC-3.2, US-4 AC-5.2
  - Files: `lib/core/leaderboard_limits.dart`, `lib/domain/leaderboard_models.dart`, `lib/domain/leaderboard_score_policy.dart`, `lib/state/providers.dart`
  - Đọc trực tiếp `kArenas`, `kMaxMultiplier`; đổi `ProgressController.record()` để trả snapshot hậu lưu bất biến và không thêm Flutter/network import vào `lib/sim/`.
  - Giữ nguyên luật dội, hằng số cân bằng và `lib/sim/arenas.dart` generated.

- [x] 1.4 Chạy lại unit test chính sách và tiến trình tới trạng thái xanh
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-3.1, US-4 AC-3.2, US-4 AC-5.2
  - Command: `flutter test test/domain/leaderboard_score_policy_test.dart test/state/progress_controller_test.dart test/domain/player_progress_test.dart`
  - Expected: PASS và các regression hiện có của `PlayerProgress` vẫn xanh.

### 2. Phân vùng danh tính, cache và hàng đợi bền vững

- [x] 2.1 Viết test đỏ cho salt danh tính, snapshot cache và submission queue
  - Reference: US-2 AC-2.4, US-2 AC-3.4, US-3 AC-1.1, US-3 AC-3.1, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4, US-4 AC-2.3, US-4 AC-2.4, US-4 AC-3.4, US-4 AC-4.1, US-4 AC-4.5, US-4 AC-5.3, US-4 AC-5.4
  - Files: `test/data/local_leaderboard_store_test.dart`, `lib/data/identity_hasher.dart`, `lib/data/local_leaderboard_store.dart`
  - Bao phủ salt ổn định qua restart; purge namespace khi salt mất/hỏng; key platform + identity hash + arena + scope; default/restore scope; cache exact-match; giới hạn 100 hàng, 128 KiB và 40 snapshot/identity; queue highest-only và permanent-failure.
  - Expected: test thất bại vì store và hasher chưa tồn tại.

- [x] 2.2 Chạy test store và xác nhận đúng trạng thái đỏ
  - Reference: US-3 AC-1.1, US-3 AC-3.1, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4, US-4 AC-2.3, US-4 AC-2.4, US-4 AC-3.4, US-4 AC-4.1, US-4 AC-4.5, US-4 AC-5.3, US-4 AC-5.4
  - Command: `flutter test test/data/local_leaderboard_store_test.dart`
  - Expected: FAIL do thiếu API persistence, không phải lỗi `SharedPreferences` mock.

- [x] 2.3 Cài đặt `IdentityHasher` và `LocalLeaderboardStore` theo envelope versioned
  - Reference: US-2 AC-2.4, US-2 AC-3.4, US-3 AC-1.1, US-3 AC-3.1, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4, US-4 AC-2.3, US-4 AC-2.4, US-4 AC-3.4, US-4 AC-4.1, US-4 AC-4.5, US-4 AC-5.3, US-4 AC-5.4
  - Files: `lib/data/identity_hasher.dart`, `lib/data/local_leaderboard_store.dart`
  - Dùng ghi nối đuôi theo key, không lưu raw player ID/avatar token/bytes, không dùng một blob đa tài khoản; backfill marker chỉ ghi sau khi mọi record hợp lệ đã được xếp hàng bền vững.
  - Xóa application data tự nhiên loại bỏ salt/cache/queue; dữ liệu corrupt bị cách ly và tuyệt đối không được submit.

- [x] 2.4 Chạy lại test persistence và regression local store tới trạng thái xanh
  - Reference: US-3 AC-1.1, US-3 AC-3.1, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4, US-4 AC-2.3, US-4 AC-2.4, US-4 AC-3.4, US-4 AC-4.1, US-4 AC-4.5, US-4 AC-5.3, US-4 AC-5.4
  - Command: `flutter test test/data/local_leaderboard_store_test.dart test/data/local_player_store_test.dart test/data/progress_roundtrip_test.dart`
  - Expected: PASS, không rò dữ liệu giữa tài khoản và không phá persistence hiện có.

### 3. Gateway nền tảng và hợp đồng MethodChannel

- [x] 3.1 Viết test đỏ cho payload, timeout, avatar và phân loại lỗi gateway
  - Reference: US-2 AC-1.2, US-2 AC-2.1, US-2 AC-2.2, US-2 AC-2.3, US-2 AC-2.4, US-2 AC-3.1, US-2 AC-3.2, US-2 AC-3.3, US-3 AC-1.4, US-3 AC-1.7, US-3 AC-1.8, US-3 AC-2.3, US-4 AC-1.4, US-4 AC-4.5
  - Files: `test/data/game_services_gateway_test.dart`, `test/data/platform_avatar_test.dart`, `lib/data/game_services_gateway.dart`, `lib/data/method_channel_game_services_gateway.dart`, `lib/core/platform_avatar.dart`
  - Bao phủ channel versioned; silent/interactive auth; cancel/restricted/friends unavailable/unauthenticated/retryable/permanent/unsupported; deadline đọc 10s, submit 8s, avatar 5s; avatar ≤256 KiB, concurrency 4, LRU 32/8 MiB và epoch/player-hash guard.
  - Expected: test thất bại vì gateway và avatar loader chưa tồn tại.

- [x] 3.2 Chạy test gateway và xác nhận đúng trạng thái đỏ
  - Reference: US-2 AC-1.2, US-2 AC-2.1, US-2 AC-2.2, US-2 AC-2.3, US-2 AC-2.4, US-3 AC-2.3, US-4 AC-4.5
  - Command: `flutter test test/data/game_services_gateway_test.dart test/data/platform_avatar_test.dart`
  - Expected: FAIL do thiếu contract/adapter, không phải do channel mock chưa reset.

- [x] 3.3 Cài đặt gateway Dart, adapter MethodChannel và avatar loader có giới hạn
  - Reference: US-2 AC-1.2, US-2 AC-2.1, US-2 AC-2.2, US-2 AC-2.3, US-2 AC-2.4, US-2 AC-3.1, US-2 AC-3.2, US-2 AC-3.3, US-3 AC-1.4, US-3 AC-1.7, US-3 AC-1.8, US-3 AC-2.3, US-4 AC-1.4, US-4 AC-4.5
  - Files: `lib/data/game_services_gateway.dart`, `lib/data/method_channel_game_services_gateway.dart`, `lib/core/platform_avatar.dart`, `lib/core/leaderboard_limits.dart`
  - Dart chỉ truyền `arenaId`; native là authority ánh xạ leaderboard ID. Chuẩn hóa lỗi trước khi log và loại display name, raw/hashed ID, avatar token/bytes, raw leaderboard ID khỏi log.
  - Trả avatar fallback theo từng hàng thay vì làm lỗi toàn bảng.

- [x] 3.4 Chạy lại test gateway/avatar tới trạng thái xanh
  - Reference: US-2 AC-1.2, US-2 AC-2.1, US-2 AC-2.2, US-2 AC-2.3, US-2 AC-2.4, US-2 AC-3.1, US-2 AC-3.2, US-2 AC-3.3, US-3 AC-1.4, US-3 AC-1.7, US-3 AC-1.8, US-3 AC-2.3, US-4 AC-1.4, US-4 AC-4.5
  - Command: `flutter test test/data/game_services_gateway_test.dart test/data/platform_avatar_test.dart`
  - Expected: PASS cho payload, timeout, fallback và mọi error mapping.

### 4. Repository đọc bảng, xác thực theo nhu cầu và cache offline

- [x] 4.1 Viết test đỏ cho mọi kết quả load và ranh giới xác thực/danh tính
  - Reference: US-2 AC-1.1, US-2 AC-1.2, US-2 AC-1.3, US-2 AC-2.1, US-2 AC-2.4, US-2 AC-3.1, US-2 AC-3.2, US-2 AC-3.3, US-2 AC-3.4, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-1.5, US-3 AC-1.6, US-3 AC-1.7, US-3 AC-1.8, US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-2.4, US-3 AC-3.1, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4
  - Files: `test/data/leaderboard_repository_test.dart`, `lib/data/leaderboard_repository.dart`
  - Bao phủ fresh/empty/friends-unavailable/auth-required/service-error; top 100 + current player loại trừ nhau; platform rank/tie giữ nguyên; cache đúng key; confidence `confirmedCurrent`, `lastKnownUnchanged`, `changed`, `unknown`; stale response bị bỏ theo request/identity epoch.
  - Expected: test thất bại vì repository và load result chưa tồn tại.

- [x] 4.2 Chạy test repository và xác nhận đúng trạng thái đỏ
  - Reference: US-2 AC-1.1, US-2 AC-1.3, US-2 AC-2.1, US-2 AC-2.4, US-2 AC-3.4, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-1.5, US-3 AC-1.6, US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-2.4, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4
  - Command: `flutter test test/data/leaderboard_repository_test.dart`
  - Expected: FAIL do thiếu repository behavior, không phải setup fake gateway/store.

- [x] 4.3 Cài đặt `LeaderboardRepository` và identity-confidence boundary
  - Reference: US-2 AC-1.1, US-2 AC-1.2, US-2 AC-1.3, US-2 AC-2.1, US-2 AC-2.4, US-2 AC-3.1, US-2 AC-3.2, US-2 AC-3.3, US-2 AC-3.4, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-1.5, US-3 AC-1.6, US-3 AC-1.7, US-3 AC-1.8, US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-2.4, US-3 AC-3.1, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4
  - Files: `lib/data/leaderboard_repository.dart`, `lib/domain/leaderboard_models.dart`
  - `restoreIdentity()` không present UI; `authenticateFromUserAction()` chỉ chạy sau hành động rõ ràng. Firebase sign-in/out/link/delete không thay platform identity.
  - Chỉ cache snapshot sau một read hoàn chỉnh; success online thay snapshot và bỏ stale warning; account changed/unknown ẩn cache cá nhân và trạng thái “của tôi”.

- [x] 4.4 Chạy lại test repository tới trạng thái xanh
  - Reference: US-2 AC-1.1, US-2 AC-1.2, US-2 AC-1.3, US-2 AC-2.1, US-2 AC-2.4, US-2 AC-3.1, US-2 AC-3.2, US-2 AC-3.3, US-2 AC-3.4, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-1.5, US-3 AC-1.6, US-3 AC-1.7, US-3 AC-1.8, US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-2.4, US-3 AC-3.1, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4
  - Command: `flutter test test/data/leaderboard_repository_test.dart`
  - Expected: PASS cho online, offline, auth và account-switch matrices.

### 5. Backfill, gửi kỷ lục và retry tuần tự

- [x] 5.1 Viết test đỏ cho backfill, enqueue, flush và manual retry
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.4, US-4 AC-2.1, US-4 AC-2.2, US-4 AC-2.3, US-4 AC-2.4, US-4 AC-3.1, US-4 AC-3.2, US-4 AC-3.3, US-4 AC-3.4, US-4 AC-3.5, US-4 AC-4.1, US-4 AC-4.2, US-4 AC-4.3, US-4 AC-4.4, US-4 AC-4.5, US-4 AC-5.1, US-4 AC-5.3
  - Files: `test/state/leaderboard_submission_controller_test.dart`, `test/data/leaderboard_submission_integration_test.dart`, `lib/state/leaderboard_controller.dart`, `lib/data/leaderboard_repository.dart`
  - Bao phủ backfill một lần/identity tối đa 20; bỏ màn chưa thắng/skipped/lost/zero; local-save-before-enqueue; higher-only; serialized flush; retryable giữ pending; permanent chuyển failed; manual retry; auth revoked giữ queue; trigger resume/open/win không nhân bản.
  - Expected: test thất bại vì submission controller chưa tồn tại.

- [x] 5.2 Chạy test submission và xác nhận đúng trạng thái đỏ
  - Reference: US-4 AC-2.1, US-4 AC-2.2, US-4 AC-2.3, US-4 AC-2.4, US-4 AC-3.1, US-4 AC-3.2, US-4 AC-3.3, US-4 AC-3.4, US-4 AC-3.5, US-4 AC-4.1, US-4 AC-4.2, US-4 AC-4.3, US-4 AC-4.4, US-4 AC-4.5
  - Command: `flutter test test/state/leaderboard_submission_controller_test.dart test/data/leaderboard_submission_integration_test.dart`
  - Expected: FAIL do thiếu enqueue/flush state machine, không phải lỗi fake clock/gateway.

- [x] 5.3 Cài đặt `LeaderboardSubmissionController` và orchestration trong repository
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.4, US-4 AC-2.1, US-4 AC-2.2, US-4 AC-2.3, US-4 AC-2.4, US-4 AC-3.1, US-4 AC-3.2, US-4 AC-3.3, US-4 AC-3.4, US-4 AC-3.5, US-4 AC-4.1, US-4 AC-4.2, US-4 AC-4.3, US-4 AC-4.4, US-4 AC-4.5, US-4 AC-5.1, US-4 AC-5.3
  - Files: `lib/state/leaderboard_controller.dart`, `lib/data/leaderboard_repository.dart`, `lib/domain/leaderboard_models.dart`
  - Bind validation/enqueue/flush vào current identity epoch; xóa pending chỉ sau platform acceptance; cập nhật UI status mà không sửa điểm/sao/xu; không present auth UI từ automatic retry.
  - Mọi đọc/gửi/retry chạy ngoài `Ticker`, painter và đường frame của `ShotRunner`.

- [x] 5.4 Chạy lại test submission/integration tới trạng thái xanh
  - Reference: US-4 AC-1.4, US-4 AC-2.1, US-4 AC-2.2, US-4 AC-2.3, US-4 AC-2.4, US-4 AC-3.1, US-4 AC-3.2, US-4 AC-3.3, US-4 AC-3.4, US-4 AC-3.5, US-4 AC-4.1, US-4 AC-4.2, US-4 AC-4.3, US-4 AC-4.4, US-4 AC-4.5, US-4 AC-5.1, US-4 AC-5.3
  - Command: `flutter test test/state/leaderboard_submission_controller_test.dart test/data/leaderboard_submission_integration_test.dart`
  - Expected: PASS, queue vẫn đúng sau simulated restart/account switch.

### 6. Lifecycle và provider wiring ngoài gameplay frame

- [x] 6.1 Viết test đỏ cho eager lifecycle, silent startup và identity epoch
  - Reference: US-1 AC-3.3, US-2 AC-1.1, US-2 AC-1.2, US-2 AC-1.3, US-2 AC-3.3, US-2 AC-3.4, US-4 AC-4.2, US-4 AC-4.3, US-4 AC-4.4, US-4 AC-5.1, US-4 AC-5.3
  - Files: `test/state/leaderboard_lifecycle_coordinator_test.dart`, `test/state/leaderboard_providers_test.dart`, `lib/state/leaderboard_lifecycle_coordinator.dart`, `lib/state/providers.dart`, `lib/main.dart`
  - Bao phủ coordinator được watch ở root trước khi mở route; startup chỉ restore silent; resume chỉ flush khi identity confidence cho phép; event account change tăng epoch và loại late reads/submits/avatars.
  - Expected: test thất bại vì lifecycle/provider wiring chưa tồn tại.

- [x] 6.2 Chạy test lifecycle và xác nhận đúng trạng thái đỏ
  - Reference: US-1 AC-3.3, US-2 AC-1.1, US-2 AC-1.2, US-2 AC-1.3, US-4 AC-4.2, US-4 AC-4.3, US-4 AC-4.4, US-4 AC-5.1
  - Command: `flutter test test/state/leaderboard_lifecycle_coordinator_test.dart test/state/leaderboard_providers_test.dart`
  - Expected: FAIL do thiếu eager observer và dependency graph, không phải provider override lỗi.

- [x] 6.3 Cài đặt coordinator và đăng ký toàn bộ providers ở app root
  - Reference: US-1 AC-3.3, US-2 AC-1.1, US-2 AC-1.2, US-2 AC-1.3, US-2 AC-3.3, US-2 AC-3.4, US-4 AC-4.2, US-4 AC-4.3, US-4 AC-4.4, US-4 AC-5.1, US-4 AC-5.3
  - Files: `lib/state/leaderboard_lifecycle_coordinator.dart`, `lib/state/providers.dart`, `lib/main.dart`
  - Dùng `WidgetsBindingObserver`, serialized async work và provider overrides cho fake gateway; không thay Firebase identity, local progress hoặc gameplay render state.
  - Unsupported/test host vẫn chơi được đầy đủ và không có login prompt.

- [x] 6.4 Chạy lại lifecycle/provider test và app smoke test tới trạng thái xanh
  - Reference: US-1 AC-3.3, US-2 AC-1.1, US-2 AC-1.2, US-2 AC-1.3, US-2 AC-3.3, US-2 AC-3.4, US-4 AC-4.2, US-4 AC-4.3, US-4 AC-4.4, US-4 AC-5.1, US-4 AC-5.3
  - Command: `flutter test test/state/leaderboard_lifecycle_coordinator_test.dart test/state/leaderboard_providers_test.dart test/app_smoke_test.dart`
  - Expected: PASS và app khởi động không chờ game-services auth.

### 7. Controller màn hình và tám trạng thái handoff

- [x] 7.1 Viết test đỏ cho scope, request epoch và toàn bộ view states
  - Reference: US-3 AC-1.1, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-1.5, US-3 AC-1.6, US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-2.4, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4
  - Files: `test/state/leaderboard_controller_test.dart`, `lib/state/leaderboard_controller.dart`
  - Bao phủ Global mặc định/lần sau nhớ scope; đổi scope tải đúng arena + all-time; loading không khóa ngữ cảnh; empty không tạo điểm 0; friends unavailable; retry; stale cache/no-cache; online success thay cache; late request không ghi đè scope mới.
  - Expected: test thất bại vì controller/view state chưa tồn tại.

- [x] 7.2 Chạy test controller và xác nhận đúng trạng thái đỏ
  - Reference: US-3 AC-1.1, US-3 AC-1.2, US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-2.4, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4
  - Command: `flutter test test/state/leaderboard_controller_test.dart`
  - Expected: FAIL do thiếu state transitions, không phải fake repository setup.

- [x] 7.3 Cài đặt `LeaderboardController` family theo arena + scope
  - Reference: US-3 AC-1.1, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-1.5, US-3 AC-1.6, US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-2.4, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4
  - Files: `lib/state/leaderboard_controller.dart`, `lib/state/providers.dart`
  - Mô hình hóa loaded/loading/empty/service error/offline cache/offline no-cache/friends unavailable/auth prompt và submission summary thành state tường minh.
  - Mở bảng là retry trigger phù hợp nhưng không tạo duplicate submission hay auth prompt ngoài user action.

- [x] 7.4 Chạy lại controller test tới trạng thái xanh
  - Reference: US-3 AC-1.1, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-1.5, US-3 AC-1.6, US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-2.4, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4
  - Command: `flutter test test/state/leaderboard_controller_test.dart`
  - Expected: PASS cho state matrix và request cancellation/ignore semantics.

### 8. Component và màn bảng xếp hạng karst

- [x] 8.1 Viết widget test đỏ cho loaded screen, hàng dữ liệu và accessibility
  - Reference: US-1 AC-3.1, US-1 AC-3.2, US-3 AC-1.3, US-3 AC-1.4, US-3 AC-1.5, US-3 AC-1.6, US-3 AC-1.7, US-3 AC-1.8, US-3 AC-4.1, US-3 AC-4.2, US-3 AC-4.3, US-3 AC-4.4
  - Files: `test/ui/leaderboard_screen_test.dart`, `lib/ui/screens/leaderboard_screen.dart`, `lib/ui/widgets/leaderboard_widgets.dart`, `test/support/pump_app.dart`
  - Bao phủ podium + tối đa 100 hàng; avatar fallback; current-player đúng một lần trong/ngoài top 100; platform rank/ties; Global/Friends selected semantics; fixed All-time; thứ tự đọc rank → name → score; VI/EN, safe area, 48dp, text scale và tablet max-width.
  - Expected: test thất bại vì screen/widgets chưa tồn tại.

- [x] 8.2 Chạy widget test loaded/accessibility và xác nhận đúng trạng thái đỏ
  - Reference: US-1 AC-3.1, US-1 AC-3.2, US-3 AC-1.4, US-3 AC-1.5, US-3 AC-1.6, US-3 AC-4.1, US-3 AC-4.2, US-3 AC-4.3, US-3 AC-4.4
  - Command: `flutter test test/ui/leaderboard_screen_test.dart`
  - Expected: FAIL do thiếu UI, không phải font/assets/provider fixtures.

- [x] 8.3 Cài đặt screen và component theo mockup karst đã duyệt
  - Reference: US-1 AC-3.1, US-1 AC-3.2, US-3 AC-1.3, US-3 AC-1.4, US-3 AC-1.5, US-3 AC-1.6, US-3 AC-1.7, US-3 AC-1.8, US-3 AC-4.1, US-3 AC-4.2, US-3 AC-4.3, US-3 AC-4.4
  - Files: `lib/ui/screens/leaderboard_screen.dart`, `lib/ui/widgets/leaderboard_widgets.dart`
  - Tái dùng `BbCanyonBackdrop`, `BbKarstFrameOverlay`, `BbButton`, `BbIconButton`, `BbCard`, `BbBadge`, `BbText`, token jade/teal/bronze/gold/cream và sticker shadow; không dùng galaxy/indigo/navy shell.
  - Tên dài wrap tối đa hai dòng; score tabular; list scroll trong route; trạng thái/current/filter luôn có icon, chữ, outline hoặc semantic cue ngoài màu.

- [x] 8.4 Chạy lại widget test loaded/accessibility tới trạng thái xanh
  - Reference: US-1 AC-3.1, US-1 AC-3.2, US-3 AC-1.3, US-3 AC-1.4, US-3 AC-1.5, US-3 AC-1.6, US-3 AC-1.7, US-3 AC-1.8, US-3 AC-4.1, US-3 AC-4.2, US-3 AC-4.3, US-3 AC-4.4
  - Command: `flutter test test/ui/leaderboard_screen_test.dart`
  - Expected: PASS ở 390×844, tablet width và text scale lớn, không overflow.

### 9. State UI, xác thực giải thích và trạng thái gửi

- [x] 9.1 Viết widget test đỏ cho bảy state delta còn lại và auth dialog
  - Reference: US-2 AC-2.1, US-2 AC-2.4, US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-2.4, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4, US-3 AC-4.2, US-4 AC-3.3, US-4 AC-3.5, US-4 AC-4.1, US-4 AC-4.4, US-4 AC-4.5
  - Files: `test/ui/leaderboard_states_test.dart`, `test/ui/leaderboard_auth_test.dart`, `lib/ui/screens/leaderboard_screen.dart`, `lib/ui/widgets/leaderboard_widgets.dart`
  - Bao phủ loading/empty/service error/offline cache + no-cache/friends unavailable/auth prompt/submission sent-pending-failed-unconnected; Back/filter vẫn dùng được; live announcements; cancel auth dùng matching cache hoặc pop về origin; manual retry chỉ cho permanent failure.
  - Expected: test thất bại vì state components/flows chưa được wire.

- [x] 9.2 Chạy state/auth widget test và xác nhận đúng trạng thái đỏ
  - Reference: US-2 AC-2.1, US-2 AC-2.4, US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-2.4, US-3 AC-3.2, US-3 AC-3.3, US-4 AC-4.1, US-4 AC-4.4, US-4 AC-4.5
  - Command: `flutter test test/ui/leaderboard_states_test.dart test/ui/leaderboard_auth_test.dart`
  - Expected: FAIL do thiếu visible state/interaction, không phải async settling lỗi.

- [x] 9.3 Cài đặt state regions, explanatory auth dialog và submission actions
  - Reference: US-2 AC-2.1, US-2 AC-2.4, US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-2.4, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4, US-3 AC-4.2, US-4 AC-3.3, US-4 AC-3.5, US-4 AC-4.1, US-4 AC-4.4, US-4 AC-4.5
  - Files: `lib/ui/screens/leaderboard_screen.dart`, `lib/ui/widgets/leaderboard_widgets.dart`
  - Dialog app-styled giải thích kết nối trước khi gọi platform UI; cancel/restricted/failure giữ progress và không tự re-prompt. Offline không nhận là online và không gửi trước reauth.
  - Lý do permanent failure lấy normalized localized code; retry thủ công không biến thành auto-retry loop.

- [x] 9.4 Chạy lại state/auth widget test tới trạng thái xanh
  - Reference: US-2 AC-2.1, US-2 AC-2.4, US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-2.4, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4, US-3 AC-4.2, US-4 AC-3.3, US-4 AC-3.5, US-4 AC-4.1, US-4 AC-4.4, US-4 AC-4.5
  - Command: `flutter test test/ui/leaderboard_states_test.dart test/ui/leaderboard_auth_test.dart`
  - Expected: PASS cho toàn bộ 8 handoff tabs ở UI Flutter.

### 10. Điểm vào từ Chọn màn và màn Thắng

- [x] 10.1 Viết widget test đỏ cho navigation, restoration và local-first result wiring
  - Reference: US-1 AC-1.1, US-1 AC-1.2, US-1 AC-1.3, US-1 AC-1.4, US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.3, US-1 AC-3.1, US-1 AC-3.3, US-4 AC-3.1, US-4 AC-3.2, US-4 AC-3.3, US-4 AC-3.5, US-4 AC-5.1
  - Files: `test/ui/leaderboard_entry_points_test.dart`, `test/ui/game_screen_leaderboard_test.dart`, `lib/ui/screens/arena_map_screen.dart`, `lib/ui/screens/game_screen.dart`
  - Bao phủ action chỉ ở selected unlocked arena; semantic label gồm arena; pop giữ chapter/selection/scroll; locked không đổi unlock; win result giữ Next/Map và achieved score/status; pop không ghi reward lần hai; không entry/network/auth khi aiming hoặc `_runner != null`.
  - Expected: test thất bại vì hai entry point và result epoch wiring chưa tồn tại.

- [x] 10.2 Chạy entry-point test và xác nhận đúng trạng thái đỏ
  - Reference: US-1 AC-1.1, US-1 AC-1.2, US-1 AC-1.3, US-1 AC-1.4, US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.3, US-1 AC-3.3, US-4 AC-3.1, US-4 AC-3.3, US-4 AC-5.1
  - Command: `flutter test test/ui/leaderboard_entry_points_test.dart test/ui/game_screen_leaderboard_test.dart`
  - Expected: FAIL do thiếu route/action/result integration, không phải navigation fixture.

- [x] 10.3 Wire `LeaderboardScreen` vào map và terminal win overlay
  - Reference: US-1 AC-1.1, US-1 AC-1.2, US-1 AC-1.3, US-1 AC-1.4, US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.3, US-1 AC-3.1, US-1 AC-3.3, US-4 AC-3.1, US-4 AC-3.2, US-4 AC-3.3, US-4 AC-3.5, US-4 AC-5.1
  - Files: `lib/ui/screens/arena_map_screen.dart`, `lib/ui/screens/game_screen.dart`, `lib/ui/screens/leaderboard_screen.dart`
  - Map dùng route push để stateful screen/`ScrollController` sống qua pop. Win await `RecordOutcome` đúng một lần mỗi terminal-result epoch, sau local save mới enqueue; leaderboard pop không chạy lại record/reward.
  - Giữ nguyên CTA Tiếp theo/Chọn màn và tuyệt đối không gọi leaderboard từ simulation/ticker callback.

- [x] 10.4 Chạy lại entry-point và gameplay regression test tới trạng thái xanh
  - Reference: US-1 AC-1.1, US-1 AC-1.2, US-1 AC-1.3, US-1 AC-1.4, US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.3, US-1 AC-3.1, US-1 AC-3.3, US-4 AC-3.1, US-4 AC-3.2, US-4 AC-3.3, US-4 AC-3.5, US-4 AC-5.1
  - Command: `flutter test test/ui/leaderboard_entry_points_test.dart test/ui/game_screen_leaderboard_test.dart test/ui/arena_map_screen_test.dart test/ui/game_screen_feedback_test.dart`
  - Expected: PASS, không duplicate progress/reward/submission sau rebuild hoặc pop.

### 11. Bản địa hóa và golden chống lệch style

- [x] 11.1 Viết test đỏ cho ARB parity, semantics và golden đại diện
  - Reference: US-1 AC-3.1, US-1 AC-3.2, US-2 AC-2.4, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-2.4, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-4.1, US-3 AC-4.2, US-3 AC-4.3, US-3 AC-4.4, US-4 AC-4.1, US-4 AC-4.5
  - Files: `test/l10n/arb_parity_test.dart`, `test/ui/leaderboard_golden_test.dart`, `test/ui/leaderboard_screen_test.dart`, `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`
  - Thêm expectations VI/EN cho entry, filter, all-time, loading/empty/error/offline/friends/auth/submission/reason codes và semantic announcements; golden 390×844 cho loaded/loading/offline/error/auth.
  - Expected: test thất bại vì keys/goldens mới chưa tồn tại.

- [x] 11.2 Chạy l10n/widget/golden test và xác nhận đúng trạng thái đỏ
  - Reference: US-1 AC-3.1, US-1 AC-3.2, US-3 AC-4.1, US-3 AC-4.2, US-3 AC-4.3, US-3 AC-4.4
  - Command: `flutter gen-l10n && flutter test test/l10n/arb_parity_test.dart test/ui/leaderboard_screen_test.dart test/ui/leaderboard_golden_test.dart`
  - Expected: FAIL vì missing strings/goldens hoặc UI chưa khớp karst target, không phải lỗi font loading.

- [x] 11.3 Hoàn thiện copy VI/EN, semantics/live regions và golden baselines karst
  - Reference: US-1 AC-3.1, US-1 AC-3.2, US-2 AC-2.4, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-2.4, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-4.1, US-3 AC-4.2, US-3 AC-4.3, US-3 AC-4.4, US-4 AC-4.1, US-4 AC-4.5
  - Files: `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`, generated l10n outputs, `lib/ui/screens/leaderboard_screen.dart`, `lib/ui/widgets/leaderboard_widgets.dart`, `test/ui/goldens/leaderboard_*.png`
  - Đối chiếu `mockup.html`, `leaderboard-reference-v2.png` và `test/ui/goldens/arena_map_390x844.png`; không thêm Ngày/Tuần/campaign board, card trắng hoặc galaxy/navy shell.
  - Thêm semantics rank → platform name → score và live announcements cho load/scope/error/offline.

- [x] 11.4 Chạy lại l10n/widget/golden test tới trạng thái xanh
  - Reference: US-1 AC-3.1, US-1 AC-3.2, US-2 AC-2.4, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-2.4, US-3 AC-3.2, US-3 AC-3.3, US-3 AC-4.1, US-3 AC-4.2, US-3 AC-4.3, US-3 AC-4.4, US-4 AC-4.1, US-4 AC-4.5
  - Command: `flutter gen-l10n && flutter test test/l10n/arb_parity_test.dart test/ui/leaderboard_screen_test.dart test/ui/leaderboard_states_test.dart test/ui/leaderboard_golden_test.dart`
  - Expected: PASS ở VI/EN, large text và các golden đại diện.

### 12. Native Android Play Games Services v2

- [x] 12.1 Viết test đỏ cho catalog 20 bảng, paging top 100 và bridge Android
  - Reference: US-2 AC-1.2, US-2 AC-2.1, US-2 AC-2.3, US-2 AC-2.4, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-1.4, US-3 AC-1.6, US-3 AC-1.7, US-3 AC-1.8, US-3 AC-2.3, US-4 AC-1.4, US-4 AC-4.5
  - Files: `android/app/src/test/kotlin/com/example/ban_bua_tuong/GameServicesBridgeTest.kt`, `android/app/src/main/res/values/leaderboards.xml`, `android/app/src/main/kotlin/com/example/ban_bua_tuong/GameServicesBridge.kt`
  - Bao phủ đúng 20 ID duy nhất/non-placeholder; app/application ID match; silent startup không profile prompt; interactive auth; four-page `loadTopScores`/`loadMoreScores` ≤25, dedupe player ID, release buffers, current-player lookup; friends resolution; submit/error/avatar mapping và limit parity.
  - Expected: native test thất bại vì dependency/catalog/bridge chưa tồn tại.

- [x] 12.2 Chạy Android native test và xác nhận đúng trạng thái đỏ
  - Reference: US-2 AC-1.2, US-2 AC-2.3, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-1.6, US-3 AC-2.3, US-4 AC-1.4
  - Command: `cd android; .\gradlew.bat :app:testDebugUnitTest`
  - Expected: FAIL vì PGS v2 bridge/catalog chưa được cài đặt, không phải Gradle syntax.

- [x] 12.3 Cài đặt PGS v2 dependency, resources, manifest và Kotlin bridge
  - Reference: US-2 AC-1.2, US-2 AC-2.1, US-2 AC-2.3, US-2 AC-2.4, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-1.4, US-3 AC-1.6, US-3 AC-1.7, US-3 AC-1.8, US-3 AC-2.3, US-4 AC-1.4, US-4 AC-4.5
  - Files: `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/res/values/leaderboards.xml`, `android/app/src/main/kotlin/com/example/ban_bua_tuong/MainActivity.kt`, `android/app/src/main/kotlin/com/example/ban_bua_tuong/GameServicesBridge.kt`
  - Tắt automatic profile-creation prompt; register channel; map arena 1..20 qua resource; release mọi score buffer; tải avatar có timeout/byte cap; không mở native leaderboard UI.
  - 20 ID thật là release input: test cấu hình phải fail rõ nếu thiếu, trùng hoặc còn placeholder thay vì đoán ID.

- [x] 12.4 Chạy lại Android unit test và Dart channel contract tới trạng thái xanh
  - Reference: US-2 AC-1.2, US-2 AC-2.1, US-2 AC-2.3, US-2 AC-2.4, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-1.4, US-3 AC-1.6, US-3 AC-1.7, US-3 AC-1.8, US-3 AC-2.3, US-4 AC-1.4, US-4 AC-4.5
  - Command: `cd android; .\gradlew.bat :app:testDebugUnitTest`; then `flutter test test/data/game_services_gateway_test.dart`
  - Expected: PASS khi catalog test dùng fixture hợp lệ; production/release validation vẫn chặn placeholder.

### 13. Native iOS GameKit

- [x] 13.1 Viết test đỏ cho catalog, auth presentation và bridge GameKit
  - Reference: US-2 AC-1.2, US-2 AC-2.1, US-2 AC-2.2, US-2 AC-2.4, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-1.4, US-3 AC-1.6, US-3 AC-1.7, US-3 AC-1.8, US-3 AC-2.3, US-4 AC-1.4, US-4 AC-4.5
  - Files: `ios/RunnerTests/GameServicesBridgeTests.swift`, `ios/Runner/LeaderboardCatalog.plist`, `ios/Runner/GameServicesBridge.swift`
  - Bao phủ đúng 20 ID duy nhất/non-placeholder; silent auth không present view controller; interactive auth sau user action; global/friends all-time top range + local-player lookup; rank/ties; avatar byte cap; cancel/restricted/consent/retryable/permanent mapping và limit parity.
  - Expected: XCTest thất bại vì capability/catalog/bridge chưa tồn tại.

- [ ] 13.2 Chạy iOS native test trên macOS và xác nhận đúng trạng thái đỏ
  - Reference: US-2 AC-1.2, US-2 AC-2.2, US-2 AC-2.4, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-2.3, US-4 AC-1.4
  - Command: `xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 16'`
  - Expected: FAIL vì GameKit bridge/catalog/capability chưa được cài đặt, không phải project reference lỗi.

- [x] 13.3 Cài đặt Game Center capability, catalog, localized consent và Swift bridge
  - Reference: US-2 AC-1.2, US-2 AC-2.1, US-2 AC-2.2, US-2 AC-2.4, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-1.4, US-3 AC-1.6, US-3 AC-1.7, US-3 AC-1.8, US-3 AC-2.3, US-4 AC-1.4, US-4 AC-4.5
  - Files: `ios/Runner/AppDelegate.swift`, `ios/Runner/GameServicesBridge.swift`, `ios/Runner/LeaderboardCatalog.plist`, `ios/Runner/Info.plist`, `ios/Runner/en.lproj/InfoPlist.strings`, `ios/Runner/vi.lproj/InfoPlist.strings`, `ios/Runner/Runner.entitlements`, `ios/Runner.xcodeproj/project.pbxproj`
  - Register channel với implicit engine; map arena 1..20 qua plist; chỉ present auth controller sau explicit Flutter action; dùng `NSGKFriendListUsageDescription`; trả bounded `UIImage` bytes; không mở native leaderboard UI.
  - 20 ID thật là release input và validation phải chặn thiếu/trùng/placeholder.

- [ ] 13.4 Chạy lại iOS XCTest và Dart channel contract tới trạng thái xanh
  - Reference: US-2 AC-1.2, US-2 AC-2.1, US-2 AC-2.2, US-2 AC-2.4, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-1.4, US-3 AC-1.6, US-3 AC-1.7, US-3 AC-1.8, US-3 AC-2.3, US-4 AC-1.4, US-4 AC-4.5
  - Command: `xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,name=iPhone 16'`; then `flutter test test/data/game_services_gateway_test.dart`
  - Expected: PASS khi catalog fixture hợp lệ; release validation vẫn chặn placeholder.

### 14. Kiểm chứng tích hợp và regression cuối

- [x] 14.1 Viết integration test đỏ cho luồng end-to-end bằng fake gateway
  - Reference: US-1 AC-1.1, US-1 AC-1.2, US-1 AC-1.3, US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.3, US-2 AC-1.1, US-2 AC-1.3, US-2 AC-2.1, US-2 AC-2.4, US-2 AC-3.4, US-3 AC-1.1, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-1.4, US-3 AC-1.5, US-3 AC-1.6, US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-2.4, US-3 AC-3.2, US-3 AC-3.3, US-4 AC-2.1, US-4 AC-2.4, US-4 AC-3.1, US-4 AC-3.4, US-4 AC-3.5, US-4 AC-4.1, US-4 AC-4.2, US-4 AC-4.3, US-4 AC-4.4, US-4 AC-4.5
  - Files: `integration_test/leaderboard_flow_test.dart`, `test/support/fake_game_services_gateway.dart`
  - Bao phủ map → auth → loaded → scope switch → offline cache → retry; win local save → enqueue → accepted; restart với pending; permanent fail/manual retry; auth revoke; platform account switch không lộ/gửi partition cũ.
  - Expected: test thất bại cho tới khi toàn bộ seams đã được wire.

- [x] 14.2 Chạy integration test bằng fake gateway và sửa chỉ lỗi wiring có test
  - Reference: US-1 AC-1.1, US-1 AC-1.2, US-1 AC-1.3, US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.3, US-2 AC-1.1, US-2 AC-1.3, US-2 AC-2.1, US-2 AC-2.4, US-2 AC-3.4, US-3 AC-1.1, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-1.4, US-3 AC-1.5, US-3 AC-1.6, US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-2.4, US-3 AC-3.2, US-3 AC-3.3, US-4 AC-2.1, US-4 AC-2.4, US-4 AC-3.1, US-4 AC-3.4, US-4 AC-3.5, US-4 AC-4.1, US-4 AC-4.2, US-4 AC-4.3, US-4 AC-4.4, US-4 AC-4.5
  - Command: `flutter test integration_test/leaderboard_flow_test.dart`
  - Expected: PASS sau khi nối provider, route, local store và gateway fake; không mở platform UI thật.

- [x] 14.3 Bổ sung boundary/regression assertions cho phạm vi không được thay đổi
  - Reference: US-1 AC-1.4, US-1 AC-2.3, US-1 AC-3.3, US-2 AC-3.3, US-4 AC-3.5, US-4 AC-5.1, US-4 AC-5.2, US-4 AC-5.3, US-4 AC-5.4
  - Files: `test/boundary_test.dart`, `test/state/progress_controller_test.dart`, `test/ui/game_screen_leaderboard_test.dart`, `test/data/leaderboard_repository_test.dart`
  - Assert `lib/sim/` vẫn không import Flutter/network; gameplay frame không gọi read/submit/retry; pop leaderboard không ghi reward; Firebase lifecycle không đổi platform identity; clear app namespace loại cache/queue; accepted platform score không sửa local progress.
  - Không chạy solver vì không được sửa campaign/hằng số; nếu diff chạm `lib/sim/`, `tools/solver/` hoặc `lib/sim/arenas.dart` thì dừng và loại thay đổi đó.

- [x] 14.4 Chạy toàn bộ gate Flutter và kiểm tra static cuối
  - Reference: US-1 AC-3.1, US-1 AC-3.2, US-1 AC-3.3, US-2 AC-1.1, US-2 AC-1.2, US-2 AC-1.3, US-2 AC-3.3, US-2 AC-3.4, US-3 AC-4.1, US-3 AC-4.2, US-3 AC-4.3, US-3 AC-4.4, US-4 AC-5.1, US-4 AC-5.2, US-4 AC-5.3, US-4 AC-5.4
  - Command: `flutter gen-l10n && flutter analyze && flutter test`
  - Expected: toàn bộ test PASS, analyze không lỗi; diff không chạm luật/campaign/generated arenas và không đưa galaxy/navy trở lại shell.

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
