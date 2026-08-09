---
artifact_type: tasks
phase: construction
status: draft
created: 2026-08-05
updated: 2026-08-05
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

- [ ] 1.1 Write the failing test
  - Reference: US-1 AC-1.5, US-3 AC-3.5
  - Files: `test/ui/comic_effect_tier_test.dart`
  - Add coverage cho bảng bậc: miền `0..kMaxBanks`, đơn điệu tăng, bậc chết dùng lại bậc đỉnh.
  - Test file: `test/ui/comic_effect_tier_test.dart`
  - Expected assertion: `level 0` không có bậc; `level 1..4` tăng đơn điệu ở **cả bốn** tham số; bước `3→4` lớn hơn bước `2→3` ở cả bốn; `tierFor(5) == tierFor(4)`; `kMaxEffectElements == 24`
- [ ] 1.2 Run test to verify it fails
  - Reference: US-1 AC-1.5, US-3 AC-3.5
  - Command: `flutter test test/ui/comic_effect_tier_test.dart`
  - Expected: FAIL vì `lib/ui/comic_effect_controller.dart` chưa tồn tại.
- [ ] 1.3 Write minimal implementation
  - Reference: US-1 AC-1.5, US-3 AC-3.5
  - Implementation file: `lib/ui/comic_effect_controller.dart`
  - Khai `EffectTier` (`level`, `duration`, `spokeCount`, `spokeLength`, `spokeWidth`), bảng 6 bậc theo § `comic_effect_controller`, `kMaxEffectElements`. Ngưỡng bậc đỉnh đọc `kMaxBanks - 1`, **không** viết cứng 4.
- [ ] 1.4 Run test to verify it passes
  - Reference: US-1 AC-1.5, US-3 AC-3.5
  - Command: `flutter test test/ui/comic_effect_tier_test.dart`
  - Expected: PASS.

### 2. Chọn bậc theo loại sự kiện

- [ ] 2.1 Write the failing test
  - Reference: US-1 AC-1.1, US-1 AC-2.1, US-1 AC-2.2, US-2 AC-1.1
  - Files: `test/ui/comic_effect_controller_test.dart`
  - Add coverage cho `onEvent` chọn bậc: `bank` theo số dội, `broke` theo hệ số, `blocked` theo `banksAtEvent`.
  - Test file: `test/ui/comic_effect_controller_test.dart`
  - Expected assertion: `bank` với `banksAtEvent: 3` ⇒ bậc 3; `broke` với `banksAtEvent: 3` ⇒ bậc theo hệ số `min(1+3, kMaxMultiplier) == 4`; `blocked` với `banksAtEvent: 2` ⇒ bậc 2 **không** bậc 0 (dù `e.bankCount` là 0); `bank` với `banksAtEvent: 0` ⇒ không sinh phần tử
- [ ] 2.2 Run test to verify it fails
  - Reference: US-1 AC-1.1, US-1 AC-2.1, US-1 AC-2.2, US-2 AC-1.1
  - Command: `flutter test test/ui/comic_effect_controller_test.dart`
  - Expected: FAIL vì `onEvent` chưa có.
- [ ] 2.3 Write minimal implementation
  - Reference: US-1 AC-1.1, US-1 AC-2.1, US-1 AC-2.2, US-2 AC-1.1
  - Implementation file: `lib/ui/comic_effect_controller.dart`
  - `onEvent(ShotEvent e, {required int banksAtEvent})`. `banksAtEvent` là nguồn có thẩm quyền cho cả ba loại — **không** đọc `e.bankCount` cho `blocked` vì `shot_runner.dart:210` không truyền nó.
- [ ] 2.4 Run test to verify it passes
  - Reference: US-1 AC-1.1, US-1 AC-2.1, US-1 AC-2.2, US-2 AC-1.1
  - Command: `flutter test test/ui/comic_effect_controller_test.dart`
  - Expected: PASS.
- [ ] 2.5 Chốt bi dội mục tiêu không tính công dội
  - Reference: US-1 AC-2.1
  - Files: `test/ui/comic_effect_controller_test.dart`
  - Thêm test: một chuỗi sự kiện có `blocked` xen giữa hai `bank` **không** làm bậc leo thêm — dội mục tiêu không phải công dội (PDR §8.4).

### 3. Vòng đời phần tử và trần

- [ ] 3.1 Write the failing test
  - Reference: US-2 AC-1.2, US-3 AC-3.5
  - Files: `test/ui/comic_effect_controller_test.dart`
  - Add coverage cho `tick` già hoá, loại phần tử hết tuổi, và trần phần tử.
  - Test file: `test/ui/comic_effect_controller_test.dart`
  - Expected assertion: sau `tick(duration + ε)` phần tử bị loại; nhiều `broke` liên tiếp **cộng dồn** không xoá nhau (AC US-2/1.2); sinh 30 phần tử ⇒ `elements.length == 24` và phần tử **cũ nhất** bị loại
- [ ] 3.2 Run test to verify it fails
  - Reference: US-2 AC-1.2, US-3 AC-3.5
  - Command: `flutter test test/ui/comic_effect_controller_test.dart`
  - Expected: FAIL vì `tick` và trần chưa có.
- [ ] 3.3 Write minimal implementation
  - Reference: US-2 AC-1.2, US-3 AC-3.5
  - Implementation file: `lib/ui/comic_effect_controller.dart`
  - `tick(double dt)` cộng `age`, loại phần tử `age > tier.duration`; vượt trần thì loại cũ nhất.
- [ ] 3.4 Run test to verify it passes
  - Reference: US-2 AC-1.2, US-3 AC-3.5
  - Command: `flutter test test/ui/comic_effect_controller_test.dart`
  - Expected: PASS.

### 4. `endShot` phân biệt kiểu chết

- [ ] 4.1 Write the failing test
  - Reference: US-1 AC-2.3, US-2 AC-1.3
  - Files: `test/ui/comic_effect_controller_test.dart`
  - Add coverage cho `endShot(ShotEndReason)`.
  - Test file: `test/ui/comic_effect_controller_test.dart`
  - Expected assertion: `endShot(exitedBottom)` ⇒ `elements` rỗng; `endShot(banksExhausted)` và `endShot(timeout)` ⇒ phần tử đang sống **vẫn còn** để chạy hết tuổi
- [ ] 4.2 Run test to verify it fails
  - Reference: US-1 AC-2.3, US-2 AC-1.3
  - Command: `flutter test test/ui/comic_effect_controller_test.dart`
  - Expected: FAIL vì `endShot` chưa nhận tham số.
- [ ] 4.3 Write minimal implementation
  - Reference: US-1 AC-2.3, US-2 AC-1.3
  - Implementation file: `lib/ui/comic_effect_controller.dart`
  - `endShot(ShotEndReason reason)` theo bảng ở § `game_screen`. Thêm `clear()` và `isNotEmpty`.
- [ ] 4.4 Run test to verify it passes
  - Reference: US-1 AC-2.3, US-2 AC-1.3
  - Command: `flutter test test/ui/comic_effect_controller_test.dart`
  - Expected: PASS.

### 5. Bốn pattern rung

- [ ] 5.1 Write the failing test
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-1.4
  - Files: `test/core/haptic_service_test.dart`
  - Add coverage cho bốn `HapticEvent` map sang bốn pattern **khác nhau**.
  - Test file: `test/core/haptic_service_test.dart`
  - Expected assertion: bốn lần `fire` với bốn event khác nhau ⇒ bốn method channel call **khác nhau** (bắt qua `TestDefaultBinaryMessengerBinding` mock của `SystemChannels.platform`)
- [ ] 5.2 Run test to verify it fails
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-1.4
  - Command: `flutter test test/core/haptic_service_test.dart`
  - Expected: FAIL vì `lib/core/haptic_service.dart` chưa tồn tại.
- [ ] 5.3 Write minimal implementation
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-1.4
  - Implementation file: `lib/core/haptic_service.dart`
  - `HapticEvent`, `HapticService({required bool enabled, DateTime Function()? now})`, `fire`. Map: `bank`→`selectionClick`, `blockedShot`→`mediumImpact`, `targetBroken`→`heavyImpact`, `levelEnd`→`vibrate`.
- [ ] 5.4 Run test to verify it passes
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-1.4
  - Command: `flutter test test/core/haptic_service_test.dart`
  - Expected: PASS.

### 6. Cooldown hai tầng

- [ ] 6.1 Write the failing test
  - Reference: US-4 AC-2.1, US-4 AC-2.2, US-4 AC-2.3
  - Files: `test/core/haptic_service_test.dart`
  - Add coverage cho bucket: ba sự kiện gameplay chia **một** cửa sổ; `levelEnd` miễn cooldown.
  - Test file: `test/core/haptic_service_test.dart`
  - Expected assertion: `bank` rồi `targetBroken` cách 20ms ⇒ chỉ **một** lần rung (chia bucket); cách 70ms ⇒ hai lần; **`targetBroken` rồi `levelEnd` cách 16ms ⇒ HAI lần rung** — đây là test bắt được lỗi cooldown chung; `now` tiêm được nên không cần thiết bị
- [ ] 6.2 Run test to verify it fails
  - Reference: US-4 AC-2.1, US-4 AC-2.2, US-4 AC-2.3
  - Command: `flutter test test/core/haptic_service_test.dart`
  - Expected: FAIL — đặc biệt ở assertion `levelEnd`, vốn là ca dễ cài sai nhất.
- [ ] 6.3 Write minimal implementation
  - Reference: US-4 AC-2.1, US-4 AC-2.2, US-4 AC-2.3
  - Implementation file: `lib/core/haptic_service.dart`
  - `static const Map<HapticEvent, int> _bucket`, `static const Map<int, Duration> _cooldown`, `Map<int, DateTime> _lastFired` khoá **theo bucket**. **Không** dùng `Map<HapticEvent, Duration>` như audio — đó là cooldown per-key và sẽ cho mỗi sự kiện một timer riêng.
- [ ] 6.4 Run test to verify it passes
  - Reference: US-4 AC-2.1, US-4 AC-2.2, US-4 AC-2.3
  - Command: `flutter test test/core/haptic_service_test.dart`
  - Expected: PASS.

### 7. Rung tắt và lỗi platform

- [ ] 7.1 Write the failing test
  - Reference: US-4 AC-3.1, US-4 AC-3.2
  - Files: `test/core/haptic_service_test.dart`
  - Add coverage cho `enabled == false` và cho platform channel throw.
  - Test file: `test/core/haptic_service_test.dart`
  - Expected assertion: `enabled == false` ⇒ **không** có channel call nào; mock channel throw ⇒ `fire` không throw **và không** để lại unhandled async error (test fail nếu có)
- [ ] 7.2 Run test to verify it fails
  - Reference: US-4 AC-3.1, US-4 AC-3.2
  - Command: `flutter test test/core/haptic_service_test.dart`
  - Expected: FAIL ở assertion async error — `try`/`catch` đồng bộ không bắt được Future bị reject.
- [ ] 7.3 Write minimal implementation
  - Reference: US-4 AC-3.1, US-4 AC-3.2
  - Implementation file: `lib/core/haptic_service.dart`
  - `unawaited(HapticFeedback.x().catchError((_) {}))`. `setEnabled` trả sớm khi tắt.
- [ ] 7.4 Run test to verify it passes
  - Reference: US-4 AC-3.1, US-4 AC-3.2
  - Command: `flutter test test/core/haptic_service_test.dart`
  - Expected: PASS.

### 8. `hapticsOn` trong cài đặt

- [ ] 8.1 Write the failing test
  - Reference: US-5 AC-1.2, US-5 AC-1.5, US-5 AC-2.1
  - Files: `test/data/settings_repository_test.dart`
  - Add coverage cho `hapticsOn` mặc định bật và tương thích ngược save cũ.
  - Test file: `test/data/settings_repository_test.dart`
  - Expected assertion: prefs **không có** khoá `hapticsOn` ⇒ `hapticsOn == true`; `copyWith` giữ nguyên ba field kia; save rồi load round-trip đúng
- [ ] 8.2 Run test to verify it fails
  - Reference: US-5 AC-1.2, US-5 AC-1.5, US-5 AC-2.1
  - Command: `flutter test test/data/settings_repository_test.dart`
  - Expected: FAIL vì `AppSettings` chưa có `hapticsOn`.
- [ ] 8.3 Write minimal implementation
  - Reference: US-5 AC-1.2, US-5 AC-1.5, US-5 AC-2.1
  - Implementation file: `lib/data/settings_repository.dart`
  - Thêm `hapticsOn` vào `AppSettings` + `copyWith`; `load()` đọc `getBool('hapticsOn') ?? true`; **và thêm nó vào `save()`** — bỏ sót đường ghi là cách AC US-5/1.3 im lặng thất bại.
- [ ] 8.4 Run test to verify it passes
  - Reference: US-5 AC-1.2, US-5 AC-1.5, US-5 AC-2.1
  - Command: `flutter test test/data/settings_repository_test.dart`
  - Expected: PASS.

### 9. Công tắc rung trên màn Cài đặt

- [ ] 9.1 Write the failing test
  - Reference: US-5 AC-1.1, US-5 AC-1.3, US-5 AC-1.4, US-5 AC-2.2, US-5 AC-2.3
  - Files: `test/ui/settings_haptics_test.dart`
  - Add coverage cho hàng công tắc rung.
  - Test file: `test/ui/settings_haptics_test.dart`
  - Expected assertion: công tắc nằm **sau** Nhạc nền và **trước** Ngôn ngữ trong cùng `BbCard`; lật ⇒ áp ngay và lưu; mở lại màn ⇒ khôi phục; `Semantics.toggled` đúng; vùng chạm ≥ 48px
- [ ] 9.2 Run test to verify it fails
  - Reference: US-5 AC-1.1, US-5 AC-1.3, US-5 AC-1.4, US-5 AC-2.2, US-5 AC-2.3
  - Command: `flutter test test/ui/settings_haptics_test.dart`
  - Expected: FAIL vì công tắc chưa có.
- [ ] 9.3 Write minimal implementation
  - Reference: US-5 AC-1.1, US-5 AC-1.3, US-5 AC-1.4, US-5 AC-2.2, US-5 AC-2.3
  - Implementation file: `lib/ui/screens/settings_screen.dart`, `lib/state/providers.dart`
  - `BbToggle` theo đúng khuôn hai hàng đang có, ngăn bởi `Divider(height: sp6)`; thêm `SettingsController.setHaptics`. Dùng **một** khoá `hapticsLabel` cho cả nhãn và `semanticLabel`, đúng như `settings_screen.dart:59-61` đang làm.
- [ ] 9.4 Run test to verify it passes
  - Reference: US-5 AC-1.1, US-5 AC-1.3, US-5 AC-1.4, US-5 AC-2.2, US-5 AC-2.3
  - Command: `flutter test test/ui/settings_haptics_test.dart`
  - Expected: PASS.

### 10. Provider rung

- [ ] 10.1 Write the failing test
  - Reference: US-5 AC-1.3, US-4 AC-3.2
  - Files: `test/state/haptic_provider_test.dart`
  - Add coverage cho việc lật công tắc đồng bộ tới service **không** dựng lại nó.
  - Test file: `test/state/haptic_provider_test.dart`
  - Expected assertion: lật `hapticsOn` ⇒ **cùng một** instance `HapticService` nhận `setEnabled`, không phải instance mới
- [ ] 10.2 Run test to verify it fails
  - Reference: US-5 AC-1.3, US-4 AC-3.2
  - Command: `flutter test test/state/haptic_provider_test.dart`
  - Expected: FAIL vì `hapticServiceProvider` chưa tồn tại.
- [ ] 10.3 Write minimal implementation
  - Reference: US-5 AC-1.3, US-4 AC-3.2
  - Implementation file: `lib/state/providers.dart`
  - `ref.read` + `ref.listen` theo đúng khuôn `gameAudioProvider` (`providers.dart:83-96`).
- [ ] 10.4 Run test to verify it passes
  - Reference: US-5 AC-1.3, US-4 AC-3.2
  - Command: `flutter test test/state/haptic_provider_test.dart`
  - Expected: PASS.

### 11. Chỉ số hệ số BỪA rõ dần

- [ ] 11.1 Write the failing test
  - Reference: US-1 AC-1.2, US-2 AC-2.2
  - Files: `test/ui/multiplier_scale_test.dart`
  - Add coverage cho việc chỉ số hệ số to/đậm dần theo số dội, và **không** hồi quy tương phản.
  - Test file: `test/ui/multiplier_scale_test.dart`
  - Expected assertion: cỡ chữ hệ số ở `banks == 4` **lớn hơn** ở `banks == 1`; alpha **không giảm** so với `0x59` hiện tại (làm chữ to hơn không được đánh đổi bằng mờ hơn)
- [ ] 11.2 Run test to verify it fails
  - Reference: US-1 AC-1.2, US-2 AC-2.2
  - Command: `flutter test test/ui/multiplier_scale_test.dart`
  - Expected: FAIL vì `_paintMultiplier` còn cố định `fit.u(11)`.
- [ ] 11.3 Write minimal implementation
  - Reference: US-1 AC-1.2, US-2 AC-2.2
  - Implementation file: `lib/ui/arena_painter.dart`
  - `_paintMultiplier` nhận `banks` và tăng cỡ chữ theo bậc. Giữ vị trí z-order hiện tại (**trên** mục tiêu) — đây là đường code riêng, không đi qua `EffectTier`.
- [ ] 11.4 Run test to verify it passes
  - Reference: US-1 AC-1.2, US-2 AC-2.2
  - Command: `flutter test test/ui/multiplier_scale_test.dart`
  - Expected: PASS.
- [ ] 11.5 Đo và ghi tương phản
  - Reference: US-2 AC-2.2
  - Files: `aidlc-docs/specs/phan-hoi-cu-ban/design.md`
  - Đo tỉ lệ tương phản của hệ số ở alpha đã chọn trên `bgTop`/`bgBottom`, ghi số vào § Điều kiện chưa kiểm. Mốc hiện tại là **2.45:1** — nghĩa vụ là không hồi quy, không phải đạt 3:1.

### 12. Vẽ chùm vạch va đập

- [ ] 12.1 Write the failing test
  - Reference: US-1 AC-1.4, US-3 AC-1.2
  - Files: `test/ui/arena_painter_effects_test.dart`
  - Add coverage golden cho tầng hiệu ứng vẽ đúng và **không** đổi gì khi rỗng.
  - Test file: `test/ui/arena_painter_effects_test.dart`
  - Expected assertion: `effects` rỗng ⇒ golden **byte-identical** với ảnh không có field này (nhờ default `const []`); `effects` non-rỗng ⇒ vạch toả màu `frame` xuất hiện tại điểm va chạm
- [ ] 12.2 Run test to verify it fails
  - Reference: US-1 AC-1.4, US-3 AC-1.2
  - Command: `flutter test test/ui/arena_painter_effects_test.dart`
  - Expected: FAIL vì `ArenaPainter` chưa có field `effects`.
- [ ] 12.3 Write minimal implementation
  - Reference: US-1 AC-1.4, US-3 AC-1.2
  - Implementation file: `lib/ui/arena_painter.dart`
  - Thêm `final List<EffectElement> effects` **mặc định `const []`** để golden test của Unit 1 không phải sửa. Vẽ vạch thẳng toả, mờ dần theo `age / duration`.
- [ ] 12.4 Run test to verify it passes
  - Reference: US-1 AC-1.4, US-3 AC-1.2
  - Command: `flutter test test/ui/arena_painter_effects_test.dart`
  - Expected: PASS.

### 13. Bảo vệ tín hiệu `armed`

- [ ] 13.1 Write the failing test
  - Reference: US-3 AC-1.1, US-3 AC-1.3, US-3 AC-1.4
  - Files: `test/ui/arena_painter_effects_test.dart`
  - Add coverage cho z-order **và** cho tính đọc được của quầng `armed` khi hiệu ứng chồng lên.
  - Test file: `test/ui/arena_painter_effects_test.dart`
  - Expected assertion: hiệu ứng vẽ **dưới** lớp mục tiêu và **dưới** vệt bay; golden có một case **cố ý** đặt hiệu ứng chồng vùng `r × 1.55` của mục tiêu `armed` ⇒ quầng vẫn đọc được; `onEvent` **không** sinh phần tử có tâm trong vùng đó
- [ ] 13.2 Run test to verify it fails
  - Reference: US-3 AC-1.1, US-3 AC-1.3, US-3 AC-1.4
  - Command: `flutter test test/ui/arena_painter_effects_test.dart`
  - Expected: FAIL vì ràng buộc vùng loại trừ chưa có.
- [ ] 13.3 Write minimal implementation
  - Reference: US-3 AC-1.1, US-3 AC-1.3, US-3 AC-1.4
  - Implementation file: `lib/ui/comic_effect_controller.dart`, `lib/ui/arena_painter.dart`
  - `onEvent` bỏ qua phần tử có tâm trong `r × 1.55` của mục tiêu còn sống; đoạn vạch cắt qua vùng đó hạ alpha dưới `0x28`. Chèn draw call vào khe `vệt ma → [gợi ý] → [hiệu ứng] → vệt bay`.
- [ ] 13.4 Run test to verify it passes
  - Reference: US-3 AC-1.1, US-3 AC-1.3, US-3 AC-1.4
  - Command: `flutter test test/ui/arena_painter_effects_test.dart`
  - Expected: PASS. Nếu Unit 1 đã có golden z-order, **cập nhật** ảnh chuẩn của nó chứ không viết lại test.

### 14. Nối vào `_drain`

- [ ] 14.1 Write the failing test
  - Reference: US-1 AC-1.3, US-1 AC-3.1, US-2 AC-1.3, US-4 AC-2.4
  - Files: `test/ui/game_screen_feedback_test.dart`
  - Add coverage cho `_drain` phát cho hai consumer, và cho kết màn.
  - Test file: `test/ui/game_screen_feedback_test.dart`
  - Expected assertion: mỗi `bank`/`blocked`/`broke` sinh **cả** phần tử hiệu ứng **và** một lời gọi rung; thắng màn ⇒ hiệu ứng kết màn + `levelEnd`; bi rơi đáy ⇒ **không** rung phá mục tiêu
- [ ] 14.2 Run test to verify it fails
  - Reference: US-1 AC-1.3, US-1 AC-3.1, US-2 AC-1.3, US-4 AC-2.4
  - Command: `flutter test test/ui/game_screen_feedback_test.dart`
  - Expected: FAIL vì `_drain` chưa phát cho hai consumer.
- [ ] 14.3 Write minimal implementation
  - Reference: US-1 AC-1.3, US-1 AC-3.1, US-2 AC-1.3, US-4 AC-2.4
  - Implementation file: `lib/ui/screens/game_screen.dart`
  - Trong `_drain` (`game_screen.dart:143-171`) thêm hai lời gọi mỗi sự kiện. `endShot(runner.endReason)` là câu lệnh **đầu tiên** của `_finishShot`. Capture `hapticServiceProvider` trong `initState` cạnh `_audio`. Âm thanh đi qua `game_audio_service` sẵn có, **không** dựng đường phát âm riêng.
- [ ] 14.4 Run test to verify it passes
  - Reference: US-1 AC-1.3, US-1 AC-3.1, US-2 AC-1.3, US-4 AC-2.4
  - Command: `flutter test test/ui/game_screen_feedback_test.dart`
  - Expected: PASS.
- [ ] 14.5 Nối `tick` và cờ `dirty`
  - Reference: US-3 AC-3.3, US-3 AC-3.4
  - Files: `lib/ui/screens/game_screen.dart`, `test/ui/game_screen_feedback_test.dart`
  - Thêm `effects.tick(dt)` vào `_onTick` và `effects.isNotEmpty` vào điều kiện `dirty`; gọi `clear()` từ `_load()`. Thêm test: hiệu ứng còn sống sau khi tem cuối hết tuổi ⇒ màn hình **vẫn** repaint.
- [ ] 14.6 Nối âm thanh qua cơ chế sẵn có
  - Reference: US-1 AC-3.2, US-2 AC-2.4
  - Files: `lib/ui/screens/game_screen.dart`, `test/ui/game_screen_feedback_test.dart`
  - Hiệu ứng phát âm qua `game_audio_service` sẵn có — dùng `wallImpact` cho `bank` và `comicImpact` cho `broke`, **không** thêm asset âm thanh mới và **không** dựng đường phát âm thứ hai.
  - Tests:
    - Test file: `test/ui/game_screen_feedback_test.dart`
    - Test cases: nhiều `bank` trong một cú carom ⇒ số lần phát âm bị cooldown sẵn có của `game_audio_service` chặn, không phát dày; không có `GameSound` nào mới được thêm vào enum
  - Validate với `flutter test test/ui/game_screen_feedback_test.dart`

### 15. Không chặn thao tác, không hoãn cú bắn

- [ ] 15.1 Write the failing test
  - Reference: US-3 AC-2.1, US-3 AC-2.2, US-4 AC-2.5
  - Files: `test/ui/game_screen_feedback_test.dart`
  - Add coverage cho việc hiệu ứng không chặn input và không hoãn cú bắn mới.
  - Test file: `test/ui/game_screen_feedback_test.dart`
  - Expected assertion: bắn khi hiệu ứng đang chạy ⇒ cú bắn khởi động **cùng tick**, không hoãn; kéo ngắm khi hiệu ứng đang chạy ⇒ hướng ngắm vẫn đổi; kéo ngắm ⇒ **không** có lời gọi rung nào
- [ ] 15.2 Run test to verify it fails
  - Reference: US-3 AC-2.1, US-3 AC-2.2, US-4 AC-2.5
  - Command: `flutter test test/ui/game_screen_feedback_test.dart`
  - Expected: FAIL nếu tầng hiệu ứng vô tình chen vào cây widget dưới `GestureDetector`.
- [ ] 15.3 Write minimal implementation
  - Reference: US-3 AC-2.1, US-3 AC-2.2, US-4 AC-2.5
  - Implementation file: `lib/ui/screens/game_screen.dart`
  - Hiệu ứng chỉ được **vẽ** trong `CustomPainter`, **không** thêm widget nào dưới `GestureDetector`. Preview ngắm dùng runner probe riêng nên không sự kiện nào của nó vào kênh rung.
- [ ] 15.4 Run test to verify it passes
  - Reference: US-3 AC-2.1, US-3 AC-2.2, US-4 AC-2.5
  - Command: `flutter test test/ui/game_screen_feedback_test.dart`
  - Expected: PASS.

### 16. Reduced-motion và không hồi quy rung màn

- [ ] 16.1 Write the failing test
  - Reference: US-3 AC-4.1, US-3 AC-4.2, US-3 AC-4.3, US-3 AC-4.4
  - Files: `test/ui/game_screen_reduced_motion_test.dart`
  - Add coverage cho gate reduced-motion và cho việc rung màn **không** mở rộng.
  - Test file: `test/ui/game_screen_reduced_motion_test.dart`
  - Expected assertion: `disableAnimationsOf == true` ⇒ `onEvent` **không sinh** phần tử nào và `dirty` không bị kích bởi hiệu ứng; chip số dội và hệ số HUD **vẫn** hiện đúng số dội; `_shake` được đặt **chỉ** bởi `broke`, **không** bởi `bank`
- [ ] 16.2 Run test to verify it fails
  - Reference: US-3 AC-4.1, US-3 AC-4.2, US-3 AC-4.3, US-3 AC-4.4
  - Command: `flutter test test/ui/game_screen_reduced_motion_test.dart`
  - Expected: FAIL vì gate chưa có.
- [ ] 16.3 Write minimal implementation
  - Reference: US-3 AC-4.1, US-3 AC-4.2, US-3 AC-4.3, US-3 AC-4.4
  - Implementation file: `lib/ui/screens/game_screen.dart`, `lib/ui/comic_effect_controller.dart`
  - Đọc `MediaQuery.disableAnimationsOf(context)` trong `build`, truyền xuống controller; gate là **chặn sinh phần tử** trong `onEvent`. **Không** đụng `_shake`.
- [ ] 16.4 Run test to verify it passes
  - Reference: US-3 AC-4.1, US-3 AC-4.2, US-3 AC-4.3, US-3 AC-4.4
  - Command: `flutter test test/ui/game_screen_reduced_motion_test.dart`
  - Expected: PASS.

### 17. Chuỗi song ngữ

- [ ] 17.1 Write the failing test
  - Reference: US-5 AC-2.3
  - Files: `test/l10n/arb_parity_test.dart`
  - Add coverage cho khoá `hapticsLabel` có ở cả hai file ARB.
  - Test file: `test/l10n/arb_parity_test.dart`
  - Expected assertion: tập khoá `app_vi.arb` và `app_en.arb` giống hệt; `hapticsLabel` có ở cả hai
- [ ] 17.2 Run test to verify it fails
  - Reference: US-5 AC-2.3
  - Command: `flutter test test/l10n/arb_parity_test.dart`
  - Expected: FAIL vì khoá chưa có.
- [ ] 17.3 Write minimal implementation
  - Reference: US-5 AC-2.3
  - Implementation file: `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`
  - Thêm **một** khoá `hapticsLabel` vào cả hai, VI là bản gốc. Chạy `flutter gen-l10n`.
- [ ] 17.4 Run test to verify it passes
  - Reference: US-5 AC-2.3
  - Command: `flutter test test/l10n/arb_parity_test.dart`
  - Expected: PASS.

### 17b. Chốt ranh giới của kênh rung

- [ ] 17b.1 Write the failing test
  - Reference: US-4 AC-4.1, US-4 AC-4.2, US-4 AC-4.3
  - Files: `test/core/haptic_boundary_test.dart`
  - Add coverage cho ba ràng buộc ranh giới: rung dùng **cùng** bộ sự kiện với hiệu ứng, không đụng `lib/sim/`, không thêm dependency.
  - Test file: `test/core/haptic_boundary_test.dart`
  - Expected assertion: mọi `HapticEvent` map 1-1 với một `ShotEventKind` hoặc mốc kết màn — **không** có mốc nào riêng của rung (AC-4.1); không file nào trong `lib/sim/` import `package:flutter` và `shot_runner.dart` không import `haptic_service.dart` (AC-4.2); `pubspec.yaml` **không** có package rung nào — chỉ `flutter/services.dart` built-in (AC-4.3)
- [ ] 17b.2 Run test to verify it fails
  - Reference: US-4 AC-4.1, US-4 AC-4.2, US-4 AC-4.3
  - Command: `flutter test test/core/haptic_boundary_test.dart`
  - Expected: FAIL vì test chưa tồn tại (không phải vì ranh giới bị vi phạm).
- [ ] 17b.3 Write minimal implementation
  - Reference: US-4 AC-4.1, US-4 AC-4.2, US-4 AC-4.3
  - Implementation file: `test/core/haptic_boundary_test.dart`
  - Task **chỉ có test** — nó khoá ba ràng buộc mà unit này SHALL không phá. Không sửa code sản phẩm. Nếu test đỏ ở bước 17b.2 vì lý do **khác** việc test chưa có, tức một task trước đã phá ranh giới và phải sửa task đó.
- [ ] 17b.4 Run test to verify it passes
  - Reference: US-4 AC-4.1, US-4 AC-4.2, US-4 AC-4.3
  - Command: `flutter test test/core/haptic_boundary_test.dart`
  - Expected: PASS.

### 18. Chốt bất biến và kiểm toàn bộ

- [ ] 18.1 Write the failing test
  - Reference: US-2 AC-2.1, US-2 AC-2.3
  - Files: `test/sim/invariants_test.dart`
  - Add coverage khoá các hằng số cân bằng và ranh giới `lib/sim/`.
  - Test file: `test/sim/invariants_test.dart`
  - Expected assertion: `kMaxBanks`, `kMinAimUp`, `kMaxMultiplier`, `starThresholds` của cả 20 màn **giữ đúng giá trị hiện tại**; không file nào trong `lib/sim/` import `package:flutter`
- [ ] 18.2 Run test to verify it fails
  - Reference: US-2 AC-2.1, US-2 AC-2.3
  - Command: `flutter test test/sim/invariants_test.dart`
  - Expected: FAIL vì test chưa tồn tại (không phải vì giá trị sai).
- [ ] 18.3 Write minimal implementation
  - Reference: US-2 AC-2.1, US-2 AC-2.3
  - Implementation file: `test/sim/invariants_test.dart`
  - Đây là task **chỉ có test** — nó khoá thứ unit này SHALL không đổi. Không sửa code sản phẩm.
- [ ] 18.4 Run test to verify it passes
  - Reference: US-2 AC-2.1, US-2 AC-2.3
  - Command: `flutter test test/sim/invariants_test.dart`
  - Expected: PASS.
- [ ] 18.5 Chạy toàn bộ test và phân tích tĩnh
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
