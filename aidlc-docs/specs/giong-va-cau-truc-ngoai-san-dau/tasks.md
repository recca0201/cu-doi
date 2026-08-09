---
artifact_type: tasks
phase: construction
status: draft
created: 2026-08-05
updated: 2026-08-09
unit: giong-va-cau-truc-ngoai-san-dau
source_artifacts:
  - aidlc-docs/specs/giong-va-cau-truc-ngoai-san-dau/requirements.md
  - aidlc-docs/specs/giong-va-cau-truc-ngoai-san-dau/design.md
  - aidlc-docs/foundation/uiux-guideline.md
---

# Tasks: Giọng và cấu trúc ngoài sân đấu

Thứ tự: luật miền thuần Dart trước (test được không cần widget), rồi dựng component
grid theo design mới, lắp bản đồ, rồi thoại, cuối cùng nối dây và kiểm.

**Nguồn design hiện hành**: `Cu_Doi_UI_UX_Design_Spec.docx` và
`aidlc-docs/foundation/uiux-guideline.md`. `C:\repos\ban_bua` chỉ còn là nguồn
tham khảo primitive; **không port composition đường mòn**.

**Phụ thuộc Unit 1**: task 6 (dấu đã bỏ qua trên node), task 10 (`targetArenaId` +
`pushReplacement`), task 11 (`showGuide` đọc seen-set), và ràng buộc badge của Unit 1. Nếu Unit 1 chưa làm, các task đó **chặn** — không tự viết lại phần của Unit 1.

**Hạ tầng test còn thiếu**: `test/` hiện chỉ có `app_smoke_test.dart` và `shot_runner_test.dart`.
Pump bất kỳ màn nào cần override `sharedPreferencesProvider` (`providers.dart:12` throw nếu
không) — task 1 dựng harness đó trước, mọi task widget sau đều dùng.

## Implementation Checklist

### 1. Harness test widget

- [ ] 1.1 Write the failing test
  - Reference: US-1 AC-2.3
  - Files: `test/support/pump_app.dart`, `test/ui/arena_map_smoke_test.dart`
  - Add coverage cho việc pump được `ArenaMapScreen` với tiến trình dựng sẵn.
  - Test file: `test/ui/arena_map_smoke_test.dart`
  - Expected assertion: pump `ArenaMapScreen` với `PlayerProgress` có `completedMax == 3` ⇒ dựng được, không throw; luật mở màn tuyến tính **không đổi** (`isUnlocked(4) == true`, `isUnlocked(5) == false`)
- [ ] 1.2 Run test to verify it fails
  - Reference: US-1 AC-2.3
  - Command: `flutter test test/ui/arena_map_smoke_test.dart`
  - Expected: FAIL vì `pumpApp` helper chưa tồn tại — **không** phải vì `sharedPreferencesProvider` throw.
- [ ] 1.3 Write minimal implementation
  - Reference: US-1 AC-2.3
  - Implementation file: `test/support/pump_app.dart`
  - Helper nhận `PlayerProgress` và `AppSettings`, override `sharedPreferencesProvider` bằng `SharedPreferences.setMockInitialValues({})`, bọc `MaterialApp` + `AppLocalizations.delegate`. Đây là hạ tầng cho **mọi** task widget sau.
- [ ] 1.4 Run test to verify it passes
  - Reference: US-1 AC-2.3
  - Command: `flutter test test/ui/arena_map_smoke_test.dart`
  - Expected: PASS.

### 2. Định nghĩa chương thuần

- [ ] 2.1 Write the failing test
  - Reference: US-1 AC-1.1, US-1 AC-1.3, US-1 AC-1.4, US-1 AC-1.5
  - Files: `test/domain/chapters_test.dart`
  - Add coverage cho bảng khoảng `kChapters`, tra cứu có kẹp, và màn ngoài mọi chương.
  - Test file: `test/domain/chapters_test.dart`
  - Expected assertion: 20 màn chia đúng 4 chương 5 màn; `chapterOf` đúng ở biên
    (1, 5, 6, 20); `chapterOf(99)` trả `null`; model không chứa màu/token UI.
- [ ] 2.2 Run test to verify it fails
  - Reference: US-1 AC-1.1, US-1 AC-1.3, US-1 AC-1.4, US-1 AC-1.5
  - Command: `flutter test test/domain/chapters_test.dart`
  - Expected: FAIL vì `lib/domain/chapters.dart` chưa tồn tại.
- [ ] 2.3 Write minimal implementation
  - Reference: US-1 AC-1.1, US-1 AC-1.3, US-1 AC-1.4, US-1 AC-1.5
  - Implementation file: `lib/domain/chapters.dart`
  - `Chapter(number, firstLevelId, lastLevelId)` — thuần, không import l10n/UI.
    `kChapters` là bảng khoảng; không thêm field vào `ArenaSpec` và không mang
    accent/season/boss từ game cũ.
- [ ] 2.4 Run test to verify it passes
  - Reference: US-1 AC-1.1, US-1 AC-1.3, US-1 AC-1.4, US-1 AC-1.5
  - Command: `flutter test test/domain/chapters_test.dart`
  - Expected: PASS.

### 3. Tiến độ sao theo chương

- [ ] 3.1 Write the failing test
  - Reference: US-2 AC-1.1, US-2 AC-1.2, US-2 AC-1.4, US-2 AC-1.5, US-2 AC-2.1, US-2 AC-2.3
  - Files: `test/domain/chapters_test.dart`
  - Add coverage cho `chapterMaxStars` và `chapterEarnedStars`.
  - Test file: `test/domain/chapters_test.dart`
  - Expected assertion: `chapterMaxStars` **tính** từ khoảng (5×3 = 15), **không** viết cứng 15; chương chưa có sao ⇒ `0`; màn **đã bỏ qua** góp **0 sao** dù được tính là đã mở (khớp Unit 1); tiến trình rỗng ⇒ mọi chương `0`, không throw; tổng sao 4 chương == `totalStars`; **không** phép ghi nào lên `PlayerProgress` được gọi
- [ ] 3.2 Run test to verify it fails
  - Reference: US-2 AC-1.1, US-2 AC-1.2, US-2 AC-1.4, US-2 AC-1.5, US-2 AC-2.1, US-2 AC-2.3
  - Command: `flutter test test/domain/chapters_test.dart`
  - Expected: FAIL vì hai hàm chưa có.
- [ ] 3.3 Write minimal implementation
  - Reference: US-2 AC-1.1, US-2 AC-1.2, US-2 AC-1.4, US-2 AC-1.5, US-2 AC-2.1, US-2 AC-2.3
  - Implementation file: `lib/domain/chapters.dart`
  - `chapterMaxStars` = `(lastLevelId - firstLevelId + 1) * 3`. `chapterEarnedStars` cộng `starsFor` — **chỉ đọc**, và không cần biết gì về `skipped` vì màn bỏ qua có `stars == 0`.
- [ ] 3.4 Run test to verify it passes
  - Reference: US-2 AC-1.1, US-2 AC-1.2, US-2 AC-1.4, US-2 AC-1.5, US-2 AC-2.1, US-2 AC-2.3
  - Command: `flutter test test/domain/chapters_test.dart`
  - Expected: PASS.

### 4. Màn đích của tự cuộn

- [ ] 4.1 Write the failing test
  - Reference: US-3 AC-1.1, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-2.2
  - Files: `test/domain/target_level_test.dart`
  - Add coverage cho `targetLevelId`.
  - Test file: `test/domain/target_level_test.dart`
  - Expected assertion: người chơi mới ⇒ `null`; hoàn thành cả 20 màn ⇒ `null`; `completedMax == 7` ⇒ `8`; màn **đã bỏ qua** tính là đã xong nên đích là màn **sau** nó; `completedMax` trỏ ra ngoài `kArenas` ⇒ `null`; `requestedArenaId` hợp lệ ⇒ **ưu tiên** nó trên luật suy ra; `requestedArenaId` không có trong `kArenas` ⇒ bỏ qua, rơi về luật suy ra
- [ ] 4.2 Run test to verify it fails
  - Reference: US-3 AC-1.1, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-2.2
  - Command: `flutter test test/domain/target_level_test.dart`
  - Expected: FAIL vì `targetLevelId` chưa có.
- [ ] 4.3 Write minimal implementation
  - Reference: US-3 AC-1.1, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-2.2
  - Implementation file: `lib/domain/chapters.dart`
  - Đặt ở `lib/domain/`, không ở `map_sections.dart`: đây là luật suy ra thuần từ
    tiến trình, không có layout. Dùng `completedMax + 1` theo định nghĩa sau Unit 1.
- [ ] 4.4 Run test to verify it passes
  - Reference: US-3 AC-1.1, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-2.2
  - Command: `flutter test test/domain/target_level_test.dart`
  - Expected: PASS.

### 5. Token và shell tối cho màn chọn màn

- [ ] 5.1 Viết golden/widget test cho shell 390 × 844: nền `nightIndigo`, header
  `panelNavy`, Back / “CHỌN MÀN” / tổng sao; không có `sky`, cream card hoặc coral
  CTA từ composition cũ.
- [ ] 5.2 Thêm/ánh xạ token ngữ nghĩa theo `uiux-guideline.md`; không viết hex
  trong widget và không sửa `lib/sim/`.
- [ ] 5.3 Chạy test ở phone, tablet và text scale 2.0; kiểm không overflow.

### 6. Node level dạng grid

- [ ] 6.1 Viết test cho năm trạng thái `locked`, `unlocked`, `current`,
  `completed`, `skipped`; mỗi node có hit target ≥48dp và một semantic label đầy đủ.
- [ ] 6.2 Dựng node tròn/bo tròn với số ở giữa, 0–3 sao, lock icon, gold
  outline/glow cho current và badge/icon chữ cho skipped. Không dùng màu đơn độc.
- [ ] 6.3 Giữ extent node ổn định giữa các state để grid không nhảy.

### 7. Section chapter và grid 4 cột

- [ ] 7.1 Viết test: 4 header, mỗi header có `earned/max`; mỗi chapter có đúng
  5 node theo `levelId`; chapter sau không lấp ô trống của chapter trước.
- [ ] 7.2 Dùng một `CustomScrollView`/sliver tree; mỗi section có header và
  `SliverGrid` 4 cột. Không dùng scroll lồng, `ChapterTrail` hoặc `TrailPainter`.
- [ ] 7.3 Nhóm dự phòng cho arena ngoài `kChapters` vẫn hiện sau chương 4.

### 8. Tự định vị theo section/grid

- [ ] 8.1 Viết test offset cho màn 1, 8 và 20; offset gồm extent header, grid
  row và khoảng section thật, được clamp và áp trước khung đầu.
- [ ] 8.2 `targetArenaId` hợp lệ thắng luật suy ra; giá trị lạ rơi về
  `targetLevelId`; người mới/đã xong mở đầu danh sách.
- [ ] 8.3 Không gọi `animateTo` khi mở; sau khi người chơi cuộn tay, locale/text
  scale đổi không tự đưa họ về đích.

### 9. Visual QA màn chọn màn

- [ ] 9.1 Golden 390 × 844 phải khớp hierarchy của hình tham chiếu nhưng dùng
  đúng 4 chapter, không gắn cả 20 màn vào “Chương 1”.
- [ ] 9.2 Kiểm current/locked/completed/skipped, tên chapter VI/EN, tổng sao,
  snackbar màn khoá và route tới màn mở.
- [ ] 9.3 Chạy `flutter test` và `flutter analyze`; kiểm mắt golden trước khi kết luận.

### 10. Điểm giao Unit 1 — định vị sau khi bỏ qua màn

- [ ] 10.1 Write the failing test
  - Reference: US-3 AC-2.2
  - Files: `test/ui/arena_map_autoscroll_test.dart`
  - Add coverage cho `targetArenaId` **và** cho đường điều hướng của Unit 1.
  - Test file: `test/ui/arena_map_autoscroll_test.dart`
  - Expected assertion: mở với `targetArenaId` khác `completedMax + 1` ⇒ cuộn tới `targetArenaId`; `targetArenaId` không có trong `kArenas` ⇒ rơi về luật suy ra, không throw; **và** đường bỏ qua màn của Unit 1 dùng `pushReplacement` một `ArenaMapScreen` mới — test chỉ pump màn với tham số sẽ **xanh dù tính năng chết trong app**
- [ ] 10.2 Run test to verify it fails
  - Reference: US-3 AC-2.2
  - Command: `flutter test test/ui/arena_map_autoscroll_test.dart`
  - Expected: FAIL vì `ArenaMapScreen` chưa nhận `targetArenaId`.
- [ ] 10.3 Write minimal implementation
  - Reference: US-3 AC-2.2
  - Implementation file: `lib/ui/screens/arena_map_screen.dart`, `lib/ui/screens/game_screen.dart`
  - `ArenaMapScreen({this.targetArenaId})`, ưu tiên nó trong `targetLevelId`. Và đổi đường bỏ qua màn của Unit 1 từ `pop()` sang `pushReplacement` — `pop` về instance cũ **không** chạy lại `initState` nên `initialScrollOffset` không bao giờ kích. Đường "về menu" thường **vẫn** `pop`.
  - **Chặn nếu Unit 1 chưa làm**: đường bỏ qua màn thuộc Unit 1. Không tự viết lại nó.
- [ ] 10.4 Run test to verify it passes
  - Reference: US-3 AC-2.2
  - Command: `flutter test test/ui/arena_map_autoscroll_test.dart`
  - Expected: PASS.

### 11. Trạng thái "đã xem thoại"

- [ ] 11.1 Write the failing test
  - Reference: US-4 AC-3.3, US-4 AC-3.4
  - Files: `test/data/dialogue_seen_test.dart`
  - Add coverage cho repository và controller.
  - Test file: `test/data/dialogue_seen_test.dart`
  - Expected assertion: lưu rồi đọc round-trip; khoá là `dialogue_seen_v1`, **không** phải `progress_v1`; save lỗi ⇒ trả `false`, **không** throw; tên enum lạ trong payload bị bỏ qua chứ không nổ; save cũ không có khoá ⇒ tập rỗng, mọi đoạn coi như chưa xem
- [ ] 11.2 Run test to verify it fails
  - Reference: US-4 AC-3.3, US-4 AC-3.4
  - Command: `flutter test test/data/dialogue_seen_test.dart`
  - Expected: FAIL vì `dialogue_seen_repository.dart` chưa tồn tại.
- [ ] 11.3 Write minimal implementation
  - Reference: US-4 AC-3.3, US-4 AC-3.4
  - Implementation file: `lib/data/dialogue_seen_repository.dart`, `lib/state/providers.dart`
  - Khoá **riêng** `dialogue_seen_v1` — Unit 1 đã đổi schema `progress_v1` một lần, thêm nữa là lần thứ ba trên cùng payload. `save` trả `Future<bool>` theo hợp đồng Unit 1 đã lập. `DialogueSeenController` theo hình dạng **restore-rồi-notify** của `ProgressController` (`providers.dart:51-66`) — **không** phải `SettingsController`, vốn seed đồng bộ trong constructor.
- [ ] 11.4 Run test to verify it passes
  - Reference: US-4 AC-3.3, US-4 AC-3.4
  - Command: `flutter test test/data/dialogue_seen_test.dart`
  - Expected: PASS.

### 12. Nhân vật và lời thoại song ngữ

- [ ] 12.1 Write the failing test
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-1.4, US-4 AC-4.1
  - Files: `test/domain/character_test.dart`
  - Add coverage cho model nhân vật và bảng thoại.
  - Test file: `test/domain/character_test.dart`
  - Expected assertion: mọi `DialogueId` có resolver sang getter ARB; tên/thoại
    VI và EN không rỗng hoặc chứa placeholder; đổi khoá ARB làm vỡ compile;
    `lib/domain/character.dart` không import Flutter/l10n và không chứa text.
- [ ] 12.2 Run test to verify it fails
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-1.4, US-4 AC-4.1
  - Command: `flutter test test/domain/character_test.dart`
  - Expected: FAIL vì `character.dart` chưa tồn tại.
- [ ] 12.3 Write minimal implementation
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-1.4, US-4 AC-4.1
  - Implementation file: `lib/domain/character.dart`
  - `DialogueId { intro, levelWin, levelLose, levelLoseShort, finalVictory }` và
    `DialogueSpec(id, onceOnly)` giữ thuần trong domain. Mọi text, kể cả tên nhân
    vật và thoại, đi qua getter ARB bằng resolver top-level trong
    `lib/ui/localized_text.dart`; domain không import l10n.
- [ ] 12.4 Run test to verify it passes
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-1.4, US-4 AC-4.1
  - Command: `flutter test test/domain/character_test.dart`
  - Expected: PASS.

### 13. Component thoại duy nhất

- [ ] 13.1 Write the failing test
  - Reference: US-4 AC-3.2, US-4 AC-4.2, US-4 AC-4.3
  - Files: `test/ui/character_dialogue_test.dart`
  - Add coverage cho component thoại.
  - Test file: `test/ui/character_dialogue_test.dart`
  - Expected assertion: modal đóng trong một chạm bằng CTA gold ≥48dp; embedded
    không có scrim/CTA gold cạnh tranh với result. Cả hai không tự đóng, semantics
    đọc tên + lời, text scale 2.0 không overflow; reduced motion chỉ tắt animation.
- [ ] 13.2 Run test to verify it fails
  - Reference: US-4 AC-3.2, US-4 AC-4.2, US-4 AC-4.3
  - Command: `flutter test test/ui/character_dialogue_test.dart`
  - Expected: FAIL vì component chưa tồn tại.
- [ ] 13.3 Write minimal implementation
  - Reference: US-4 AC-3.2, US-4 AC-4.2, US-4 AC-4.3
  - Implementation file: `lib/ui/character_dialogue.dart`
  - Một component với `modal` và `embedded` presentation. Modal dùng scrim 70–80%,
    chặn chạm xuyên, scroll, maxWidth 420, panel navy và CTA gold. Embedded dùng
    cùng nội dung/panel primitive nhưng không scrim hoặc CTA gold riêng. Không port
    card cream/coral.
  - **Sao nguyên khối `Semantics` ở `:1999-2006` kèm comment** — comment ghi rằng bỏ `explicitChildNodes` làm framework assert và hiện màn đỏ. Đó là loại tri thức mất đi thì phải học lại bằng một lần vỡ.
- [ ] 13.4 Run test to verify it passes
  - Reference: US-4 AC-3.2, US-4 AC-4.2, US-4 AC-4.3
  - Command: `flutter test test/ui/character_dialogue_test.dart`
  - Expected: PASS.

### 14. Thoại giới thiệu trong overlay hướng dẫn

- [ ] 14.1 Write the failing test
  - Reference: US-4 AC-2.1, US-4 AC-3.1, US-4 AC-3.5
  - Files: `test/ui/game_screen_dialogue_test.dart`
  - Add coverage cho thoại giới thiệu và cổng "lần đầu".
  - Test file: `test/ui/game_screen_dialogue_test.dart`
  - Expected assertion: thoại giới thiệu hiện **trong `_guide()`** (overlay hướng dẫn hiện có), không phải ở menu; bi đang bay ⇒ **không** thoại nào hiện; thoại **không** che tín hiệu `armed` (nó không cùng tồn tại với lúc chơi thật); **trong lúc seen-set còn restore** ⇒ `showGuide` là `false`; đã xem `intro` ⇒ không hiện lại
- [ ] 14.2 Run test to verify it fails
  - Reference: US-4 AC-2.1, US-4 AC-3.1, US-4 AC-3.5
  - Command: `flutter test test/ui/game_screen_dialogue_test.dart`
  - Expected: FAIL vì `_guide()` còn là chữ không có giọng.
- [ ] 14.3 Write minimal implementation
  - Reference: US-4 AC-2.1, US-4 AC-3.1, US-4 AC-3.5
  - Implementation file: `lib/ui/screens/game_screen.dart`, `lib/ui/screens/menu_screen.dart`
  - Thêm thoại vào `_guide()` (`game_screen.dart:382-420`) — nó **đã có** `SingleChildScrollView` (`:386`) nên không gây overflow, và `_fire` return sớm khi `_guideVisible` (`:203`) nên nó không cùng tồn tại với bi đang bay.
  - `showGuide` đọc `!hasSeen(DialogueId.intro)` thay cho `fresh = progress.results.isEmpty` (`menu_screen.dart:34`) — sau Unit 1, **một lần thua** cũng sinh `LevelResult` nên `fresh` thành `false` và người thua ngay lần đầu **mất luôn** phần hướng dẫn. `markSeen(intro)` gọi ở handler `gotItCta` (`:414`).
- [ ] 14.4 Run test to verify it passes
  - Reference: US-4 AC-2.1, US-4 AC-3.1, US-4 AC-3.5
  - Command: `flutter test test/ui/game_screen_dialogue_test.dart`
  - Expected: PASS.

### 15. Thoại kết màn và kết chiến dịch

- [ ] 15.1 Write the failing test
  - Reference: US-4 AC-2.2, US-4 AC-2.3, US-4 AC-2.4
  - Files: `test/ui/game_screen_dialogue_test.dart`
  - Add coverage cho thoại trên overlay kết quả và thứ tự dọc.
  - Test file: `test/ui/game_screen_dialogue_test.dart`
  - Expected assertion: thắng ⇒ thoại phù hợp; thua ⇒ thoại phù hợp; thắng **màn 20** ⇒ thoại kết chiến dịch, `onceOnly`; thứ tự dọc là kết quả → **thoại** → lời nhắc Unit 1 → thử lại → màn kế/về bản đồ; khi `lossesFor >= kSkipOfferAfterLosses` ⇒ dùng `levelLoseShort`, đọc **cùng** hằng số với Unit 1 chứ không viết cứng 3
- [ ] 15.2 Run test to verify it fails
  - Reference: US-4 AC-2.2, US-4 AC-2.3, US-4 AC-2.4
  - Command: `flutter test test/ui/game_screen_dialogue_test.dart`
  - Expected: FAIL vì overlay kết quả chưa có thoại.
- [ ] 15.3 Write minimal implementation
  - Reference: US-4 AC-2.2, US-4 AC-2.3, US-4 AC-2.4
  - Implementation file: `lib/ui/screens/game_screen.dart`
  - Chèn thoại trước primary action gold trong `_result()`. Bọc `_result()` trong
    `SingleChildScrollView`; ở lần thua thứ 3 cột có thể chứa 7 phần tử và phải
    không overflow ở text scale 2.0.
- [ ] 15.4 Run test to verify it passes
  - Reference: US-4 AC-2.2, US-4 AC-2.3, US-4 AC-2.4
  - Command: `flutter test test/ui/game_screen_dialogue_test.dart`
  - Expected: PASS.
- [ ] 15.5 Chốt overlay kết quả không overflow
  - Reference: US-4 AC-2.4
  - Files: `test/ui/game_screen_dialogue_test.dart`
  - Thêm test: ở `TextScaler.linear(2.0)` với thoại + **cả hai** lời nhắc Unit 1 + thử lại + về menu ⇒ `takeException()` là `null`. Đây là ca chật nhất của unit.

### 16. Chuỗi song ngữ

- [ ] 16.1 Write the failing test
  - Reference: US-1 AC-4.1, US-4 AC-4.1
  - Files: `test/l10n/arb_parity_test.dart`
  - Add coverage cho khoá ARB mới và cho việc không còn chuỗi giữ chỗ.
  - Test file: `test/l10n/arb_parity_test.dart`
  - Expected assertion: hai ARB có cùng bộ khoá; có `characterName`,
    `chapter1Title`..`chapter4Title`, `chapterOtherTitle`, `chapterProgressLabel`,
    `currentLevelBadge`, `dialogueIntro`, `dialogueWin`, `dialogueLose`,
    `dialogueLoseShort`, `dialogueFinalVictory`; không giá trị rỗng/placeholder.
- [ ] 16.2 Run test to verify it fails
  - Reference: US-1 AC-4.1, US-4 AC-4.1
  - Command: `flutter test test/l10n/arb_parity_test.dart`
  - Expected: FAIL vì các khoá chưa có.
- [ ] 16.3 Write minimal implementation
  - Reference: US-1 AC-4.1, US-4 AC-4.1
  - Implementation file: `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`, `lib/ui/localized_text.dart`
  - Thêm mọi khoá chapter/character/dialogue vào cả hai file, VI là bản gốc; chạy
    `flutter gen-l10n`. `localized_text.dart` giữ resolver top-level cho chapter,
    character và `DialogueId`; domain không import l10n.
- [ ] 16.4 Run test to verify it passes
  - Reference: US-1 AC-4.1, US-4 AC-4.1
  - Command: `flutter test test/l10n/arb_parity_test.dart`
  - Expected: PASS.

### 17. Nối dây và kiểm toàn bộ

- [ ] 17.1 Chốt ranh giới không bị phá
  - Reference: US-1 AC-2.3, US-2 AC-2.3
  - Files: `test/boundary_test.dart`
  - Task **chỉ có test**: `lib/sim/` không file nào import `package:flutter`; `ArenaSpec` **không** có field chương; unit này **không** gọi phép ghi nào lên `PlayerProgress`; `lib/domain/` không import `lib/l10n/`; luật mở màn tuyến tính giữ đúng giá trị hiện tại.
  - Validate với `flutter test test/boundary_test.dart`
- [ ] 17.2 Chạy toàn bộ test và phân tích tĩnh
  - Reference: US-2 AC-2.2, US-3 AC-1.4
  - Command: `flutter analyze && flutter test`
  - Expected: 0 issue; mọi test xanh gồm 16 test sẵn có. Thắng lại một màn đã bỏ qua ⇒ sao mới cộng vào tiến độ chương (AC US-2/2.2) phải có test trong `chapters_test.dart`.
- [ ] 17.3 Kiểm trên máy ảo
  - Reference: US-1 AC-3.1, US-3 AC-1.1
  - Command: `flutter build apk --release --target-platform android-x64`
  - Cài và mở màn chọn màn: 4 chương có tiêu đề và tiến độ, grid 4 cột nền navy,
    node current/locked/completed/skipped đúng state, tự định vị tới chỗ đang chơi.
    Chụp ảnh ở 390 × 844 và đối chiếu hierarchy với hình trong
    `Cu_Doi_UI_UX_Design_Spec.docx`; không đối chiếu composition đường mòn của
    `ban_bua`. **Lưu ý**: dùng release build — debug APK 155 MB không cài được vì
    `/data` máy ảo chật; release ~19 MB.

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
