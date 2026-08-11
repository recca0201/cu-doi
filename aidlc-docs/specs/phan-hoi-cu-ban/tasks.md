---
artifact_type: tasks
phase: construction
status: draft
created: 2026-08-05
updated: 2026-08-09
unit: phan-hoi-cu-ban
source_artifacts:
  - aidlc-docs/specs/phan-hoi-cu-ban/requirements.md
  - aidlc-docs/specs/phan-hoi-cu-ban/design.md
---

# Tasks: Phản hồi cú bắn

Thứ tự: hằng số và hai service thuần Dart trước (test được không cần thiết bị), rồi tầng vẽ,
rồi nối vào `_drain`, cuối cùng là Cài đặt và kiểm toàn bộ. Mọi lệnh kiểm chạy trên host.

**Phụ thuộc Unit 1**: task 13 (z-order + golden) giả định đường gợi ý của Unit 1 đã có khe
`vệt ma → [GỢI Ý] → [HIỆU ỨNG] → vệt bay`. Nếu Unit 1 chưa làm, bỏ phần gợi ý khỏi golden và
khe hiệu ứng nằm ngay sau vệt ma — thứ tự tương đối giữa hiệu ứng và vệt bay không đổi.

## Implementation Checklist

### 1. Hằng số và bậc cường độ

- [x] 1.1 Write the failing test
  - Reference: US-1 AC-1.5, US-3 AC-3.5
  - Files: `test/ui/comic_effect_tier_test.dart`
  - Add coverage cho bảng bậc: miền `0..kMaxBanks`, đơn điệu tăng, bậc chết dùng lại bậc đỉnh.
  - Test file: `test/ui/comic_effect_tier_test.dart`
  - Expected assertion: `level 0` không có bậc; `level 1..4` tăng đơn điệu ở **cả bốn** tham số; bước `3→4` lớn hơn bước `2→3` ở cả bốn; `tierFor(5) == tierFor(4)`; `kMaxEffectElements == 24`
- [x] 1.2 Run test to verify it fails
  - Reference: US-1 AC-1.5, US-3 AC-3.5
  - Command: `flutter test test/ui/comic_effect_tier_test.dart`
  - Expected: FAIL vì `lib/ui/comic_effect_controller.dart` chưa tồn tại.
- [x] 1.3 Write minimal implementation
  - Reference: US-1 AC-1.5, US-3 AC-3.5
  - Implementation file: `lib/ui/comic_effect_controller.dart`
  - Khai `EffectTier` (`level`, `duration`, `spokeCount`, `spokeLength`, `spokeWidth`), bảng 6 bậc theo § `comic_effect_controller`, `kMaxEffectElements`. Ngưỡng bậc đỉnh đọc `kMaxBanks - 1`, **không** viết cứng 4.
- [x] 1.4 Run test to verify it passes
  - Reference: US-1 AC-1.5, US-3 AC-3.5
  - Command: `flutter test test/ui/comic_effect_tier_test.dart`
  - Expected: PASS.

### 2. Chọn bậc theo loại sự kiện

- [x] 2.1 Write the failing test
  - Reference: US-1 AC-1.1, US-1 AC-2.1, US-1 AC-2.2, US-2 AC-1.1
  - Files: `test/ui/comic_effect_controller_test.dart`
  - Add coverage cho `onEvent` chọn bậc: `bank` theo số dội, `broke` theo hệ số, `blocked` theo `banksAtEvent`.
  - Test file: `test/ui/comic_effect_controller_test.dart`
  - Expected assertion: `bank` với `banksAtEvent: 3` ⇒ bậc 3; `broke` với `banksAtEvent: 3` ⇒ bậc theo hệ số `min(1+3, kMaxMultiplier) == 4`; `blocked` với `banksAtEvent: 2` ⇒ bậc 2 **không** bậc 0 (dù `e.bankCount` là 0); `bank` với `banksAtEvent: 0` ⇒ không sinh phần tử
- [x] 2.2 Run test to verify it fails
  - Reference: US-1 AC-1.1, US-1 AC-2.1, US-1 AC-2.2, US-2 AC-1.1
  - Command: `flutter test test/ui/comic_effect_controller_test.dart`
  - Expected: FAIL vì `onEvent` chưa có.
- [x] 2.3 Write minimal implementation
  - Reference: US-1 AC-1.1, US-1 AC-2.1, US-1 AC-2.2, US-2 AC-1.1
  - Implementation file: `lib/ui/comic_effect_controller.dart`
  - `onEvent(ShotEvent e, {required int banksAtEvent})`. `banksAtEvent` là nguồn có thẩm quyền cho cả ba loại — **không** đọc `e.bankCount` cho `blocked` vì `shot_runner.dart:210` không truyền nó.
- [x] 2.4 Run test to verify it passes
  - Reference: US-1 AC-1.1, US-1 AC-2.1, US-1 AC-2.2, US-2 AC-1.1
  - Command: `flutter test test/ui/comic_effect_controller_test.dart`
  - Expected: PASS.
- [x] 2.5 Chốt bi dội mục tiêu không tính công dội
  - Reference: US-1 AC-2.1
  - Files: `test/ui/comic_effect_controller_test.dart`
  - Thêm test: một chuỗi sự kiện có `blocked` xen giữa hai `bank` **không** làm bậc leo thêm — dội mục tiêu không phải công dội (PDR §8.4).

### 3. Vòng đời phần tử và trần

- [x] 3.1 Write the failing test
  - Reference: US-2 AC-1.2, US-3 AC-3.5
  - Files: `test/ui/comic_effect_controller_test.dart`
  - Add coverage cho `tick` già hoá, loại phần tử hết tuổi, và trần phần tử.
  - Test file: `test/ui/comic_effect_controller_test.dart`
  - Expected assertion: sau `tick(duration + ε)` phần tử bị loại; nhiều `broke` liên tiếp **cộng dồn** không xoá nhau (AC US-2/1.2); sinh 30 phần tử ⇒ `elements.length == 24` và phần tử **cũ nhất** bị loại
- [x] 3.2 Run test to verify it fails
  - Reference: US-2 AC-1.2, US-3 AC-3.5
  - Command: `flutter test test/ui/comic_effect_controller_test.dart`
  - Expected: FAIL vì `tick` và trần chưa có.
- [x] 3.3 Write minimal implementation
  - Reference: US-2 AC-1.2, US-3 AC-3.5
  - Implementation file: `lib/ui/comic_effect_controller.dart`
  - `tick(double dt)` cộng `age`, loại phần tử `age > tier.duration`; vượt trần thì loại cũ nhất.
- [x] 3.4 Run test to verify it passes
  - Reference: US-2 AC-1.2, US-3 AC-3.5
  - Command: `flutter test test/ui/comic_effect_controller_test.dart`
  - Expected: PASS.

### 4. `endShot` phân biệt kiểu chết

- [x] 4.1 Write the failing test
  - Reference: US-1 AC-2.3, US-2 AC-1.3
  - Files: `test/ui/comic_effect_controller_test.dart`
  - Add coverage cho `endShot(ShotEndReason)`.
  - Test file: `test/ui/comic_effect_controller_test.dart`
  - Expected assertion: `endShot(exitedBottom)` ⇒ `elements` rỗng; `endShot(banksExhausted)` và `endShot(timeout)` ⇒ phần tử đang sống **vẫn còn** để chạy hết tuổi
- [x] 4.2 Run test to verify it fails
  - Reference: US-1 AC-2.3, US-2 AC-1.3
  - Command: `flutter test test/ui/comic_effect_controller_test.dart`
  - Expected: FAIL vì `endShot` chưa nhận tham số.
- [x] 4.3 Write minimal implementation
  - Reference: US-1 AC-2.3, US-2 AC-1.3
  - Implementation file: `lib/ui/comic_effect_controller.dart`
  - `endShot(ShotEndReason reason)` theo bảng ở § `game_screen`. Thêm `clear()` và `isNotEmpty`.
- [x] 4.4 Run test to verify it passes
  - Reference: US-1 AC-2.3, US-2 AC-1.3
  - Command: `flutter test test/ui/comic_effect_controller_test.dart`
  - Expected: PASS.

### 5. Bốn pattern rung

- [x] 5.1 Write the failing test
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-1.4
  - Files: `test/core/haptic_service_test.dart`
  - Add coverage cho bốn `HapticEvent` map sang bốn pattern **khác nhau**.
  - Test file: `test/core/haptic_service_test.dart`
  - Expected assertion: bốn lần `fire` với bốn event khác nhau ⇒ bốn method channel call **khác nhau** (bắt qua `TestDefaultBinaryMessengerBinding` mock của `SystemChannels.platform`)
- [x] 5.2 Run test to verify it fails
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-1.4
  - Command: `flutter test test/core/haptic_service_test.dart`
  - Expected: FAIL vì `lib/core/haptic_service.dart` chưa tồn tại.
- [x] 5.3 Write minimal implementation
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-1.4
  - Implementation file: `lib/core/haptic_service.dart`
  - `HapticEvent`, `HapticService({required bool enabled, DateTime Function()? now})`, `fire`. Map: `bank`→`selectionClick`, `blockedShot`→`mediumImpact`, `targetBroken`→`heavyImpact`, `levelEnd`→`vibrate`.
- [x] 5.4 Run test to verify it passes
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-1.4
  - Command: `flutter test test/core/haptic_service_test.dart`
  - Expected: PASS.

### 6. Cooldown hai tầng

- [x] 6.1 Write the failing test
  - Reference: US-4 AC-2.1, US-4 AC-2.2, US-4 AC-2.3
  - Files: `test/core/haptic_service_test.dart`
  - Add coverage cho bucket: ba sự kiện gameplay chia **một** cửa sổ; `levelEnd` miễn cooldown.
  - Test file: `test/core/haptic_service_test.dart`
  - Expected assertion: `bank` rồi `targetBroken` cách 20ms ⇒ chỉ **một** lần rung (chia bucket); cách 70ms ⇒ hai lần; **`targetBroken` rồi `levelEnd` cách 16ms ⇒ HAI lần rung** — đây là test bắt được lỗi cooldown chung; `now` tiêm được nên không cần thiết bị
- [x] 6.2 Run test to verify it fails
  - Reference: US-4 AC-2.1, US-4 AC-2.2, US-4 AC-2.3
  - Command: `flutter test test/core/haptic_service_test.dart`
  - Expected: FAIL — đặc biệt ở assertion `levelEnd`, vốn là ca dễ cài sai nhất.
- [x] 6.3 Write minimal implementation
  - Reference: US-4 AC-2.1, US-4 AC-2.2, US-4 AC-2.3
  - Implementation file: `lib/core/haptic_service.dart`
  - `static const Map<HapticEvent, int> _bucket`, `static const Map<int, Duration> _cooldown`, `Map<int, DateTime> _lastFired` khoá **theo bucket**. **Không** dùng `Map<HapticEvent, Duration>` như audio — đó là cooldown per-key và sẽ cho mỗi sự kiện một timer riêng.
- [x] 6.4 Run test to verify it passes
  - Reference: US-4 AC-2.1, US-4 AC-2.2, US-4 AC-2.3
  - Command: `flutter test test/core/haptic_service_test.dart`
  - Expected: PASS.

### 7. Rung tắt và lỗi platform

- [x] 7.1 Write the failing test
  - Reference: US-4 AC-3.1, US-4 AC-3.2
  - Files: `test/core/haptic_service_test.dart`
  - Add coverage cho `enabled == false` và cho platform channel throw.
  - Test file: `test/core/haptic_service_test.dart`
  - Expected assertion: `enabled == false` ⇒ **không** có channel call nào; mock channel throw ⇒ `fire` không throw **và không** để lại unhandled async error (test fail nếu có)
- [x] 7.2 Run test to verify it fails
  - Reference: US-4 AC-3.1, US-4 AC-3.2
  - Command: `flutter test test/core/haptic_service_test.dart`
  - Expected: FAIL ở assertion async error — `try`/`catch` đồng bộ không bắt được Future bị reject.
- [x] 7.3 Write minimal implementation
  - Reference: US-4 AC-3.1, US-4 AC-3.2
  - Implementation file: `lib/core/haptic_service.dart`
  - `unawaited(HapticFeedback.x().catchError((_) {}))`. `setEnabled` trả sớm khi tắt.
- [x] 7.4 Run test to verify it passes
  - Reference: US-4 AC-3.1, US-4 AC-3.2
  - Command: `flutter test test/core/haptic_service_test.dart`
  - Expected: PASS.

### 8. `hapticsOn` trong cài đặt

- [x] 8.1 Write the failing test
  - Reference: US-5 AC-1.2, US-5 AC-1.5, US-5 AC-2.1
  - Files: `test/data/settings_repository_test.dart`
  - Add coverage cho `hapticsOn` mặc định bật và tương thích ngược save cũ.
  - Test file: `test/data/settings_repository_test.dart`
  - Expected assertion: prefs **không có** khoá `hapticsOn` ⇒ `hapticsOn == true`; `copyWith` giữ nguyên ba field kia; save rồi load round-trip đúng
- [x] 8.2 Run test to verify it fails
  - Reference: US-5 AC-1.2, US-5 AC-1.5, US-5 AC-2.1
  - Command: `flutter test test/data/settings_repository_test.dart`
  - Expected: FAIL vì `AppSettings` chưa có `hapticsOn`.
- [x] 8.3 Write minimal implementation
  - Reference: US-5 AC-1.2, US-5 AC-1.5, US-5 AC-2.1
  - Implementation file: `lib/data/settings_repository.dart`
  - Thêm `hapticsOn` vào `AppSettings` + `copyWith`; `load()` đọc `getBool('hapticsOn') ?? true`; **và thêm nó vào `save()`** — bỏ sót đường ghi là cách AC US-5/1.3 im lặng thất bại.
- [x] 8.4 Run test to verify it passes
  - Reference: US-5 AC-1.2, US-5 AC-1.5, US-5 AC-2.1
  - Command: `flutter test test/data/settings_repository_test.dart`
  - Expected: PASS.

### 9. Công tắc rung trên màn Cài đặt

- [x] 9.1 Write the failing test
  - Reference: US-5 AC-1.1, US-5 AC-1.3, US-5 AC-1.4, US-5 AC-2.2, US-5 AC-2.3
  - Files: `test/ui/settings_haptics_test.dart`
  - Add coverage cho hàng công tắc rung.
  - Test file: `test/ui/settings_haptics_test.dart`
  - Expected assertion: công tắc nằm sau Nhạc nền và trước Ngôn ngữ trong cùng
    panel karst jade/teal hiện hành; lật ⇒ áp ngay và lưu; mở lại ⇒ khôi phục;
    `Semantics.toggled` đúng; vùng chạm ≥48dp; state không chỉ dựa vào màu.
- [x] 9.2 Run test to verify it fails
  - Reference: US-5 AC-1.1, US-5 AC-1.3, US-5 AC-1.4, US-5 AC-2.2, US-5 AC-2.3
  - Command: `flutter test test/ui/settings_haptics_test.dart`
  - Expected: FAIL vì công tắc chưa có.
- [x] 9.3 Write minimal implementation
  - Reference: US-5 AC-1.1, US-5 AC-1.3, US-5 AC-1.4, US-5 AC-2.2, US-5 AC-2.3
  - Implementation file: `lib/ui/screens/settings_screen.dart`, `lib/state/providers.dart`
  - `BbToggle` theo đúng khuôn hai hàng đang có, ngăn bởi `Divider(height: sp6)`; thêm `SettingsController.setHaptics`. Dùng **một** khoá `hapticsLabel` cho cả nhãn và `semanticLabel`, đúng như `settings_screen.dart:59-61` đang làm.
- [x] 9.4 Run test to verify it passes
  - Reference: US-5 AC-1.1, US-5 AC-1.3, US-5 AC-1.4, US-5 AC-2.2, US-5 AC-2.3
  - Command: `flutter test test/ui/settings_haptics_test.dart`
  - Expected: PASS.

### 10. Provider rung

- [x] 10.1 Write the failing test
  - Reference: US-5 AC-1.3, US-4 AC-3.2
  - Files: `test/state/haptic_provider_test.dart`
  - Add coverage cho việc lật công tắc đồng bộ tới service **không** dựng lại nó.
  - Test file: `test/state/haptic_provider_test.dart`
  - Expected assertion: lật `hapticsOn` ⇒ **cùng một** instance `HapticService` nhận `setEnabled`, không phải instance mới
- [x] 10.2 Run test to verify it fails
  - Reference: US-5 AC-1.3, US-4 AC-3.2
  - Command: `flutter test test/state/haptic_provider_test.dart`
  - Expected: FAIL vì `hapticServiceProvider` chưa tồn tại.
- [x] 10.3 Write minimal implementation
  - Reference: US-5 AC-1.3, US-4 AC-3.2
  - Implementation file: `lib/state/providers.dart`
  - `ref.read` + `ref.listen` theo đúng khuôn `gameAudioProvider` (`providers.dart:83-96`).
- [x] 10.4 Run test to verify it passes
  - Reference: US-5 AC-1.3, US-4 AC-3.2
  - Command: `flutter test test/state/haptic_provider_test.dart`
  - Expected: PASS.

### 11. Chỉ số hệ số BỪA rõ dần

- [x] 11.1 Write the failing test
  - Reference: US-1 AC-1.2, US-2 AC-2.2
  - Files: `test/ui/multiplier_scale_test.dart`
  - Add coverage cho capsule `×1…×6`, việc số to/đậm dần theo bank và tương phản target.
  - Test file: `test/ui/multiplier_scale_test.dart`
  - Expected assertion: `banks == 0` vẫn hiện capsule `×1` nhưng không punch; cỡ
    chữ ở `banks == 4` lớn hơn `banks == 1`; gold trên panel navy đạt ≥3:1.
- [x] 11.2 Run test to verify it fails
  - Reference: US-1 AC-1.2, US-2 AC-2.2
  - Command: `flutter test test/ui/multiplier_scale_test.dart`
  - Expected: FAIL vì `_paintMultiplier` còn cố định `fit.u(11)`.
- [x] 11.3 Write minimal implementation
  - Reference: US-1 AC-1.2, US-2 AC-2.2
  - Implementation file: `lib/ui/arena_painter.dart`
  - `_paintMultiplier` nhận `banks`, dựng capsule dọc `panelNavy` +
    `primaryGold`, hiện `×1…×6` và punch 120–200ms khi tăng. Giữ nó trên effect và
    ngoài vùng che target; đây là đường code riêng, không đi qua `EffectTier`.
- [x] 11.4 Run test to verify it passes
  - Reference: US-1 AC-1.2, US-2 AC-2.2
  - Command: `flutter test test/ui/multiplier_scale_test.dart`
  - Expected: PASS.
- [x] 11.5 Đo và ghi tương phản
  - Reference: US-2 AC-2.2
  - Files: `aidlc-docs/specs/phan-hoi-cu-ban/design.md`
  - Đo `primaryGold` trên capsule `panelNavy` ở state default/pressed/reduced
    motion, ghi số vào § Điều kiện chưa kiểm; mọi state thông tin đạt ≥3:1.

### 12. Vẽ chùm vạch va đập

- [x] 12.1 Write the failing test
  - Reference: US-1 AC-1.4, US-3 AC-1.2
  - Files: `test/ui/arena_painter_effects_test.dart`
  - Add coverage golden cho tầng hiệu ứng vẽ đúng và **không** đổi gì khi rỗng.
  - Test file: `test/ui/arena_painter_effects_test.dart`
  - Expected assertion: `effects` rỗng ⇒ golden byte-identical với ảnh không có
    field này; `effects` non-rỗng ⇒ vạch toả `trajectoryCyan` xuất hiện đúng điểm
    va chạm và không che target/armed.
- [x] 12.2 Run test to verify it fails
  - Reference: US-1 AC-1.4, US-3 AC-1.2
  - Command: `flutter test test/ui/arena_painter_effects_test.dart`
  - Expected: FAIL vì `ArenaPainter` chưa có field `effects`.
- [x] 12.3 Write minimal implementation
  - Reference: US-1 AC-1.4, US-3 AC-1.2
  - Implementation file: `lib/ui/arena_painter.dart`
  - Thêm `final List<EffectElement> effects` **mặc định `const []`** để golden test của Unit 1 không phải sửa. Vẽ vạch thẳng toả, mờ dần theo `age / duration`.
- [x] 12.4 Run test to verify it passes
  - Reference: US-1 AC-1.4, US-3 AC-1.2
  - Command: `flutter test test/ui/arena_painter_effects_test.dart`
  - Expected: PASS.

### 13. Bảo vệ tín hiệu `armed`

- [x] 13.1 Write the failing test
  - Reference: US-3 AC-1.1, US-3 AC-1.3, US-3 AC-1.4
  - Files: `test/ui/arena_painter_effects_test.dart`
  - Add coverage cho z-order **và** cho tính đọc được của quầng `armed` khi hiệu ứng chồng lên.
  - Test file: `test/ui/arena_painter_effects_test.dart`
  - Expected assertion: hiệu ứng vẽ **dưới** lớp mục tiêu và **dưới** vệt bay; golden có một case **cố ý** đặt hiệu ứng chồng vùng `r × 1.55` của mục tiêu `armed` ⇒ quầng vẫn đọc được; `onEvent` **không** sinh phần tử có tâm trong vùng đó
- [x] 13.2 Run test to verify it fails
  - Reference: US-3 AC-1.1, US-3 AC-1.3, US-3 AC-1.4
  - Command: `flutter test test/ui/arena_painter_effects_test.dart`
  - Expected: FAIL vì ràng buộc vùng loại trừ chưa có.
- [x] 13.3 Write minimal implementation
  - Reference: US-3 AC-1.1, US-3 AC-1.3, US-3 AC-1.4
  - Implementation file: `lib/ui/comic_effect_controller.dart`, `lib/ui/arena_painter.dart`
  - `onEvent` bỏ qua phần tử có tâm trong `r × 1.55` của mục tiêu còn sống; đoạn vạch cắt qua vùng đó hạ alpha dưới `0x28`. Chèn draw call vào khe `vệt ma → [gợi ý] → [hiệu ứng] → vệt bay`.
- [x] 13.4 Run test to verify it passes
  - Reference: US-3 AC-1.1, US-3 AC-1.3, US-3 AC-1.4
  - Command: `flutter test test/ui/arena_painter_effects_test.dart`
  - Expected: PASS. Nếu Unit 1 đã có golden z-order, **cập nhật** ảnh chuẩn của nó chứ không viết lại test.

### 14. Nối vào `_drain`

- [x] 14.1 Write the failing test
  - Reference: US-1 AC-1.3, US-1 AC-3.1, US-2 AC-1.3, US-4 AC-2.4
  - Files: `test/ui/game_screen_feedback_test.dart`
  - Add coverage cho `_drain` phát cho hai consumer, và cho kết màn.
  - Test file: `test/ui/game_screen_feedback_test.dart`
  - Expected assertion: mỗi `bank`/`blocked`/`broke` sinh **cả** phần tử hiệu ứng **và** một lời gọi rung; thắng màn ⇒ hiệu ứng kết màn + `levelEnd`; bi rơi đáy ⇒ **không** rung phá mục tiêu
- [x] 14.2 Run test to verify it fails
  - Reference: US-1 AC-1.3, US-1 AC-3.1, US-2 AC-1.3, US-4 AC-2.4
  - Command: `flutter test test/ui/game_screen_feedback_test.dart`
  - Expected: FAIL vì `_drain` chưa phát cho hai consumer.
- [x] 14.3 Write minimal implementation
  - Reference: US-1 AC-1.3, US-1 AC-3.1, US-2 AC-1.3, US-4 AC-2.4
  - Implementation file: `lib/ui/screens/game_screen.dart`
  - Trong `_drain` (`game_screen.dart:143-171`) thêm hai lời gọi mỗi sự kiện. `endShot(runner.endReason)` là câu lệnh **đầu tiên** của `_finishShot`. Capture `hapticServiceProvider` trong `initState` cạnh `_audio`. Âm thanh đi qua `game_audio_service` sẵn có, **không** dựng đường phát âm riêng.
- [x] 14.4 Run test to verify it passes
  - Reference: US-1 AC-1.3, US-1 AC-3.1, US-2 AC-1.3, US-4 AC-2.4
  - Command: `flutter test test/ui/game_screen_feedback_test.dart`
  - Expected: PASS.
- [x] 14.5 Nối `tick` và cờ `dirty`
  - Reference: US-3 AC-3.3, US-3 AC-3.4
  - Files: `lib/ui/screens/game_screen.dart`, `test/ui/game_screen_feedback_test.dart`
  - Thêm `effects.tick(dt)` vào `_onTick` và `effects.isNotEmpty` vào điều kiện `dirty`; gọi `clear()` từ `_load()`. Thêm test: hiệu ứng còn sống sau khi tem cuối hết tuổi ⇒ màn hình **vẫn** repaint.
- [x] 14.6 Nối âm thanh qua cơ chế sẵn có
  - Reference: US-1 AC-3.2, US-2 AC-2.4
  - Files: `lib/ui/screens/game_screen.dart`, `test/ui/game_screen_feedback_test.dart`
  - Hiệu ứng phát âm qua `game_audio_service` sẵn có — dùng `wallImpact` cho `bank` và `comicImpact` cho `broke`, **không** thêm asset âm thanh mới và **không** dựng đường phát âm thứ hai.
  - Tests:
    - Test file: `test/ui/game_screen_feedback_test.dart`
    - Test cases: nhiều `bank` trong một cú carom ⇒ số lần phát âm bị cooldown sẵn có của `game_audio_service` chặn, không phát dày; không có `GameSound` nào mới được thêm vào enum
  - Validate với `flutter test test/ui/game_screen_feedback_test.dart`

### 15. Không chặn thao tác, không hoãn cú bắn

- [x] 15.1 Write the failing test
  - Reference: US-3 AC-2.1, US-3 AC-2.2, US-4 AC-2.5
  - Files: `test/ui/game_screen_feedback_test.dart`
  - Add coverage cho việc hiệu ứng không chặn input và không hoãn cú bắn mới.
  - Test file: `test/ui/game_screen_feedback_test.dart`
  - Expected assertion: bắn khi hiệu ứng đang chạy ⇒ cú bắn khởi động **cùng tick**, không hoãn; kéo ngắm khi hiệu ứng đang chạy ⇒ hướng ngắm vẫn đổi; kéo ngắm ⇒ **không** có lời gọi rung nào
- [x] 15.2 Run test to verify it fails
  - Reference: US-3 AC-2.1, US-3 AC-2.2, US-4 AC-2.5
  - Command: `flutter test test/ui/game_screen_feedback_test.dart`
  - Expected: FAIL nếu tầng hiệu ứng vô tình chen vào cây widget dưới `GestureDetector`.
- [x] 15.3 Write minimal implementation
  - Reference: US-3 AC-2.1, US-3 AC-2.2, US-4 AC-2.5
  - Implementation file: `lib/ui/screens/game_screen.dart`
  - Hiệu ứng chỉ được **vẽ** trong `CustomPainter`, **không** thêm widget nào dưới `GestureDetector`. Preview ngắm dùng runner probe riêng nên không sự kiện nào của nó vào kênh rung.
- [x] 15.4 Run test to verify it passes
  - Reference: US-3 AC-2.1, US-3 AC-2.2, US-4 AC-2.5
  - Command: `flutter test test/ui/game_screen_feedback_test.dart`
  - Expected: PASS.

### 16. Reduced-motion và camera shake

- [x] 16.1 Write the failing test
  - Reference: US-3 AC-4.1, US-3 AC-4.2, US-3 AC-4.3, US-3 AC-4.4
  - Files: `test/ui/game_screen_reduced_motion_test.dart`
  - Add coverage cho gate reduced-motion, multiplier tĩnh và camera shake.
  - Test file: `test/ui/game_screen_reduced_motion_test.dart`
  - Expected assertion: `disableAnimationsOf == true` ⇒ `onEvent` không sinh
    effect, multiplier không punch, camera offset bằng 0; chip số dội, `armed` và
    capsule hệ số vẫn hiện. Khi animation bật, `_shake` chỉ do `broke`, không do bank.
- [x] 16.2 Run test to verify it fails
  - Reference: US-3 AC-4.1, US-3 AC-4.2, US-3 AC-4.3, US-3 AC-4.4
  - Command: `flutter test test/ui/game_screen_reduced_motion_test.dart`
  - Expected: FAIL vì gate chưa có.
- [x] 16.3 Write minimal implementation
  - Reference: US-3 AC-4.1, US-3 AC-4.2, US-3 AC-4.3, US-3 AC-4.4
  - Implementation file: `lib/ui/screens/game_screen.dart`, `lib/ui/comic_effect_controller.dart`
  - Đọc `MediaQuery.disableAnimationsOf(context)` trong `build`, truyền xuống
    controller và painter; chặn sinh effect, tắt punch và ép camera-shake offset
    về 0. Không thay đổi luật sự kiện hoặc simulation.
- [x] 16.4 Run test to verify it passes
  - Reference: US-3 AC-4.1, US-3 AC-4.2, US-3 AC-4.3, US-3 AC-4.4
  - Command: `flutter test test/ui/game_screen_reduced_motion_test.dart`
  - Expected: PASS.

### 17. Chuỗi song ngữ

- [x] 17.1 Write the failing test
  - Reference: US-5 AC-2.3
  - Files: `test/l10n/arb_parity_test.dart`
  - Add coverage cho khoá `hapticsLabel` có ở cả hai file ARB.
  - Test file: `test/l10n/arb_parity_test.dart`
  - Expected assertion: tập khoá `app_vi.arb` và `app_en.arb` giống hệt; `hapticsLabel` có ở cả hai
- [x] 17.2 Run test to verify it fails
  - Reference: US-5 AC-2.3
  - Command: `flutter test test/l10n/arb_parity_test.dart`
  - Expected: FAIL vì khoá chưa có.
- [x] 17.3 Write minimal implementation
  - Reference: US-5 AC-2.3
  - Implementation file: `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`
  - Thêm **một** khoá `hapticsLabel` vào cả hai, VI là bản gốc. Chạy `flutter gen-l10n`.
- [x] 17.4 Run test to verify it passes
  - Reference: US-5 AC-2.3
  - Command: `flutter test test/l10n/arb_parity_test.dart`
  - Expected: PASS.

### 17b. Chốt ranh giới của kênh rung

- [x] 17b.1 Write the failing test
  - Reference: US-4 AC-4.1, US-4 AC-4.2, US-4 AC-4.3
  - Files: `test/core/haptic_boundary_test.dart`
  - Add coverage cho ba ràng buộc ranh giới: rung dùng **cùng** bộ sự kiện với hiệu ứng, không đụng `lib/sim/`, không thêm dependency.
  - Test file: `test/core/haptic_boundary_test.dart`
  - Expected assertion: mọi `HapticEvent` map 1-1 với một `ShotEventKind` hoặc mốc kết màn — **không** có mốc nào riêng của rung (AC-4.1); không file nào trong `lib/sim/` import `package:flutter` và `shot_runner.dart` không import `haptic_service.dart` (AC-4.2); `pubspec.yaml` **không** có package rung nào — chỉ `flutter/services.dart` built-in (AC-4.3)
- [x] 17b.2 Run test to verify it fails
  - Reference: US-4 AC-4.1, US-4 AC-4.2, US-4 AC-4.3
  - Command: `flutter test test/core/haptic_boundary_test.dart`
  - Expected: FAIL vì test chưa tồn tại (không phải vì ranh giới bị vi phạm).
- [x] 17b.3 Write minimal implementation
  - Reference: US-4 AC-4.1, US-4 AC-4.2, US-4 AC-4.3
  - Implementation file: `test/core/haptic_boundary_test.dart`
  - Task **chỉ có test** — nó khoá ba ràng buộc mà unit này SHALL không phá. Không sửa code sản phẩm. Nếu test đỏ ở bước 17b.2 vì lý do **khác** việc test chưa có, tức một task trước đã phá ranh giới và phải sửa task đó.
- [x] 17b.4 Run test to verify it passes
  - Reference: US-4 AC-4.1, US-4 AC-4.2, US-4 AC-4.3
  - Command: `flutter test test/core/haptic_boundary_test.dart`
  - Expected: PASS.

### 18. Chốt bất biến và kiểm toàn bộ

- [x] 18.1 Write the failing test
  - Reference: US-2 AC-2.1, US-2 AC-2.3
  - Files: `test/sim/invariants_test.dart`
  - Add coverage khoá các hằng số cân bằng và ranh giới `lib/sim/`.
  - Test file: `test/sim/invariants_test.dart`
  - Expected assertion: `kMaxBanks`, `kMinAimUp`, `kMaxMultiplier`, `starThresholds` của cả 20 màn **giữ đúng giá trị hiện tại**; không file nào trong `lib/sim/` import `package:flutter`
- [x] 18.2 Run test to verify it fails
  - Reference: US-2 AC-2.1, US-2 AC-2.3
  - Command: `flutter test test/sim/invariants_test.dart`
  - Expected: FAIL vì test chưa tồn tại (không phải vì giá trị sai).
- [x] 18.3 Write minimal implementation
  - Reference: US-2 AC-2.1, US-2 AC-2.3
  - Implementation file: `test/sim/invariants_test.dart`
  - Đây là task **chỉ có test** — nó khoá thứ unit này SHALL không đổi. Không sửa code sản phẩm.
- [x] 18.4 Run test to verify it passes
  - Reference: US-2 AC-2.1, US-2 AC-2.3
  - Command: `flutter test test/sim/invariants_test.dart`
  - Expected: PASS.
- [x] 18.5 Chạy toàn bộ test và phân tích tĩnh
  - Reference: US-3 AC-3.2, US-3 AC-3.3, US-3 AC-3.4
  - Command: `flutter analyze && flutter test`
  - Expected: 0 issue; mọi test xanh gồm 16 test sẵn có. Ba AC hiệu năng (`US-3 AC-3.1` 60fps, cooldown "đúng cảm giác", trần phần tử dưới tải thật) **không đóng được bằng test host** — chúng cần thiết bị tham chiếu đã ghi ở § Điều kiện chưa kiểm và phải mang sang xác minh sau khi có APK.

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
