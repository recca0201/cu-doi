---
artifact_type: tasks
phase: construction
status: draft
created: 2026-08-05
updated: 2026-08-09
unit: duong-ra-khoi-man-bi
source_artifacts:
  - aidlc-docs/specs/duong-ra-khoi-man-bi/requirements.md
  - aidlc-docs/specs/duong-ra-khoi-man-bi/design.md
---

# Tasks: Đường ra khỏi màn bí

Thứ tự: hạ tầng lưu trữ và luật miền trước (chỗ sai làm **mất tiến trình người chơi**), rồi
phép quét gợi ý, rồi UI, cuối cùng nối dây. Mọi lệnh kiểm chạy trên host — không cần thiết bị.

## Implementation Checklist

### 1. Hằng số kinh tế

- [ ] 1.1 Write the failing test
  - Reference: US-1 AC-4.1, US-2 AC-2.5
  - Files: `test/domain/economy_test.dart`
  - Add coverage cho việc giá và mốc nhắc đọc từ một nguồn duy nhất.
  - Test file: `test/domain/economy_test.dart`
  - Expected assertion: `kHintCost == 50`, `kSkipCost == 150`, `kSkipOfferAfterLosses == 3`, `kHintReminderAfterLosses == 2`
- [ ] 1.2 Run test to verify it fails
  - Reference: US-1 AC-4.1, US-2 AC-2.5
  - Command: `flutter test test/domain/economy_test.dart`
  - Expected: FAIL vì `lib/domain/economy.dart` chưa tồn tại, không phải vì lỗi cú pháp test.
- [ ] 1.3 Write minimal implementation
  - Reference: US-1 AC-4.1, US-2 AC-2.5
  - Implementation file: `lib/domain/economy.dart`
  - Chỉ khai bốn hằng số. Không thêm helper, không thêm class.
- [ ] 1.4 Run test to verify it passes
  - Reference: US-1 AC-4.1, US-2 AC-2.5
  - Command: `flutter test test/domain/economy_test.dart`
  - Expected: PASS, không lỗi lan sang test khác.

### 2. Schema `LevelResult` và tương thích ngược save cũ

- [ ] 2.1 Write the failing test
  - Reference: US-2 AC-4.1, US-2 AC-4.2, US-3 AC-1.6
  - Files: `test/domain/player_progress_test.dart`
  - Add coverage cho việc parse save **không có** `skipped`/`losses`, và cho việc `stars`/`highScore` vắng mặt không làm nổ parse.
  - Test file: `test/domain/player_progress_test.dart`
  - Expected assertion: JSON `{"coins":120,"results":{"3":{"stars":2,"highScore":900}}}` parse ra `skipped == false`, `losses == 0`, giữ đúng 2 sao / 900 điểm / 120 xu; JSON `{"results":{"3":{}}}` cho `stars == 0`, không throw
- [ ] 2.2 Run test to verify it fails
  - Reference: US-2 AC-4.1, US-2 AC-4.2, US-3 AC-1.6
  - Command: `flutter test test/domain/player_progress_test.dart`
  - Expected: FAIL vì `LevelResult` chưa có hai field mới và `fromJson` còn dùng `as int` không chịu null (ràng buộc C2).
- [ ] 2.3 Write minimal implementation
  - Reference: US-2 AC-4.1, US-2 AC-4.2, US-3 AC-1.6
  - Implementation file: `lib/domain/player_progress.dart`
  - Thêm `skipped` và `losses` vào `LevelResult` + `toJson`; đổi mọi read trong `fromJson` sang `as T?` kèm mặc định. **Không** đổi khoá `progress_v1`.
- [ ] 2.4 Run test to verify it passes
  - Reference: US-2 AC-4.1, US-2 AC-4.2, US-3 AC-1.6
  - Command: `flutter test test/domain/player_progress_test.dart`
  - Expected: PASS.
- [ ] 2.5 Broaden verification
  - Reference: US-2 AC-4.3
  - Files: `test/domain/player_progress_test.dart`
  - Thêm case JSON rác để chốt chống hồi quy cho `load()` rơi về tiến trình rỗng — hành vi này **đã có** (ràng buộc C10), test chỉ khoá nó lại.

### 3. Luật mở màn có tính "đã bỏ qua"

- [ ] 3.1 Write the failing test
  - Reference: US-2 AC-3.2, US-2 AC-3.4
  - Files: `test/domain/player_progress_test.dart`
  - Add coverage cho `completedMax` tính cả màn `skipped`, và cho `totalStars` **không** đổi khi có màn bỏ qua.
  - Test file: `test/domain/player_progress_test.dart`
  - Expected assertion: màn 3 `skipped: true, stars: 0` ⇒ `isUnlocked(4) == true`, `totalStars` không tăng, `isCompleted(3) == false`, `isSkipped(3) == true`
- [ ] 3.2 Run test to verify it fails
  - Reference: US-2 AC-3.2, US-2 AC-3.4
  - Command: `flutter test test/domain/player_progress_test.dart`
  - Expected: FAIL vì `completedMax` còn lọc `stars >= 1` (ràng buộc C1).
- [ ] 3.3 Write minimal implementation
  - Reference: US-2 AC-3.2, US-2 AC-3.4
  - Implementation file: `lib/domain/player_progress.dart`
  - `completedMax` lọc `stars >= 1 || skipped`; thêm `isSkipped`, `lossesFor`. Giữ `totalStars` và `isCompleted` **nguyên**.
- [ ] 3.4 Run test to verify it passes
  - Reference: US-2 AC-3.2, US-2 AC-3.4
  - Command: `flutter test test/domain/player_progress_test.dart`
  - Expected: PASS, và test smoke sẵn có vẫn xanh (luật mở màn không hồi quy).

### 4. Phép biến đổi tiến trình: tiêu xu, bỏ qua, đếm thua

- [ ] 4.1 Write the failing test
  - Reference: US-1 AC-1.2, US-2 AC-3.1, US-2 AC-3.3, US-3 AC-1.1, US-3 AC-1.2
  - Files: `test/domain/player_progress_test.dart`
  - Add coverage cho `canAfford`/`withCoinsSpent`/`withSkipped`/`withLoss`, và cho việc `withResult` **xoá** `skipped` và **zero** `losses`.
  - Test file: `test/domain/player_progress_test.dart`
  - Expected assertion: `withCoinsSpent` không cho số dư < 0; `withSkipped(3)` cho `skipped == true` **và** `losses == 0`; `withLoss(3)` tăng đúng 1; `withResult(3, 2, 900)` trên màn đã bỏ qua ⇒ `isSkipped(3) == false` và `lossesFor(3) == 0`
- [ ] 4.2 Run test to verify it fails
  - Reference: US-1 AC-1.2, US-2 AC-3.1, US-2 AC-3.3, US-3 AC-1.1, US-3 AC-1.2
  - Command: `flutter test test/domain/player_progress_test.dart`
  - Expected: FAIL vì bốn phép mới chưa có và `withResult` chưa xử hai field mới.
- [ ] 4.3 Write minimal implementation
  - Reference: US-1 AC-1.2, US-2 AC-3.1, US-2 AC-3.3, US-3 AC-1.1, US-3 AC-1.2
  - Implementation file: `lib/domain/player_progress.dart`
  - Thêm `canAfford`, `withCoinsSpent`, `withSkipped`, `withLoss`; sửa `withResult` xoá `skipped` + zero `losses`. `withResult` vẫn cộng xu theo `score ~/ 10` như cũ.
- [ ] 4.4 Run test to verify it passes
  - Reference: US-1 AC-1.2, US-2 AC-3.1, US-2 AC-3.3, US-3 AC-1.1, US-3 AC-1.2
  - Command: `flutter test test/domain/player_progress_test.dart`
  - Expected: PASS.

### 5. Hợp đồng ghi báo được thất bại

- [ ] 5.1 Write the failing test
  - Reference: US-1 AC-1.3, US-2 AC-2.3
  - Files: `test/data/progress_repository_test.dart`
  - Add coverage cho `save` trả `bool`: `true` khi ghi được, `false` khi `SharedPreferences` từ chối hoặc throw.
  - Test file: `test/data/progress_repository_test.dart`
  - Expected assertion: với prefs mock ghi được ⇒ `true`; với mock throw ⇒ `false` **và không** throw lên caller
- [ ] 5.2 Run test to verify it fails
  - Reference: US-1 AC-1.3, US-2 AC-2.3
  - Command: `flutter test test/data/progress_repository_test.dart`
  - Expected: FAIL vì `save` còn là `Future<void>` (ràng buộc C9).
- [ ] 5.3 Write minimal implementation
  - Reference: US-1 AC-1.3, US-2 AC-2.3
  - Implementation file: `lib/data/progress_repository.dart`
  - Đổi cả `ProgressRepository.save` và `LocalProgressRepository.save` sang `Future<bool>`: `return await _prefs.setString(...)` ở đường thành công, `return false` trong `catch` (giữ `dev.log`). **Không** viết `try { ... } return true;` — đó đúng là cái bẫy làm việc đổi hợp đồng thành vô nghĩa.
- [ ] 5.4 Run test to verify it passes
  - Reference: US-1 AC-1.3, US-2 AC-2.3
  - Command: `flutter test test/data/progress_repository_test.dart`
  - Expected: PASS.
- [ ] 5.5 Wire call sites
  - Reference: US-2 AC-2.3
  - Files: `lib/state/providers.dart`
  - Cập nhật `ProgressController.record` và `reset` cho signature mới nhưng **giữ nguyên** hình dạng commit-rồi-save (Q8). Chạy `flutter analyze` để chốt không còn call site nào lệch.

### 6. `ProgressController`: hai đường tiêu xu

- [ ] 6.1 Write the failing test
  - Reference: US-1 AC-1.1, US-1 AC-1.3, US-2 AC-2.2, US-2 AC-2.3, US-2 AC-2.4
  - Files: `test/state/progress_controller_test.dart`
  - Add coverage cho `spendOnHint`/`skipArena` trả `SpendResult`, và cho việc `save` thất bại **không** commit state.
  - Test file: `test/state/progress_controller_test.dart`
  - Expected assertion: repo trả `false` ⇒ `SpendResult.writeFailed` **và** `state.coins` không đổi **và** `isSkipped` vẫn `false`; số dư thiếu ⇒ `SpendResult.insufficientCoins` và không gọi `save`; thành công ⇒ `SpendResult.ok`, trừ đúng giá, `skipped == true`, `losses == 0`
- [ ] 6.2 Run test to verify it fails
  - Reference: US-1 AC-1.1, US-1 AC-1.3, US-2 AC-2.2, US-2 AC-2.3, US-2 AC-2.4
  - Command: `flutter test test/state/progress_controller_test.dart`
  - Expected: FAIL vì `SpendResult` và hai phép mới chưa có.
- [ ] 6.3 Write minimal implementation
  - Reference: US-1 AC-1.1, US-1 AC-1.3, US-2 AC-2.2, US-2 AC-2.3, US-2 AC-2.4
  - Implementation file: `lib/state/providers.dart`
  - Thêm `enum SpendResult`, `spendOnHint`, `skipArena` theo hình dạng `canAfford` → dựng state → `save` → commit **chỉ khi** `true`.
- [ ] 6.4 Run test to verify it passes
  - Reference: US-1 AC-1.1, US-1 AC-1.3, US-2 AC-2.2, US-2 AC-2.3, US-2 AC-2.4
  - Command: `flutter test test/state/progress_controller_test.dart`
  - Expected: PASS.

### 7. Chống bấm trùng trên đường tiêu xu

- [ ] 7.1 Write the failing test
  - Reference: US-1 AC-1.2
  - Files: `test/state/progress_controller_test.dart`
  - Add coverage cho hai lời gọi liên tiếp không chờ nhau.
  - Test file: `test/state/progress_controller_test.dart`
  - Expected assertion: gọi `spendOnHint()` hai lần không `await` giữa hai lần ⇒ xu chỉ bị trừ **một** lần; tương tự cho `skipArena`
- [ ] 7.2 Run test to verify it fails
  - Reference: US-1 AC-1.2
  - Command: `flutter test test/state/progress_controller_test.dart`
  - Expected: FAIL vì trừ hai lần — chưa có chốt.
- [ ] 7.3 Write minimal implementation
  - Reference: US-1 AC-1.2
  - Implementation file: `lib/state/providers.dart`
  - Thêm cờ "đang xử lý"; lời gọi mới bị bỏ qua khi lời gọi trước chưa xong.
- [ ] 7.4 Run test to verify it passes
  - Reference: US-1 AC-1.2
  - Command: `flutter test test/state/progress_controller_test.dart`
  - Expected: PASS.

### 8. `hint_finder`: phép quét góc

- [ ] 8.1 Write the failing test
  - Reference: US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.3
  - Files: `test/sim/hint_finder_test.dart`
  - Add coverage cho việc tìm được cú phá ≥1 mục tiêu ở **sân đầy** và ở **sân đã vơi**, trả `null` khi không có cú nào, và `path` kết ở vị trí `broke` **cuối cùng**.
  - Test file: `test/sim/hint_finder_test.dart`
  - Expected assertion: với `kArenas[0]` sân đầy ⇒ trả non-null, `targetsDestroyed >= 1`, `path.first == kShooterOrigin`, `path.last` nằm **trong** sân (không phải dưới đáy sân); với `alive` toàn `false` ⇒ `null`
- [ ] 8.2 Run test to verify it fails
  - Reference: US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.3
  - Command: `flutter test test/sim/hint_finder_test.dart`
  - Expected: FAIL vì `lib/sim/hint_finder.dart` chưa tồn tại.
- [ ] 8.3 Write minimal implementation
  - Reference: US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.3
  - Implementation file: `lib/sim/hint_finder.dart`
  - Khai `ArenaSnapshot`, `HintShot`, và top-level `findHintShot(ArenaSnapshot)`. Sao hình dạng vòng lặp của `previewPath` (`shot_runner.dart:240-261`), bỏ chặn `vertices < maxBanks`, thêm ghi nhận `broke`. **Không gọi** `previewPath` — nó bỏ hết `broke`. Giữ `origin` làm đỉnh 0, lấy đỉnh từ **cả** `bank` và `blocked`, vét `pending` mỗi vòng.
- [ ] 8.4 Run test to verify it passes
  - Reference: US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.3
  - Command: `flutter test test/sim/hint_finder_test.dart`
  - Expected: PASS.

### 9. Ba điều kiện đúng đắn của phép quét

- [ ] 9.1 Write the failing test
  - Reference: US-1 AC-2.2, US-1 AC-2.3, US-1 AC-2.4
  - Files: `test/sim/hint_finder_test.dart`
  - Add coverage cho: **không mutate** `alive` của caller; kết quả **tất định**; guard không cắt sớm cú carom dài.
  - Test file: `test/sim/hint_finder_test.dart`
  - Expected assertion: list `alive` truyền vào giữ **y nguyên** sau khi quét; gọi hai lần cùng snapshot ⇒ `aim` giống hệt; một cú cần gần hết 14s bay vẫn được xếp là giải được (guard ≥ 1680 ở `dt = 1/120`, không phải hằng 1500 của `previewPath`)
- [ ] 9.2 Run test to verify it fails
  - Reference: US-1 AC-2.2, US-1 AC-2.3, US-1 AC-2.4
  - Command: `flutter test test/sim/hint_finder_test.dart`
  - Expected: FAIL ở ít nhất assertion mutate — `ShotRunner` ghi thẳng vào list `alive` của caller (`shot_runner.dart:75-77`).
- [ ] 9.3 Write minimal implementation
  - Reference: US-1 AC-2.2, US-1 AC-2.3, US-1 AC-2.4
  - Implementation file: `lib/sim/hint_finder.dart`
  - Mỗi mẫu chạy trên `List<bool>.of(alive)` **riêng**; quét **tăng dần theo góc**; `dt = 1/120`; guard `1680` buộc vào timeout 14s của `ShotRunner`.
- [ ] 9.4 Run test to verify it passes
  - Reference: US-1 AC-2.2, US-1 AC-2.3, US-1 AC-2.4
  - Command: `flutter test test/sim/hint_finder_test.dart`
  - Expected: PASS.
- [ ] 9.5 Add the deadline and the sim-boundary guard
  - Reference: US-1 AC-2.4
  - Files: `lib/sim/hint_finder.dart`, `test/sim/hint_finder_test.dart`
  - Thêm tham số `budget: Duration` kiểm bằng `Stopwatch` **sau mỗi mẫu**, hết ngân sách thì trả kết quả tốt nhất tới lúc đó. Thêm một test khẳng định `hint_finder.dart` **không import Flutter** (PDR §8.7).

### 10. `HintController` và ranh giới isolate

- [ ] 10.1 Write the failing test
  - Reference: US-1 AC-2.4, US-1 AC-4.2, US-1 AC-4.3
  - Files: `test/state/hint_controller_test.dart`
  - Add coverage cho vòng trạng thái `idle → computing → shown`, cho `unavailable` khi không có cú, `failed` khi quét lỗi, và `insufficientCoins` khi thiếu xu.
  - Test file: `test/state/hint_controller_test.dart`
  - Expected assertion: thiếu xu ⇒ `insufficientCoins` và **không** chạy quét; không có cú giải được ⇒ `unavailable` và xu **không** bị trừ; `request` khi `status == computing` bị bỏ qua
- [ ] 10.2 Run test to verify it fails
  - Reference: US-1 AC-2.4, US-1 AC-4.2, US-1 AC-4.3
  - Command: `flutter test test/state/hint_controller_test.dart`
  - Expected: FAIL vì `lib/state/hint_controller.dart` chưa tồn tại.
- [ ] 10.3 Write minimal implementation
  - Reference: US-1 AC-2.4, US-1 AC-4.2, US-1 AC-4.3
  - Implementation file: `lib/state/hint_controller.dart`
  - `HintStatus`, `HintState`, `HintController` với `request` chạy `findHintShot` qua `compute()`. Trừ xu **chỉ sau khi** quét trả non-null. Không gán state sau dispose.
- [ ] 10.4 Run test to verify it passes
  - Reference: US-1 AC-2.4, US-1 AC-4.2, US-1 AC-4.3
  - Command: `flutter test test/state/hint_controller_test.dart`
  - Expected: PASS.

### 11. Vòng đời gợi ý theo `arenaId`

- [ ] 11.1 Write the failing test
  - Reference: US-1 AC-3.6, US-1 AC-5.1, US-1 AC-5.2, US-1 AC-5.3
  - Files: `test/state/hint_controller_test.dart`
  - Add coverage cho bốn trigger: bắn, chơi lại cùng màn, sang màn kế, vào màn mới.
  - Test file: `test/state/hint_controller_test.dart`
  - Expected assertion: mua → bắn ⇒ `path` rỗng nhưng `purchasedPath` **còn**; mua → bắn → `onArenaLoaded(cùng id)` ⇒ `path == purchasedPath` và xu **không** bị trừ thêm; `onArenaLoaded(id khác)` ⇒ **cả hai** path rỗng và `purchasedForArenaId == null`; mua lần hai sau khi đã bắn ⇒ trừ thêm 50 xu
- [ ] 11.2 Run test to verify it fails
  - Reference: US-1 AC-3.6, US-1 AC-5.1, US-1 AC-5.2, US-1 AC-5.3
  - Command: `flutter test test/state/hint_controller_test.dart`
  - Expected: FAIL ở assertion chơi lại — nếu `clearOnShot` xoá bản sao duy nhất thì không còn gì để hiện lại.
- [ ] 11.3 Write minimal implementation
  - Reference: US-1 AC-3.6, US-1 AC-5.1, US-1 AC-5.2, US-1 AC-5.3
  - Implementation file: `lib/state/hint_controller.dart`
  - Thêm `purchasedPath` + `purchasedForArenaId`. `clearOnShot` xoá **chỉ** `path` và đặt `status = idle`. `onArenaLoaded(arenaId)` so id: khớp ⇒ restore, khác ⇒ xoá cả hai và null id.
- [ ] 11.4 Run test to verify it passes
  - Reference: US-1 AC-3.6, US-1 AC-5.1, US-1 AC-5.2, US-1 AC-5.3
  - Command: `flutter test test/state/hint_controller_test.dart`
  - Expected: PASS.

### 12. Lớp vẽ đường gợi ý

- [ ] 12.1 Write the failing test
  - Reference: US-1 AC-3.1, US-1 AC-3.2, US-1 AC-3.5
  - Files: `test/ui/arena_painter_hint_test.dart`
  - Add coverage golden cho z-order: gợi ý **trên** vệt ma, **dưới** vệt bay, và mục tiêu vẽ trên cả hai.
  - Test file: `test/ui/arena_painter_hint_test.dart`
  - Expected assertion: golden khớp ảnh chuẩn với `hintPath` non-rỗng cùng lúc có `ghostTrail` và mục tiêu; `hintPath` rỗng ⇒ không vẽ gì thêm
- [ ] 12.2 Run test to verify it fails
  - Reference: US-1 AC-3.1, US-1 AC-3.2, US-1 AC-3.5
  - Command: `flutter test test/ui/arena_painter_hint_test.dart`
  - Expected: FAIL vì `ArenaPainter` chưa có field `hintPath`.
- [ ] 12.3 Write minimal implementation
  - Reference: US-1 AC-3.1, US-1 AC-3.2, US-1 AC-3.5
  - Implementation file: `lib/ui/arena_painter.dart`
  - Thêm `hintPath`; vẽ giữa `_paintGhost` và `_paintTrail`. Dùng
    `primaryGold` qua token/ArenaInk, nét đứt và vòng waypoint tại mỗi điểm dội;
    không ghi hex/alpha thô trong painter. Dùng lại `_dashed`
    (`arena_painter.dart:455`), không viết routine đứt nét thứ hai.
- [ ] 12.4 Run test to verify it passes
  - Reference: US-1 AC-3.1, US-1 AC-3.2, US-1 AC-3.5
  - Command: `flutter test test/ui/arena_painter_hint_test.dart`
  - Expected: PASS. Sinh ảnh chuẩn bằng `--update-goldens`, rồi kiểm mắt ở 390 ×
    844 trước khi commit theo `uiux-guideline.md` §10.3 và §11.
- [ ] 12.5 Kiểm token và khả năng phân biệt
  - Reference: US-1 AC-3.1
  - Files: `aidlc-docs/specs/duong-ra-khoi-man-bi/design.md`
  - Xác nhận painter chỉ đọc token semantic, không có hex/alpha legacy; golden phải
    phân biệt hint với preview và ghost bằng cả màu lẫn marker/cadence.

### 13. Nút gợi ý trên màn chơi

- [ ] 13.1 Write the failing test
  - Reference: US-1 AC-3.3, US-1 AC-3.4, US-1 AC-6.1, US-1 AC-6.2, US-1 AC-6.4
  - Files: `test/ui/game_screen_hint_test.dart`
  - Add coverage cho nút gợi ý: hiện ở footer, vô hiệu khi thiếu xu, không tự ngắm hộ, không thay hint chữ tĩnh.
  - Test file: `test/ui/game_screen_hint_test.dart`
  - Expected assertion: xu < 50 ⇒ nút vô hiệu nhưng **tìm thấy được** và badge hiện số còn thiếu; bấm nút vô hiệu ⇒ xu không đổi, vẫn ở màn chơi; hint chữ `ArenaSpec.hint` **vẫn** hiện; vùng chạm ≥ 48dp; `Semantics` có label + `button` + `enabled`; hướng ngắm **không** đổi sau khi gợi ý hiện
- [ ] 13.2 Run test to verify it fails
  - Reference: US-1 AC-3.3, US-1 AC-3.4, US-1 AC-6.1, US-1 AC-6.2, US-1 AC-6.4
  - Command: `flutter test test/ui/game_screen_hint_test.dart`
  - Expected: FAIL vì nút chưa tồn tại.
- [ ] 13.3 Write minimal implementation
  - Reference: US-1 AC-3.3, US-1 AC-3.4, US-1 AC-6.1, US-1 AC-6.2, US-1 AC-6.4
  - Implementation file: `lib/ui/screens/game_screen.dart`
  - Dùng action gold hoặc icon button navy có gold accent ở footer, kèm badge
    navy/gold cho giá và số xu còn thiếu. Không dùng variant `accent` nếu nó còn
    ánh xạ coral. Nối `hintPath` vào `ArenaPainter`; preview ngắm vẫn chỉ hai đoạn.
- [ ] 13.4 Run test to verify it passes
  - Reference: US-1 AC-3.3, US-1 AC-3.4, US-1 AC-6.1, US-1 AC-6.2, US-1 AC-6.4
  - Command: `flutter test test/ui/game_screen_hint_test.dart`
  - Expected: PASS.
- [ ] 13.5 Nối phản hồi "đang tính" và announcement
  - Reference: US-1 AC-2.4
  - Files: `lib/ui/screens/game_screen.dart`, `test/ui/game_screen_hint_test.dart`
  - Hiện phản hồi khi `status == computing`; phát `Semantics` announcement khi gợi ý hiện. Quyết định về `HintShot.targetsDestroyed`: **hoặc** dùng nó trong chuỗi announcement, **hoặc** bỏ khỏi contract — đừng ship dữ liệu chết.

### 14. Bộ đếm thua và điểm gọi

- [ ] 14.1 Write the failing test
  - Reference: US-3 AC-1.3, US-3 AC-1.5, US-3 AC-1.7
  - Files: `test/state/progress_controller_test.dart`, `test/ui/game_screen_hint_test.dart`
  - Add coverage cho `recordLoss`: chỉ tăng khi **hết lượt bắn mà còn mục tiêu**, bền qua restart, và reset khi xoá tiến trình.
  - Test file: `test/state/progress_controller_test.dart`
  - Expected assertion: hết lượt còn mục tiêu ⇒ `lossesFor` tăng 1; **thoát màn giữa lượt** ⇒ không tăng; save rồi load lại ⇒ bộ đếm còn nguyên; `reset()` ⇒ mọi bộ đếm về 0
- [ ] 14.2 Run test to verify it fails
  - Reference: US-3 AC-1.3, US-3 AC-1.5, US-3 AC-1.7
  - Command: `flutter test test/state/progress_controller_test.dart`
  - Expected: FAIL vì `recordLoss` chưa có.
- [ ] 14.3 Write minimal implementation
  - Reference: US-3 AC-1.3, US-3 AC-1.5, US-3 AC-1.7
  - Implementation file: `lib/state/providers.dart`, `lib/ui/screens/game_screen.dart`
  - Thêm `recordLoss(int arenaId)`; gọi trong nhánh `else if (_shotsLeft <= 0)` của `_afterShot` (`game_screen.dart:187-189`). Thêm chốt chống gọi trùng đối xứng với `_recorded` mà `_onWin` đang dùng.
- [ ] 14.4 Run test to verify it passes
  - Reference: US-3 AC-1.3, US-3 AC-1.5, US-3 AC-1.7
  - Command: `flutter test test/state/progress_controller_test.dart`
  - Expected: PASS.
- [ ] 14.5 Chốt một bộ đếm duy nhất
  - Reference: US-3 AC-1.4
  - Files: `test/state/progress_controller_test.dart`
  - Thêm test khẳng định điều kiện xuất hiện của bỏ qua màn (US-2 AC-1.1) và mốc nhắc (US-3 AC-2.1/2.2) đọc **cùng** `lossesFor`, không phải hai nguồn song song.

### 15. Bỏ qua màn trên màn hình kết quả

- [ ] 15.1 Write the failing test
  - Reference: US-2 AC-1.1, US-2 AC-1.2, US-2 AC-1.3, US-2 AC-2.1
  - Files: `test/ui/game_screen_skip_test.dart`
  - Add coverage cho điều kiện xuất hiện và dialog xác nhận.
  - Test file: `test/ui/game_screen_skip_test.dart`
  - Expected assertion: thua lần 1 và 2 ⇒ **không** hiện lựa chọn bỏ qua; lần 3 ⇒ hiện; màn đã thắng thật **hoặc** đã bỏ qua ⇒ không hiện; đang trong cú bắn ⇒ không hiện; chọn bỏ qua ⇒ hiện dialog xác nhận **trước** khi xu đổi
- [ ] 15.2 Run test to verify it fails
  - Reference: US-2 AC-1.1, US-2 AC-1.2, US-2 AC-1.3, US-2 AC-2.1
  - Command: `flutter test test/ui/game_screen_skip_test.dart`
  - Expected: FAIL vì lựa chọn bỏ qua chưa tồn tại.
- [ ] 15.3 Write minimal implementation
  - Reference: US-2 AC-1.1, US-2 AC-1.2, US-2 AC-1.3, US-2 AC-2.1
  - Implementation file: `lib/ui/screens/game_screen.dart`
  - Thêm lựa chọn bỏ qua vào overlay kết quả, gate bằng `lossesFor >= kSkipOfferAfterLosses && !isCompleted && !isSkipped`. Xác nhận bằng `showBbDialog` + `BbDialog` — component của hệ đã có, không dựng kiểu popup thứ tư.
- [ ] 15.4 Run test to verify it passes
  - Reference: US-2 AC-1.1, US-2 AC-1.2, US-2 AC-1.3, US-2 AC-2.1
  - Command: `flutter test test/ui/game_screen_skip_test.dart`
  - Expected: PASS.
- [ ] 15.5 Nối kết quả và điều hướng
  - Reference: US-2 AC-2.2, US-2 AC-2.3, US-2 AC-2.4
  - Files: `lib/ui/screens/game_screen.dart`, `test/ui/game_screen_skip_test.dart`
  - Map `SpendResult` sang ba kết cục khác nhau: `ok` ⇒ về bản đồ, truyền `targetArenaId` (định vị là việc của Unit 3); `insufficientCoins` ⇒ vô hiệu kèm giá và số còn thiếu; `writeFailed` ⇒ thông báo, xu không đổi, **không** mở màn kế.

### 16. Lời nhắc khi đang tắc

- [ ] 16.1 Write the failing test
  - Reference: US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-3.1, US-3 AC-3.2, US-3 AC-3.3
  - Files: `test/ui/game_screen_reminder_test.dart`
  - Add coverage cho mốc nhắc, cho lựa chọn thử lại, và cho việc bỏ qua nhắc.
  - Test file: `test/ui/game_screen_reminder_test.dart`
  - Expected assertion: thua lần 2 ⇒ nhắc gợi ý kèm giá; lần 3 ⇒ nhắc **cả** gợi ý và bỏ qua màn kèm giá từng cái; màn đã hoàn thành ⇒ không nhắc bỏ qua; đang trong cú bắn ⇒ không nhắc; lựa chọn thử lại luôn có mặt; bỏ qua nhắc ⇒ không hiện lại cho tới **lần thua tiếp theo**
- [ ] 16.2 Run test to verify it fails
  - Reference: US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-3.1, US-3 AC-3.2, US-3 AC-3.3
  - Command: `flutter test test/ui/game_screen_reminder_test.dart`
  - Expected: FAIL vì lời nhắc chưa tồn tại.
- [ ] 16.3 Write minimal implementation
  - Reference: US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-3.1, US-3 AC-3.2, US-3 AC-3.3
  - Implementation file: `lib/ui/screens/game_screen.dart`
  - Nhắc trên overlay kết quả theo `kHintReminderAfterLosses` và `kSkipOfferAfterLosses`. Giữ `dismissedAtLossCount` **theo phiên**, không lưu xuống tiến trình. Lựa chọn thử lại không kém nổi bật hơn.
- [ ] 16.4 Run test to verify it passes
  - Reference: US-3 AC-2.1, US-3 AC-2.2, US-3 AC-2.3, US-3 AC-3.1, US-3 AC-3.2, US-3 AC-3.3
  - Command: `flutter test test/ui/game_screen_reminder_test.dart`
  - Expected: PASS.

### 17. Dấu "đã bỏ qua" trên bản đồ

- [ ] 17.1 Write the failing test
  - Reference: US-2 AC-5.1, US-2 AC-5.2, US-2 AC-5.3
  - Files: `test/ui/arena_map_skipped_test.dart`
  - Add coverage cho dấu phân biệt màn bỏ qua với màn thắng thật.
  - Test file: `test/ui/arena_map_skipped_test.dart`
  - Expected assertion: màn `skipped` ⇒ có badge chữ trên đúng item/node; màn thắng thật ⇒ không có badge; trạng thái không truyền đạt chỉ bằng màu
- [ ] 17.2 Run test to verify it fails
  - Reference: US-2 AC-5.1, US-2 AC-5.2, US-2 AC-5.3
  - Command: `flutter test test/ui/arena_map_skipped_test.dart`
  - Expected: FAIL vì item/node màn chưa có dấu.
- [ ] 17.3 Write minimal implementation
  - Reference: US-2 AC-5.1, US-2 AC-5.2, US-2 AC-5.3
  - Implementation file: `lib/ui/screens/arena_map_screen.dart`
  - Tách skipped indicator tái sử dụng và đặt trên item/node khi
    `isSkipped(arena.id)`, để Unit 3 dùng lại trong grid mà không viết lần hai.
  - **Đặt badge trong `Row`, cạnh cột sao — KHÔNG trong `Column`.** Ràng buộc từ Unit 3: nó ghim chiều cao thẻ để tính offset tự cuộn bằng số học, nên badge tốn **0** chiều cao dọc. Đặt vào `Column` làm thẻ đã-bỏ-qua cao hơn thẻ thường, tức thẻ có hai chiều cao nội tại và phép tính offset của Unit 3 sai.
- [ ] 17.4 Run test to verify it passes
  - Reference: US-2 AC-5.1, US-2 AC-5.2, US-2 AC-5.3
  - Command: `flutter test test/ui/arena_map_skipped_test.dart`
  - Expected: PASS, và test smoke sẵn có của bản đồ vẫn xanh.

### 18. Chuỗi song ngữ

- [ ] 18.1 Write the failing test
  - Reference: US-1 AC-6.3, US-2 AC-5.4, US-3 AC-3.4
  - Files: `test/l10n/arb_parity_test.dart`
  - Add coverage cho việc `app_vi.arb` và `app_en.arb` có **cùng** bộ khoá.
  - Test file: `test/l10n/arb_parity_test.dart`
  - Expected assertion: tập khoá hai file giống hệt nhau (bỏ qua khoá metadata `@`); mọi khoá mới của unit này có mặt ở cả hai
- [ ] 18.2 Run test to verify it fails
  - Reference: US-1 AC-6.3, US-2 AC-5.4, US-3 AC-3.4
  - Command: `flutter test test/l10n/arb_parity_test.dart`
  - Expected: FAIL vì các khoá mới chưa có.
- [ ] 18.3 Write minimal implementation
  - Reference: US-1 AC-6.3, US-2 AC-5.4, US-3 AC-3.4
  - Implementation file: `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`
  - Thêm 17 khoá liệt kê ở § UI Design Specification của `design.md`, VI là bản gốc. Chạy `flutter gen-l10n`.
- [ ] 18.4 Run test to verify it passes
  - Reference: US-1 AC-6.3, US-2 AC-5.4, US-3 AC-3.4
  - Command: `flutter test test/l10n/arb_parity_test.dart`
  - Expected: PASS.

### 19. Nối dây và kiểm toàn bộ

- [ ] 19.1 Nối `hintControllerProvider` vào cây provider
  - Reference: US-1 AC-1.1, US-1 AC-5.2
  - Files: `lib/state/providers.dart`, `lib/ui/screens/game_screen.dart`
  - Khai provider, gọi `onArenaLoaded(arena.id)` ở **cả ba** đường của `_load` (lần đầu, chơi lại tại `index`, sang màn tại `index + 1`).
- [ ] 19.2 Chạy toàn bộ test và phân tích tĩnh
  - Reference: US-2 AC-3.4, US-2 AC-4.3
  - Command: `flutter analyze && flutter test`
  - Expected: 0 issue; mọi test xanh, gồm 16 test sẵn có — luật mở màn và tiến trình **không** hồi quy.
- [ ] 19.3 Kiểm vòng lưu–đọc đầu-cuối
  - Reference: US-2 AC-4.1, US-3 AC-1.3
  - Files: `test/data/progress_roundtrip_test.dart`
  - Bỏ qua một màn, thua vài lần ở màn khác, serialize rồi deserialize qua `SharedPreferences` mock: dấu bỏ qua, bộ đếm thua và số dư xu phải còn nguyên; và một save **kiểu cũ** vẫn đọc được không mất gì.

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
