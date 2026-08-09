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

> **Supersession 2026-08-09**: Task 5–12 bên dưới mô tả phương án đường mòn cũ và
> được giữ như lịch sử. Không triển khai chúng. Thực hiện task **12A–12E** thay thế.

**Phụ thuộc Unit 1**: task 6 (dấu đã bỏ qua trên node), task 13 (`targetArenaId` +
`pushReplacement`), task 14 (`showGuide` đọc seen-set), và ràng buộc badge đặt ngang ở Unit 1
task 17.3. Nếu Unit 1 chưa làm, các task đó **chặn** — không tự viết lại phần của Unit 1.

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

### 2. Định nghĩa chương và accent

- [ ] 2.1 Write the failing test
  - Reference: US-1 AC-1.1, US-1 AC-1.3, US-1 AC-1.4, US-1 AC-1.5
  - Files: `test/domain/chapters_test.dart`
  - Add coverage cho bảng khoảng `kChapters`, tra cứu có kẹp, và màn ngoài mọi chương.
  - Test file: `test/domain/chapters_test.dart`
  - Expected assertion: 20 màn chia đúng 4 chương 5 màn; `chapterOf` đúng ở biên (1, 5, 6, 20); `chapterOf(99)` trả `null`; mỗi `Chapter` có `accent` khác nhau; tra cứu chương ngoài phạm vi **kẹp** về hai đầu chứ không throw (ý mượn `bb_chapter_theme.dart:94-95`)
- [ ] 2.2 Run test to verify it fails
  - Reference: US-1 AC-1.1, US-1 AC-1.3, US-1 AC-1.4, US-1 AC-1.5
  - Command: `flutter test test/domain/chapters_test.dart`
  - Expected: FAIL vì `lib/domain/chapters.dart` chưa tồn tại.
- [ ] 2.3 Write minimal implementation
  - Reference: US-1 AC-1.1, US-1 AC-1.3, US-1 AC-1.4, US-1 AC-1.5
  - Implementation file: `lib/domain/chapters.dart`
  - `Chapter(number, firstLevelId, lastLevelId, accent)` — **thuần**, không import l10n. `kChapters` là bảng khoảng, **không** thêm field vào `ArenaSpec` (nó ở `lib/sim/`, không được mang thông tin trình bày). `accent` lấy từ `BbTokens` sẵn có, mỗi chương một màu, theo hình dạng `BbChapterTheme` bản cũ nhưng **không** port `LevelSeason` hay `boss`.
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
  - Đặt ở `lib/domain/` chứ **không** ở `map_items.dart` — nó là luật suy ra thuần từ tiến trình, không có nội dung layout. Dùng `completedMax + 1` theo định nghĩa **sau Unit 1** (`stars >= 1 || skipped`).
- [ ] 4.4 Run test to verify it passes
  - Reference: US-3 AC-1.1, US-3 AC-1.2, US-3 AC-1.3, US-3 AC-2.2
  - Command: `flutter test test/domain/target_level_test.dart`
  - Expected: PASS.

### 5. [SUPERSEDED — KHÔNG LÀM] Số học offset đường mòn

- [ ] 5.1 Write the failing test
  - Reference: US-3 AC-1.1, US-3 AC-2.1
  - Files: `test/ui/map_offset_test.dart`
  - Add coverage cho `initialOffsetFor` — mọi số hạng là **hằng số pixel**, không suy từ metric chữ.
  - Test file: `test/ui/map_offset_test.dart`
  - Expected assertion: màn 1 ⇒ `max(0, sp5 + kChapterHeaderHeight + sp4 + 0 - sp9)`; màn 8 (chương 2, index 2) ⇒ khớp tổng tính tay gồm **cả** chương 1 đầy đủ cộng `sp7` giữa hai chương; kết quả **luôn `>= 0`**; kết quả **kẹp trên** theo `maxScrollExtent` truyền vào; và **quan trọng nhất** — gọi lại với `TextScaler.linear(2.0)` cho **cùng một** con số
- [ ] 5.2 Run test to verify it fails
  - Reference: US-3 AC-1.1, US-3 AC-2.1
  - Command: `flutter test test/ui/map_offset_test.dart`
  - Expected: FAIL vì `lib/ui/map_items.dart` chưa tồn tại.
- [ ] 5.3 Write minimal implementation
  - Reference: US-3 AC-1.1, US-3 AC-2.1
  - Implementation file: `lib/ui/map_items.dart`
  - Port số học từ `level_map_screen.dart:182-204` của bản cũ: `sp5` + Σ(`header` + `sp4` + `n×slot` + `sp7`) + `header` + `sp4` + `targetIndex×slot` − `sp9`. Hằng số: `kChapterHeaderHeight = 40.0` (**không** 32.0 của bản cũ — xem task 7) và `kTrailSlot = 108.0`. **Thêm clamp trên** theo `maxScrollExtent`, thứ bản cũ thiếu.
  - **Không** dùng `TextScaler`, **không** `MapExtents`, **không** đọc `MediaQuery` — bất biến theo cỡ chữ là điều kiện chấp nhận, không phải hệ quả tình cờ.
- [ ] 5.4 Run test to verify it passes
  - Reference: US-3 AC-1.1, US-3 AC-2.1
  - Command: `flutter test test/ui/map_offset_test.dart`
  - Expected: PASS — kể cả assertion bất biến theo scale.

### 6. [SUPERSEDED — KHÔNG LÀM] Node đường mòn theo trạng thái

- [ ] 6.1 Write the failing test
  - Reference: US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.5
  - Files: `test/ui/level_node_test.dart`
  - Add coverage cho ba trạng thái node và dấu "đã bỏ qua" của Unit 1.
  - Test file: `test/ui/level_node_test.dart`
  - Expected assertion: `locked` ⇒ nền `ink300`, icon `BbIcons.lock`, **không** hiện sao; `unlocked` ⇒ nền `bbCoral`, hiện số màn bằng `BbText.h2`, **không** hiện sao; `completed` ⇒ nền `bbTeal`, hiện 3 icon sao `starFill`/`starOutline`; **cả ba** trạng thái chiếm **cùng** chiều cao (hàng sao là `SizedBox(height: 16)` cố định, vẽ hay không vẽ đều giữ chỗ); màn đã bỏ qua ⇒ badge nằm **ngang** cạnh node, không làm node cao thêm
- [ ] 6.2 Run test to verify it fails
  - Reference: US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.5
  - Command: `flutter test test/ui/level_node_test.dart`
  - Expected: FAIL vì `BbLevelButton` chưa tồn tại trong repo này.
- [ ] 6.3 Write minimal implementation
  - Reference: US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.5
  - Implementation file: `lib/ui/widgets/bb_game_widgets.dart`
  - Port `LevelNodeState` + `BbLevelButton` từ `bb_game_widgets.dart:303-417` của bản cũ. **Bỏ** tham số `boss` và nhánh `crown` — game này không có boss. Giữ vòng tròn 68×68, `Border.all(ink900, bd3)`, `BbTokens.sticker(stickerMd)`, và hàng sao `SizedBox(height: 16)` cố định — đó là thứ giữ bước nhảy `slot` không đổi.
  - **Không** port `BubbleFaceWidget`/`BbMascotWidget` cùng file — chúng cần `bubble_painter.dart` và là mascot bong bóng, không dùng ở đây.
- [ ] 6.4 Run test to verify it passes
  - Reference: US-1 AC-2.1, US-1 AC-2.2, US-1 AC-2.5
  - Command: `flutter test test/ui/level_node_test.dart`
  - Expected: PASS.

### 7. [SUPERSEDED — KHÔNG LÀM] Tiêu đề chương kiểu đường mòn

- [ ] 7.1 Write the failing test
  - Reference: US-1 AC-1.2, US-1 AC-3.3, US-1 AC-3.4, US-2 AC-1.3
  - Files: `test/ui/chapter_header_test.dart`
  - Add coverage cho composition header và cho việc nó **không overflow** ở cỡ chữ lớn.
  - Test file: `test/ui/chapter_header_test.dart`
  - Expected assertion: header gồm `BbBadge` tiêu đề màu accent chương, một thanh kẻ `bd3` accent alpha 0.35, icon `starFill`, và `n/15`; ở `TextScaler.linear(1.0)` **và** `TextScaler.linear(2.0)` ⇒ `tester.takeException()` là `null` (đây là bug bản cũ mắc: `32.0` overflow badge từ scale ~1.05); chiều cao render **đúng** `kChapterHeaderHeight` ở cả hai scale; `Semantics` phát **một** nhãn thành câu gồm số chương + tên + tiến độ, kèm `ExcludeSemantics` quanh nội dung
- [ ] 7.2 Run test to verify it fails
  - Reference: US-1 AC-1.2, US-1 AC-3.3, US-1 AC-3.4, US-2 AC-1.3
  - Command: `flutter test test/ui/chapter_header_test.dart`
  - Expected: FAIL vì header chưa tồn tại.
- [ ] 7.3 Write minimal implementation
  - Reference: US-1 AC-1.2, US-1 AC-3.3, US-1 AC-3.4, US-2 AC-1.3
  - Implementation file: `lib/ui/widgets/chapter_header.dart`
  - Port composition từ `level_map_screen.dart:282-315`. Nhưng **`kChapterHeaderHeight = 40.0`**, không 32.0, và bọc `BbBadge` trong `FittedBox(fit: BoxFit.scaleDown)`. Lý do: `BbBadge` cao nội tại ≈ 30.4 ở scale 1.0 (`BbText.tiny` **không khai** `height` nên dòng ≈ 16.4 theo metric font) — 32.0 chỉ dư 1.6px và overflow ngay ở scale 1.05.
- [ ] 7.4 Run test to verify it passes
  - Reference: US-1 AC-1.2, US-1 AC-3.3, US-1 AC-3.4, US-2 AC-1.3
  - Command: `flutter test test/ui/chapter_header_test.dart`
  - Expected: PASS ở **cả hai** mức scale.

### 8. [SUPERSEDED — KHÔNG LÀM] Đường mòn uốn lượn

- [ ] 8.1 Write the failing test
  - Reference: US-1 AC-1.3, US-1 AC-3.1, US-1 AC-3.2
  - Files: `test/ui/chapter_trail_test.dart`
  - Add coverage cho hình học node và chiều cao trail.
  - Test file: `test/ui/chapter_trail_test.dart`
  - Expected assertion: 5 node đặt theo `sin(i·π/2)` — chu kỳ giữa → phải → giữa → trái; `dy` của node thứ `i` là `slot/2 + i*slot`; chiều cao trail đúng `slot * levels.length`, **không đổi** theo cỡ chữ; thứ tự node **tăng** theo `levelId`; bề rộng nội dung tôn trọng `BbTokens.contentMaxWidth`; chỉ **một** vùng cuộn, không cuộn lồng
- [ ] 8.2 Run test to verify it fails
  - Reference: US-1 AC-1.3, US-1 AC-3.1, US-1 AC-3.2
  - Command: `flutter test test/ui/chapter_trail_test.dart`
  - Expected: FAIL vì `_ChapterTrail` chưa tồn tại.
- [ ] 8.3 Write minimal implementation
  - Reference: US-1 AC-1.3, US-1 AC-3.1, US-1 AC-3.2
  - Implementation file: `lib/ui/widgets/chapter_trail.dart`
  - Port hình học từ `level_map_screen.dart:340-376`: `amplitude = ((width - node) / 2) * 0.74`, `centers[i] = Offset(width/2 + amplitude*sin(i*pi/2), slot/2 + i*slot)`, `Stack(clipBehavior: Clip.none)` với mỗi node `Positioned`. `Clip.none` là **cần thiết** — node vẽ rộng hơn hộp `Positioned` và badge "next up" treo phía trên nó.
- [ ] 8.4 Run test to verify it passes
  - Reference: US-1 AC-1.3, US-1 AC-3.1, US-1 AC-3.2
  - Command: `flutter test test/ui/chapter_trail_test.dart`
  - Expected: PASS.

### 9. [SUPERSEDED — KHÔNG LÀM] Đường nối đứt nét

- [ ] 9.1 Write the failing test
  - Reference: US-1 AC-1.3
  - Files: `test/ui/trail_painter_test.dart`
  - Add coverage golden cho đường mòn đứt nét vẽ **phía sau** node.
  - Test file: `test/ui/trail_painter_test.dart`
  - Expected assertion: golden khớp với 5 node và đường cubic đứt nét màu accent chương; `centers.length < 2` ⇒ **không** vẽ gì và không throw; đường vẽ **dưới** node (node không bị đường cắt qua)
- [ ] 9.2 Run test to verify it fails
  - Reference: US-1 AC-1.3
  - Command: `flutter test test/ui/trail_painter_test.dart`
  - Expected: FAIL vì `_TrailPainter` chưa tồn tại.
- [ ] 9.3 Write minimal implementation
  - Reference: US-1 AC-1.3
  - Implementation file: `lib/ui/widgets/trail_painter.dart`
  - Port gần như nguyên từ `level_map_screen.dart:455-500` — nó **không có** logic riêng của game bong bóng, chỉ nhận `List<Offset>` + `Color`. Cubic qua trung điểm, dash 13 / gap 11 qua `path.computeMetrics()`, `strokeWidth` 7, `StrokeCap.round`, accent ở alpha 0.32. Vẽ trong `Positioned.fill` **phía sau** node.
- [ ] 9.4 Run test to verify it passes
  - Reference: US-1 AC-1.3
  - Command: `flutter test test/ui/trail_painter_test.dart`
  - Expected: PASS. Sinh ảnh chuẩn bằng `--update-goldens` rồi **kiểm mắt** trước khi commit.

### 10. [SUPERSEDED — KHÔNG LÀM] Lắp bản đồ theo đường mòn

- [ ] 10.1 Write the failing test
  - Reference: US-1 AC-1.1, US-1 AC-1.5, US-1 AC-2.3, US-1 AC-2.4
  - Files: `test/ui/arena_map_chapters_test.dart`
  - Add coverage cho bản đồ đã nhóm theo chương.
  - Test file: `test/ui/arena_map_chapters_test.dart`
  - Expected assertion: **4** tiêu đề chương có mặt; 20 node có mặt, thứ tự `levelId` tăng trong từng chương; **luật mở màn không đổi** — kiểm trực tiếp `isUnlocked`; chạm node đã mở ⇒ vào màn đó; chạm node khoá ⇒ **không** điều hướng, hiện snackbar; một màn ngoài mọi chương vẫn hiện trong nhóm dự phòng
- [ ] 10.2 Run test to verify it fails
  - Reference: US-1 AC-1.1, US-1 AC-1.5, US-1 AC-2.3, US-1 AC-2.4
  - Command: `flutter test test/ui/arena_map_chapters_test.dart`
  - Expected: FAIL vì `arena_map_screen` còn là `ListView.separated` phẳng.
- [ ] 10.3 Write minimal implementation
  - Reference: US-1 AC-1.1, US-1 AC-1.5, US-1 AC-2.3, US-1 AC-2.4
  - Implementation file: `lib/ui/screens/arena_map_screen.dart`, `lib/ui/map_items.dart`
  - `buildMapItems({arenas, chapters})` (tham số tiêm được để test nhóm dự phòng không phải sửa global). `ConsumerWidget` → `ConsumerStatefulWidget`. Thay `_ArenaTile` bằng `chapter_header` + `chapter_trail`. Đọc tiến trình **trong `build`** (`ref.watch`), không capture — AC US-2/1.3 đòi tiến độ cập nhật khi quay lại.
  - Nhóm dự phòng: header `chapterOtherTitle`, đặt **sau** chương 4, màn xếp tăng theo `levelId`, max-stars theo số màn thực có.
- [ ] 10.4 Run test to verify it passes
  - Reference: US-1 AC-1.1, US-1 AC-1.5, US-1 AC-2.3, US-1 AC-2.4
  - Command: `flutter test test/ui/arena_map_chapters_test.dart`
  - Expected: PASS, và `app_smoke_test.dart` sẵn có **vẫn xanh** (nó kiểm được danh sách màn và trạng thái khoá).

### 11. [SUPERSEDED — KHÔNG LÀM] Nối tự cuộn theo extent đường mòn

- [ ] 11.1 Write the failing test
  - Reference: US-3 AC-1.4, US-3 AC-2.1, US-3 AC-2.3
  - Files: `test/ui/arena_map_autoscroll_test.dart`
  - Add coverage cho vòng đời `ScrollController` và chốt tạo-một-lần.
  - Test file: `test/ui/arena_map_autoscroll_test.dart`
  - Expected assertion: mở với `completedMax == 7` ⇒ offset **khung đầu tiên** khớp `initialOffsetFor`, không có khung nào ở offset 0 trước đó; sau khi người chơi cuộn tay rồi **đổi cỡ chữ hoặc locale** ⇒ offset **không** bị áp lại (đây là test hồi quy thật của AC-1.4); người chơi mới ⇒ offset 0
- [ ] 11.2 Run test to verify it fails
  - Reference: US-3 AC-1.4, US-3 AC-2.1, US-3 AC-2.3
  - Command: `flutter test test/ui/arena_map_autoscroll_test.dart`
  - Expected: FAIL vì chưa nối controller.
- [ ] 11.3 Write minimal implementation
  - Reference: US-3 AC-1.4, US-3 AC-2.1, US-3 AC-2.3
  - Implementation file: `lib/ui/screens/arena_map_screen.dart`
  - Tạo `ScrollController(initialScrollOffset: ...)` trong **`initState`** kèm `ref.read` (không `watch`) — theo đúng `level_map_screen.dart:163-173`. `initState` dùng được ở đây **vì** không còn đọc `MediaQuery`: offset thuần hằng số pixel. Dispose controller.
  - AC US-3/2.3 (gate hoạt ảnh cuộn bằng `disableAnimationsOf`) thoả **rỗng**: `initialScrollOffset` không phải hoạt ảnh, không có `animateTo` nào. Nếu Phase 4 sau này thêm hiệu ứng cuộn thì gate trở thành bắt buộc.
- [ ] 11.4 Run test to verify it passes
  - Reference: US-3 AC-1.4, US-3 AC-2.1, US-3 AC-2.3
  - Command: `flutter test test/ui/arena_map_autoscroll_test.dart`
  - Expected: PASS.

### 12. [SUPERSEDED — KHÔNG LÀM] Port composition `ban_bua`

- [ ] 12.1 Write the failing test
  - Reference: US-1 AC-3.2, US-1 AC-3.3
  - Files: `test/ui/arena_map_shell_test.dart`
  - Add coverage cho vỏ thẻ sticker, icon qua `BbIcons`, và route reveal.
  - Test file: `test/ui/arena_map_shell_test.dart`
  - Expected assertion: bề rộng nội dung bị chặn bởi `BbTokens.contentMaxWidth`; **không** còn `Icons.` thô nào trong `arena_map_screen.dart`; sao hiện bằng `BbIcons.starFill`/`starOutline`, **không** phải chuỗi `'★'`; chạm node mở màn bằng `bbRevealRoute` tâm tại node đó, không phải `MaterialPageRoute`
- [ ] 12.2 Run test to verify it fails
  - Reference: US-1 AC-3.2, US-1 AC-3.3
  - Command: `flutter test test/ui/arena_map_shell_test.dart`
  - Expected: FAIL — bốn thứ này đều **đã có** trong repo mà **0 lần** được gọi.
- [ ] 12.3 Write minimal implementation
  - Reference: US-1 AC-3.2, US-1 AC-3.3
  - Implementation file: `lib/ui/screens/arena_map_screen.dart`
  - Port vỏ từ `level_map_screen.dart:37-101`: `contentMaxWidth` + container cream + `rXl` + `bd4` + `stickerLg` + `BbDotPattern`. Đổi `Icons.*` → `BbIcons.*`, chuỗi `★` → icon sao, `MaterialPageRoute` → `bbRevealRoute(center: bbCenterOf(nodeCtx))` với một `Builder` bọc node để lấy `RenderBox` của chính nó. Snackbar khoá: thêm `clearSnackBars()` + `ink700` + floating + `rMd` như bản cũ.
- [ ] 12.4 Run test to verify it passes
  - Reference: US-1 AC-3.2, US-1 AC-3.3
  - Command: `flutter test test/ui/arena_map_shell_test.dart`
  - Expected: PASS.

### 12A. Token và shell tối cho màn chọn màn [REPLACEMENT]

- [ ] 12A.1 Viết golden/widget test cho shell 390 × 844: nền `nightIndigo`, header
  `panelNavy`, Back / “CHỌN MÀN” / tổng sao; không có `sky`, cream card hoặc coral
  CTA từ composition cũ.
- [ ] 12A.2 Thêm/ánh xạ token ngữ nghĩa theo `uiux-guideline.md`; không viết hex
  trong widget và không sửa `lib/sim/`.
- [ ] 12A.3 Chạy test ở phone, tablet và text scale 2.0; kiểm không overflow.

### 12B. Node level dạng grid [REPLACEMENT]

- [ ] 12B.1 Viết test cho năm trạng thái `locked`, `unlocked`, `current`,
  `completed`, `skipped`; mỗi node có hit target ≥48dp và một semantic label đầy đủ.
- [ ] 12B.2 Dựng node tròn/bo tròn với số ở giữa, 0–3 sao, lock icon, gold
  outline/glow cho current và badge/icon chữ cho skipped. Không dùng màu đơn độc.
- [ ] 12B.3 Giữ extent node ổn định giữa các state để grid không nhảy.

### 12C. Section chapter và grid 4 cột [REPLACEMENT]

- [ ] 12C.1 Viết test: 4 header, mỗi header có `earned/max`; mỗi chapter có đúng
  5 node theo `levelId`; chapter sau không lấp ô trống của chapter trước.
- [ ] 12C.2 Dùng một `CustomScrollView`/sliver tree; mỗi section có header và
  `SliverGrid` 4 cột. Không dùng scroll lồng, `ChapterTrail` hoặc `TrailPainter`.
- [ ] 12C.3 Nhóm dự phòng cho arena ngoài `kChapters` vẫn hiện sau chương 4.

### 12D. Tự định vị theo section/grid [REPLACEMENT]

- [ ] 12D.1 Viết test offset cho màn 1, 8 và 20; offset gồm extent header, grid
  row và khoảng section thật, được clamp và áp trước khung đầu.
- [ ] 12D.2 `targetArenaId` hợp lệ thắng luật suy ra; giá trị lạ rơi về
  `targetLevelId`; người mới/đã xong mở đầu danh sách.
- [ ] 12D.3 Không gọi `animateTo` khi mở; sau khi người chơi cuộn tay, locale/text
  scale đổi không tự đưa họ về đích.

### 12E. Visual QA màn chọn màn [REPLACEMENT]

- [ ] 12E.1 Golden 390 × 844 phải khớp hierarchy của hình tham chiếu nhưng dùng
  đúng 4 chapter, không gắn cả 20 màn vào “Chương 1”.
- [ ] 12E.2 Kiểm current/locked/completed/skipped, tên chapter VI/EN, tổng sao,
  snackbar màn khoá và route tới màn mở.
- [ ] 12E.3 Chạy `flutter test` và `flutter analyze`; kiểm mắt golden trước khi kết luận.

### 13. Điểm giao Unit 1 — định vị sau khi bỏ qua màn

- [ ] 13.1 Write the failing test
  - Reference: US-3 AC-2.2
  - Files: `test/ui/arena_map_autoscroll_test.dart`
  - Add coverage cho `targetArenaId` **và** cho đường điều hướng của Unit 1.
  - Test file: `test/ui/arena_map_autoscroll_test.dart`
  - Expected assertion: mở với `targetArenaId` khác `completedMax + 1` ⇒ cuộn tới `targetArenaId`; `targetArenaId` không có trong `kArenas` ⇒ rơi về luật suy ra, không throw; **và** đường bỏ qua màn của Unit 1 dùng `pushReplacement` một `ArenaMapScreen` mới — test chỉ pump màn với tham số sẽ **xanh dù tính năng chết trong app**
- [ ] 13.2 Run test to verify it fails
  - Reference: US-3 AC-2.2
  - Command: `flutter test test/ui/arena_map_autoscroll_test.dart`
  - Expected: FAIL vì `ArenaMapScreen` chưa nhận `targetArenaId`.
- [ ] 13.3 Write minimal implementation
  - Reference: US-3 AC-2.2
  - Implementation file: `lib/ui/screens/arena_map_screen.dart`, `lib/ui/screens/game_screen.dart`
  - `ArenaMapScreen({this.targetArenaId})`, ưu tiên nó trong `targetLevelId`. Và đổi đường bỏ qua màn của Unit 1 từ `pop()` sang `pushReplacement` — `pop` về instance cũ **không** chạy lại `initState` nên `initialScrollOffset` không bao giờ kích. Đường "về menu" thường **vẫn** `pop`.
  - **Chặn nếu Unit 1 chưa làm**: đường bỏ qua màn thuộc Unit 1. Không tự viết lại nó.
- [ ] 13.4 Run test to verify it passes
  - Reference: US-3 AC-2.2
  - Command: `flutter test test/ui/arena_map_autoscroll_test.dart`
  - Expected: PASS.

### 14. Trạng thái "đã xem thoại"

- [ ] 14.1 Write the failing test
  - Reference: US-4 AC-3.3, US-4 AC-3.4
  - Files: `test/data/dialogue_seen_test.dart`
  - Add coverage cho repository và controller.
  - Test file: `test/data/dialogue_seen_test.dart`
  - Expected assertion: lưu rồi đọc round-trip; khoá là `dialogue_seen_v1`, **không** phải `progress_v1`; save lỗi ⇒ trả `false`, **không** throw; tên enum lạ trong payload bị bỏ qua chứ không nổ; save cũ không có khoá ⇒ tập rỗng, mọi đoạn coi như chưa xem
- [ ] 14.2 Run test to verify it fails
  - Reference: US-4 AC-3.3, US-4 AC-3.4
  - Command: `flutter test test/data/dialogue_seen_test.dart`
  - Expected: FAIL vì `dialogue_seen_repository.dart` chưa tồn tại.
- [ ] 14.3 Write minimal implementation
  - Reference: US-4 AC-3.3, US-4 AC-3.4
  - Implementation file: `lib/data/dialogue_seen_repository.dart`, `lib/state/providers.dart`
  - Khoá **riêng** `dialogue_seen_v1` — Unit 1 đã đổi schema `progress_v1` một lần, thêm nữa là lần thứ ba trên cùng payload. `save` trả `Future<bool>` theo hợp đồng Unit 1 đã lập. `DialogueSeenController` theo hình dạng **restore-rồi-notify** của `ProgressController` (`providers.dart:51-66`) — **không** phải `SettingsController`, vốn seed đồng bộ trong constructor.
- [ ] 14.4 Run test to verify it passes
  - Reference: US-4 AC-3.3, US-4 AC-3.4
  - Command: `flutter test test/data/dialogue_seen_test.dart`
  - Expected: PASS.

### 15. Nhân vật và lời thoại song ngữ

- [ ] 15.1 Write the failing test
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-1.4, US-4 AC-4.1
  - Files: `test/domain/character_test.dart`
  - Add coverage cho model nhân vật và bảng thoại.
  - Test file: `test/domain/character_test.dart`
  - Expected assertion: tên nhân vật đọc từ **một** nguồn — đổi nó chỉ sửa một chỗ; mọi `DialogueId` có **cả** `vi` và `en` không rỗng; **không** chuỗi nào chứa giữ chỗ (`TODO`, `TBD`, `XXX`, `Lorem`, ngoặc vuông rỗng); `forLocale('en')` trả bản EN, mặc định trả VI; `lib/domain/character.dart` **không** import Flutter
- [ ] 15.2 Run test to verify it fails
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-1.4, US-4 AC-4.1
  - Command: `flutter test test/domain/character_test.dart`
  - Expected: FAIL vì `character.dart` chưa tồn tại.
- [ ] 15.3 Write minimal implementation
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-1.4, US-4 AC-4.1
  - Implementation file: `lib/domain/character.dart`
  - `DialogueId { intro, levelWin, levelLose, levelLoseShort, finalVictory }`, `DialogueLine{vi, en, forLocale(code)}` theo đúng pattern `VoiceLine` bản cũ (`voice_line.dart:17`) — **và** đúng pattern repo này đã dùng cho `hint`/`hintEn` (`arena.dart:145`). `kDialogues` gồm `onceOnly` cho `intro` + `finalVictory`.
  - Lời thoại **không** qua ARB (bản ghi song ngữ giữ cả hai chuỗi); tên chương và nhãn UI **vẫn** qua ARB.
  - Bản cũ **không có** nhân vật có tên — `VoiceLine` không có field tên. Đây là việc **mới**, chỉ mượn pattern.
- [ ] 15.4 Run test to verify it passes
  - Reference: US-4 AC-1.1, US-4 AC-1.2, US-4 AC-1.3, US-4 AC-1.4, US-4 AC-4.1
  - Command: `flutter test test/domain/character_test.dart`
  - Expected: PASS.

### 16. Component thoại duy nhất

- [ ] 16.1 Write the failing test
  - Reference: US-4 AC-3.2, US-4 AC-4.2, US-4 AC-4.3
  - Files: `test/ui/character_dialogue_test.dart`
  - Add coverage cho component thoại.
  - Test file: `test/ui/character_dialogue_test.dart`
  - Expected assertion: đóng được bằng **một** lần chạm, vùng chạm ≥ `BbTokens.tapMin`; **không** tự đóng theo thời gian; `Semantics` có `scopesRoute` + `explicitChildNodes` + `namesRoute` và đọc được cả tên nhân vật lẫn lời thoại; ở `TextScaler.linear(2.0)` ⇒ `takeException()` là `null`; reduced-motion bật ⇒ nội dung **vẫn** hiện, chỉ không có hoạt ảnh xuất hiện
- [ ] 16.2 Run test to verify it fails
  - Reference: US-4 AC-3.2, US-4 AC-4.2, US-4 AC-4.3
  - Command: `flutter test test/ui/character_dialogue_test.dart`
  - Expected: FAIL vì component chưa tồn tại.
- [ ] 16.3 Write minimal implementation
  - Reference: US-4 AC-3.2, US-4 AC-4.2, US-4 AC-4.3
  - Implementation file: `lib/ui/character_dialogue.dart`
  - **Một** component cho **mọi** lần thoại xuất hiện. Dùng scrim 70–80%,
    `GestureDetector` chặn chạm xuyên + `SingleChildScrollView` +
    `ConstrainedBox(maxWidth: 420)` + panel `panelNavy` + badge + heading trắng +
    CTA `primaryGold`. Có thể mượn cấu trúc semantics/scroll của
    `GameplayLevelGuideOverlay` bản cũ, nhưng không port card cream/coral.
  - **Sao nguyên khối `Semantics` ở `:1999-2006` kèm comment** — comment ghi rằng bỏ `explicitChildNodes` làm framework assert và hiện màn đỏ. Đó là loại tri thức mất đi thì phải học lại bằng một lần vỡ.
- [ ] 16.4 Run test to verify it passes
  - Reference: US-4 AC-3.2, US-4 AC-4.2, US-4 AC-4.3
  - Command: `flutter test test/ui/character_dialogue_test.dart`
  - Expected: PASS.

### 17. Thoại giới thiệu trong overlay hướng dẫn

- [ ] 17.1 Write the failing test
  - Reference: US-4 AC-2.1, US-4 AC-3.1, US-4 AC-3.5
  - Files: `test/ui/game_screen_dialogue_test.dart`
  - Add coverage cho thoại giới thiệu và cổng "lần đầu".
  - Test file: `test/ui/game_screen_dialogue_test.dart`
  - Expected assertion: thoại giới thiệu hiện **trong `_guide()`** (overlay hướng dẫn hiện có), không phải ở menu; bi đang bay ⇒ **không** thoại nào hiện; thoại **không** che tín hiệu `armed` (nó không cùng tồn tại với lúc chơi thật); **trong lúc seen-set còn restore** ⇒ `showGuide` là `false`; đã xem `intro` ⇒ không hiện lại
- [ ] 17.2 Run test to verify it fails
  - Reference: US-4 AC-2.1, US-4 AC-3.1, US-4 AC-3.5
  - Command: `flutter test test/ui/game_screen_dialogue_test.dart`
  - Expected: FAIL vì `_guide()` còn là chữ không có giọng.
- [ ] 17.3 Write minimal implementation
  - Reference: US-4 AC-2.1, US-4 AC-3.1, US-4 AC-3.5
  - Implementation file: `lib/ui/screens/game_screen.dart`, `lib/ui/screens/menu_screen.dart`
  - Thêm thoại vào `_guide()` (`game_screen.dart:382-420`) — nó **đã có** `SingleChildScrollView` (`:386`) nên không gây overflow, và `_fire` return sớm khi `_guideVisible` (`:203`) nên nó không cùng tồn tại với bi đang bay.
  - `showGuide` đọc `!hasSeen(DialogueId.intro)` thay cho `fresh = progress.results.isEmpty` (`menu_screen.dart:34`) — sau Unit 1, **một lần thua** cũng sinh `LevelResult` nên `fresh` thành `false` và người thua ngay lần đầu **mất luôn** phần hướng dẫn. `markSeen(intro)` gọi ở handler `gotItCta` (`:414`).
- [ ] 17.4 Run test to verify it passes
  - Reference: US-4 AC-2.1, US-4 AC-3.1, US-4 AC-3.5
  - Command: `flutter test test/ui/game_screen_dialogue_test.dart`
  - Expected: PASS.

### 18. Thoại kết màn và kết chiến dịch

- [ ] 18.1 Write the failing test
  - Reference: US-4 AC-2.2, US-4 AC-2.3, US-4 AC-2.4
  - Files: `test/ui/game_screen_dialogue_test.dart`
  - Add coverage cho thoại trên overlay kết quả và thứ tự dọc.
  - Test file: `test/ui/game_screen_dialogue_test.dart`
  - Expected assertion: thắng ⇒ thoại phù hợp; thua ⇒ thoại phù hợp; thắng **màn 20** ⇒ thoại kết chiến dịch, `onceOnly`; thứ tự dọc là kết quả → **thoại** → lời nhắc Unit 1 → thử lại → màn kế/về bản đồ; khi `lossesFor >= kSkipOfferAfterLosses` ⇒ dùng `levelLoseShort`, đọc **cùng** hằng số với Unit 1 chứ không viết cứng 3
- [ ] 18.2 Run test to verify it fails
  - Reference: US-4 AC-2.2, US-4 AC-2.3, US-4 AC-2.4
  - Command: `flutter test test/ui/game_screen_dialogue_test.dart`
  - Expected: FAIL vì overlay kết quả chưa có thoại.
- [ ] 18.3 Write minimal implementation
  - Reference: US-4 AC-2.2, US-4 AC-2.3, US-4 AC-2.4
  - Implementation file: `lib/ui/screens/game_screen.dart`
  - Chèn thoại **trước** `BbButton.primary` trong `_result()` (`game_screen.dart:428-478`). Và **bọc `_result()` trong `SingleChildScrollView`** — hiện nó không có, khác `_guide()`; ở lần thua thứ 3 cột phải chứa 7 phần tử và ở cỡ chữ 2.0 đã có nguy cơ overflow.
- [ ] 18.4 Run test to verify it passes
  - Reference: US-4 AC-2.2, US-4 AC-2.3, US-4 AC-2.4
  - Command: `flutter test test/ui/game_screen_dialogue_test.dart`
  - Expected: PASS.
- [ ] 18.5 Chốt overlay kết quả không overflow
  - Reference: US-4 AC-2.4
  - Files: `test/ui/game_screen_dialogue_test.dart`
  - Thêm test: ở `TextScaler.linear(2.0)` với thoại + **cả hai** lời nhắc Unit 1 + thử lại + về menu ⇒ `takeException()` là `null`. Đây là ca chật nhất của unit.

### 19. Chuỗi song ngữ

- [ ] 19.1 Write the failing test
  - Reference: US-1 AC-4.1, US-4 AC-4.1
  - Files: `test/l10n/arb_parity_test.dart`
  - Add coverage cho khoá ARB mới và cho việc không còn chuỗi giữ chỗ.
  - Test file: `test/l10n/arb_parity_test.dart`
  - Expected assertion: `app_vi.arb` và `app_en.arb` có **cùng** bộ khoá; có `characterName`, `chapter1Title`..`chapter4Title`, `chapterOtherTitle`, `chapterProgressLabel`, `currentLevelBadge`; **không** khoá nào có giá trị rỗng hay chứa giữ chỗ
- [ ] 19.2 Run test to verify it fails
  - Reference: US-1 AC-4.1, US-4 AC-4.1
  - Command: `flutter test test/l10n/arb_parity_test.dart`
  - Expected: FAIL vì các khoá chưa có.
- [ ] 19.3 Write minimal implementation
  - Reference: US-1 AC-4.1, US-4 AC-4.1
  - Implementation file: `lib/l10n/app_vi.arb`, `lib/l10n/app_en.arb`, `lib/ui/localized_text.dart`
  - Thêm khoá vào **cả hai** file, VI là bản gốc; chạy `flutter gen-l10n`. `localized_text.dart` giữ `chapterTitle(Chapter, AppLocalizations)` và `characterName(AppLocalizations)` — hai hàm **top-level**, không phải tear-off của instance getter. Đặt ở `lib/ui/` để `lib/domain/` không phải import l10n.
- [ ] 19.4 Run test to verify it passes
  - Reference: US-1 AC-4.1, US-4 AC-4.1
  - Command: `flutter test test/l10n/arb_parity_test.dart`
  - Expected: PASS.

### 20. Nối dây và kiểm toàn bộ

- [ ] 20.1 Chốt ranh giới không bị phá
  - Reference: US-1 AC-2.3, US-2 AC-2.3
  - Files: `test/boundary_test.dart`
  - Task **chỉ có test**: `lib/sim/` không file nào import `package:flutter`; `ArenaSpec` **không** có field chương; unit này **không** gọi phép ghi nào lên `PlayerProgress`; `lib/domain/` không import `lib/l10n/`; luật mở màn tuyến tính giữ đúng giá trị hiện tại.
  - Validate với `flutter test test/boundary_test.dart`
- [ ] 20.2 Chạy toàn bộ test và phân tích tĩnh
  - Reference: US-2 AC-2.2, US-3 AC-1.4
  - Command: `flutter analyze && flutter test`
  - Expected: 0 issue; mọi test xanh gồm 16 test sẵn có. Thắng lại một màn đã bỏ qua ⇒ sao mới cộng vào tiến độ chương (AC US-2/2.2) phải có test trong `chapters_test.dart`.
- [ ] 20.3 Kiểm trên máy ảo
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
