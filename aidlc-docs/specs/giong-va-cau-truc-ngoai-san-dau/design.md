---
artifact_type: design
phase: construction
status: draft
created: 2026-08-05
updated: 2026-08-09
unit: giong-va-cau-truc-ngoai-san-dau
source_artifacts:
  - aidlc-docs/specs/giong-va-cau-truc-ngoai-san-dau/requirements.md
  - aidlc-docs/foundation/uiux-guideline.md
  - Cu_Doi_UI_UX_Design_Spec.docx
---

# Design: Giọng và cấu trúc ngoài sân đấu

## Overview

| Review item | Summary |
| --- | --- |
| **Goal and approach** | Cho 20 màn một **cấu trúc** (4 chương, có tiến độ, mở ra là thấy chỗ đang chơi) và cho game một **giọng** (một nhân vật có tên, một component thoại). Toàn bộ nằm **ngoài** sân đấu: `lib/sim/` không đổi một dòng, và sân đấu chỉ nhận thêm một overlay thoại có điều kiện. |
| **In scope** | Định nghĩa chương từ một nguồn duy nhất; tiêu đề chương + tiến độ sao; tự cuộn tới màn đang chơi; nhân vật có tên; component thoại duy nhất; trạng thái "đã xem" bền qua lần mở app; song ngữ đầy đủ. |
| **Out of scope** | Đổi luật mở màn/điểm/sao; asset mascot mới (dùng cái đã có); voice-over; cây hội thoại nhiều nhánh; sửa khoảng trống accessibility A1–A8; hiệu ứng cú bắn (Unit 2); gợi ý/bỏ qua màn (Unit 1). |

## Open Questions

| # | Question | Blocking? | Working assumption |
| --- | --- | --- | --- |
| Q1 | Tên nhân vật là gì? | **Không** | Design chốt **cơ chế**: `characterName(AppLocalizations t) => t.characterName` — một hàm trỏ tới getter sinh sẵn, không chốt tên. AC US-4/1.4 đòi đúng thế: đổi tên phải sửa **một** chỗ. Tên cụ thể là quyết định thương hiệu; Phase 4 điền, và AC US-4/1.3 cấm chuỗi giữ chỗ nên nó không thể trôi ra bản build. |
| Q2 | Tên 4 chương? | Không | Cùng cơ chế: `chapterTitle(Chapter, AppLocalizations)` trong `lib/ui/localized_text.dart`. `Chapter` giữ **thuần** (chỉ khoảng `levelId`). Tên đi qua hai file ARB như mọi chuỗi khác. |
| Q5 | Cổng "lần đầu" cho thoại giới thiệu là `showGuide`/`fresh` hay seen-set? | **Đã chốt** | **Seen-set.** `menu_screen.dart:34` hiện tính `fresh = progress.results.isEmpty` — nhưng sau Unit 1, **một lần thua** cũng sinh `LevelResult` (Unit 1 Q4), nên `fresh` thành `false` và `_guide()` **không bao giờ hiện lại**. Người chơi thua ngay lần đầu sẽ mất luôn phần hướng dẫn. `showGuide` phải đọc `!hasSeen(DialogueId.intro)`. **Trong lúc seen-set còn đang restore**, `showGuide` là `false` — hiện lại hướng dẫn cho người chơi cũ tệ hơn là hiện muộn một khung cho người mới. `markSeen(DialogueId.intro)` gọi từ handler `gotItCta` chỗ đang clear `_guideVisible` (`game_screen.dart:414`). Đây là **thêm một lần đụng call site của Unit 1**. |
| Q3 | Trạng thái "đã xem thoại" lưu vào `progress_v1` hay khoá riêng? | **Đã chốt** | **Khoá riêng `dialogue_seen_v1`.** Unit 1 đã thêm hai field vào `LevelResult` trong `progress_v1`; nhồi thêm một `Set<String>` vào cùng khoá là lần đổi schema thứ ba trên cùng payload trong cùng release. Thoại cũng **không phải tiến trình chơi** — mất nó thì người chơi xem lại một đoạn thoại, không mất sao hay xu. |
| Q4 | `scrollable_positioned_list` có cần thêm không? | **Đã chốt** | **Không.** Xem § Tự cuộn — dùng `mapExtents(TextScaler)` + `initialScrollOffset` tính bằng số học. Thêm package cho một lần cuộn là chi phí không cần, và `initialScrollOffset` là cách **duy nhất** thoả AC US-3/2.1 ("không giật nhìn thấy được") vì nó đặt vị trí **trước** khung đầu. |
| Q6 | Level select dùng danh sách, đường mòn hay grid? | **Đã chốt** | **Grid 4 cột trên nền navy.** UI/UX Design Spec 1.0 thay thế composition đường mòn của `ban_bua`; chỉ tái sử dụng state/progress và component primitive, không port `ChapterTrail`/`TrailPainter`. |

## Architecture

```mermaid
graph TD
  subgraph SIM["lib/sim/ — KHÔNG ĐỔI"]
    AR["arenas.dart — kArenas<br/>arena.dart — ArenaSpec"]
  end

  subgraph DOMAIN["lib/domain/"]
    CH["chapters.dart<br/>[NEW] kChapters — nguồn duy nhất"]
    CHAR["character.dart<br/>[NEW] DialogueId, kDialogues"]
    PP["player_progress.dart<br/>Unit 3 chỉ ĐỌC<br/>(file do Unit 1 sửa)"]
  end

  subgraph DATA["lib/data/"]
    DR["dialogue_seen_repository.dart<br/>[NEW] khoá dialogue_seen_v1"]
  end

  subgraph UI["lib/ui/"]
    MI["map_items.dart<br/>[NEW] flatten chương → item phẳng"]
    AMS["arena_map_screen.dart<br/>[CHANGED] header + tiến độ + tự cuộn"]
    DB["character_dialogue.dart<br/>[NEW] MỘT component thoại"]
    GS["game_screen.dart<br/>[CHANGED] overlay thoại có điều kiện"]
    MS["menu_screen.dart<br/>[CHANGED] showGuide đọc từ seen-set"]
  end

  AR --> CH
  CH --> MI
  PP --> MI
  MI --> AMS
  CHAR --> DB
  DR --> DB
  DB --> GS
```

- **Pattern đang có**: `arena_map_screen` là `ConsumerWidget` + `ListView.separated` phẳng, `itemCount: kArenas.length`, `itemBuilder` dựng `_ArenaTile`. `showBbDialog` + `BbDialog` đã có.
- **Delta**: danh sách phẳng theo `kArenas` đổi thành danh sách phẳng theo **item** (header hoặc tile); thêm một repository nhỏ và một component thoại.
- **Ranh giới bị ảnh hưởng**: `lib/sim/` **không đổi**. Unit 3 **không ghi** `PlayerProgress` (AC US-2/2.3) — nhưng file đó do **Unit 1** sửa.
- **Ràng buộc chịu lực**: luật mở màn tuyến tính là `[Confirmed]` (AC US-1/2.3) — nhóm theo chương **không** được đổi nó. Và thoại không được che tín hiệu `armed` (AC US-4/3.5).

## Components and Interfaces

```
lib/
├── domain/
│   ├── chapters.dart                    [NEW]      kChapters + targetLevelId — thuần, không l10n
│   └── character.dart                   [NEW]      DialogueId + kDialogues — thuần, không l10n
├── data/
│   └── dialogue_seen_repository.dart    [NEW]      precedent: ProgressController (load async)
├── state/
│   └── providers.dart                   [CHANGED]  + dialogueSeenProvider
└── ui/
    ├── map_items.dart                   [NEW]      flatten + MapExtents + offsetForLevel
    ├── localized_text.dart              [NEW]      MỘT bảng nối id → getter ARB
    ├── character_dialogue.dart          [NEW]      MỘT component thoại (AC US-4/4.2)
    └── screens/
        ├── arena_map_screen.dart        [CHANGED]  header chương, tiến độ, tự cuộn,
        │                                           ConsumerWidget→ConsumerStatefulWidget,
        │                                           _ArenaTile ghim chiều cao cố định
        ├── game_screen.dart             [CHANGED]  (1) thoại trong _guide(),
        │                                           (2) _result() bọc SingleChildScrollView,
        │                                           (3) markSeen(intro) ở gotItCta
        └── menu_screen.dart             [CHANGED]  showGuide đọc từ seen-set (Q5)
lib/l10n/
├── app_vi.arb                           [CHANGED]  tên chương + mọi lời thoại
└── app_en.arb                           [CHANGED]  cùng bộ khoá
```

### `lib/domain/chapters.dart` [NEW]

```dart
class Chapter {
  const Chapter(this.number, this.firstLevelId, this.lastLevelId);
  final int number;          // 1..4
  final int firstLevelId;
  final int lastLevelId;
}   // THUẦN — không biết gì về l10n

const List<Chapter> kChapters = <Chapter>[ /* 1-5, 6-10, 11-15, 16-20 */ ];

Chapter? chapterOf(int levelId);
int chapterMaxStars(Chapter c);      // (lastLevelId - firstLevelId + 1) * 3
int chapterEarnedStars(Chapter c, PlayerProgress p);
```

`kChapters` là **nguồn duy nhất** (AC US-1/1.4): nhóm suy ra từ khoảng `levelId`, không viết cứng ở tầng UI. Thêm màn vào `kArenas` mà không sửa `kChapters` thì màn đó **vẫn hiện** trong một nhóm dự phòng (AC US-1/1.5) — không âm thầm biến mất.

`chapterMaxStars` **tính** từ khoảng chứ không viết cứng 15 (AC US-2/1.2), nên chương có số màn khác vẫn đúng.

`chapterEarnedStars` cộng `starsFor` — màn đã bỏ qua có `stars == 0` nên góp 0, khớp Unit 1 (AC US-2/2.1) **không cần** biết gì về `skipped`.

### `lib/ui/map_items.dart` [NEW]

```dart
sealed class MapItem {}
class ChapterHeaderItem extends MapItem { final Chapter chapter; }
class ArenaTileItem extends MapItem { final ArenaSpec arena; }

List<MapItem> buildMapItems({List<ArenaSpec> arenas = kArenas,
                             List<Chapter> chapters = kChapters});                       // header, 5 tile, header, 5 tile, ...
double offsetForLevel(List<MapItem> items, int levelId, MapExtents e);
```

`targetLevelId(PlayerProgress, {int? requestedArenaId})` sống ở **`lib/domain/`**, không ở đây — nó là luật suy ra thuần từ tiến trình, không có nội dung layout.

### Điểm giao từ Unit 1 — `targetArenaId`

Unit 1 **hoãn có chủ đích** việc định vị bản đồ sau khi bỏ qua màn sang unit này, và điều hướng về bản đồ kèm `targetArenaId` trên route (Unit 1 design Q6, tasks 15.5). Unit này **phải nhận** nó, nếu không việc hoãn đó rơi xuống đất và AC US-2/2.2 của Unit 1 không có ai cài:

```dart
class ArenaMapScreen extends ConsumerStatefulWidget {
  const ArenaMapScreen({this.targetArenaId});     // [CHANGED] optional
  final int? targetArenaId;
}
```

`targetLevelId(progress, requestedArenaId: widget.targetArenaId)` **ưu tiên** `requestedArenaId` khi nó hợp lệ (có trong `kArenas`), rồi mới rơi về luật suy ra. Lý do ưu tiên: người chơi vừa trả 150 xu để bỏ qua một màn cụ thể — chỗ họ muốn thấy là **màn kế tiếp màn đó**, không phải chỗ mà `unlockedMax` tình cờ trỏ tới.

`requestedArenaId` không có trong `kArenas` ⇒ bỏ qua nó, dùng luật suy ra (cùng cách xử lý `unlockedMax` sai ở AC US-3/2.2).

> ### Nhận `targetArenaId` là chưa đủ — đường điều hướng của Unit 1 làm nó vô hiệu
>
> `game_screen` về bản đồ bằng `Navigator.pop()` (`game_screen.dart:473`), tức pop về **đúng instance `ArenaMapScreen`** mà `menu_screen` đã push. Một instance được pop-về **không** chạy lại `initState`/`didChangeDependencies`, nên `initialScrollOffset` **không bao giờ** kích và việc định vị sau khi bỏ qua màn **âm thầm không làm gì**.
>
> **Sửa**: đường bỏ qua màn phải `pushReplacement` một `ArenaMapScreen` **mới** mang `targetArenaId`, chứ không `pop`. Đây là thay đổi ở **call site của Unit 1** (`tasks.md:361` của Unit 1), không phải chỉ trong Unit 3 — **cross-unit rework cần được ghi ra**, vì Unit 1 đã có tasks và có thể đã cài.
>
> Đường "về menu" bình thường vẫn `pop` như cũ — chỉ đường bỏ qua màn đổi.

**Luật suy ra khi không có `requestedArenaId`**: màn mở gần nhất **chưa hoàn thành**, tức `completedMax + 1` theo định nghĩa **sau Unit 1** (`stars >= 1 || skipped`). Nghĩa là một màn đã bỏ qua tính là đã xong, nên bản đồ mở ở màn **sau** nó — đúng ý AC US-3/1.1, và bản trước chỉ liệt kê ba ca trả `null` mà không viết ra nhánh này.

## Thiết kế bản đồ đích — UI/UX Design Spec 1.0

Phần composition bản đồ được thay thế ngày 2026-08-09:

- Shell dùng `nightIndigo` + texture sao/chấm nhẹ, header `panelNavy` với Back,
  “CHỌN MÀN” và tổng sao.
- Mỗi chapter là một section có title + `earned/max`; phần level là
  `GridView`/`SliverGrid` **4 cột**, `NeverScrollableScrollPhysics` nếu nằm trong
  một `CustomScrollView` duy nhất.
- Mỗi node có vùng chạm tối thiểu 48dp; số màn ở giữa; hàng 0–3 sao nằm dưới hoặc
  trong đáy node nhưng không làm thay đổi extent giữa các state.
- `current`: gold outline + glow; `completed`: sao vàng; `locked`: navy/gray +
  lock; `skipped`: badge/icon chữ, không chỉ đổi màu.
- Chapter 5 node giữ đúng lưới; ô trống không được lấp bằng màn của chapter sau.
- Không port `ChapterTrail`, `TrailPainter`, đường cubic đứt nét, công thức sin
  zig-zag, season/boss hoặc palette lễ hội từ `ban_bua`.
- Tự định vị dùng `ScrollController(initialScrollOffset:)` hoặc sliver key/offset
  đã tính trước khung đầu. Offset phải dựa trên extent section/grid đã test, clamp
  hợp lệ và không animate khi mở màn.

`kChapters`, `targetLevelId`, luật mở tuyến tính, tiến độ sao, `targetArenaId` và
nhóm dự phòng vẫn giữ như phần thiết kế miền ở trên; thay đổi này chỉ thay
composition trình bày.

<details>
<summary><strong>Phương án đường mòn đã bị loại — chỉ giữ để tra lịch sử</strong></summary>

> **Không dùng phần thu gọn này làm đầu vào triển khai.**

Toàn bộ phân tích từ đây đến trước mục “Thiết kế nhân vật và thoại” mô tả phương
án đường mòn kế thừa `ban_bua`. Nó được giữ lại để biết lịch sử quyết định, nhưng
**không còn là hướng triển khai** sau UI/UX Design Spec 1.0.

Người dùng chỉ ra giao diện hiện tại "chưa phải" và yêu cầu dùng lại design của bản `ban_bua` cũ (`C:eposan_bua`). Khảo sát bản cũ đổi ba quyết định lớn của design này.

**Phát hiện quan trọng nhất: design system hai project giống nhau từng byte.** `bb_tokens.dart`, `bb_theme.dart`, `bb_icons.dart`, `bb_widgets.dart`, `bb_backdrop.dart`, `bb_transitions.dart` — `diff` rỗng. Nên khoảng cách **không** phải token thiếu, mà là **composition chưa dùng những gì đã có**:

| Đã có trong repo này | Số lần được gọi | Bản cũ dùng thế nào |
| --- | --- | --- |
| `BbIcons.*` | **0** | dùng khắp nơi; repo này còn `Icons.*` thô (`arena_map_screen.dart:42,148`) |
| `bbRevealRoute` + `bbCenterOf` | **0** | mở màn bằng iris reveal từ đúng node vừa chạm |
| `showBbDialog` + `BbDialog` | **0** | mọi dialog; repo này còn `showDialog` thô (`menu_screen.dart:135`) |
| `BbTokens.contentMaxWidth` / `contentScale` | **0** | vỏ thẻ sticker + xử lý tablet |
| `BbLangToggle` | **0** | ở thanh trên của menu |

**Bố cục bản đồ: đường mòn uốn lượn, không phải danh sách thẻ dọc.** Bản cũ dùng `_ChapterTrail` (`level_map_screen.dart:319-377`): các node tròn `BbLevelButton` 68×68 đặt theo `sin(i·π/2)` (chu kỳ giữa → phải → giữa → trái), nối bằng đường cubic **đứt nét** vẽ phía sau (`_TrailPainter`, `:455-500`, dash 13 / gap 11, `strokeWidth` 7, màu accent chương ở alpha 0.32). Sao hiện **dưới** node và **chỉ khi đã hoàn thành**, trong một `SizedBox(height: 16)` cố định nên bước nhảy không đổi.

**Đây là lý do "chưa phải"**: danh sách `BbCard` phẳng hiện tại không có node, không có đường mòn, không có accent chương.

### Tự cuộn: hằng số pixel, KHÔNG phải extent suy từ cỡ chữ

Bản cũ đạt đúng thứ design này cần, nhưng bằng cơ chế đơn giản hơn nhiều (`level_map_screen.dart:182-204`):

```
offset  = BbTokens.sp5                          // 20 — padding trên của ListView
        + Σ (headerHeight + sp4 + n×slot + sp7) // các chương đứng trước
        + headerHeight + sp4                    // header của chương đích
        + targetIndex × slot                    // các màn trên màn đích
        - BbTokens.sp9                          // 48 — chừa ngữ cảnh phía trên
```

**Mọi số hạng đều là hằng số pixel** — `SizedBox(height: 32)`, `slot × n` — **không** một số hạng nào suy từ metric chữ. Nên phép tính **bất biến theo cỡ chữ hệ thống do cấu trúc**.

> ### Bỏ toàn bộ `mapExtents(TextScaler)`
>
> Các bản trước của design này suy extent từ `fontSize × height × maxLines`, rồi phải nhân theo `TextScaler`. Cách đó sinh ra **ba** lỗi tôi đã phải sửa: extent tile sai (96 vs 118.2), thiếu `leadingPad`, và tổng header không khớp công thức của chính nó. Nó còn buộc phải đọc `MediaQuery` trước layout, thứ dẫn tới hai lỗi thời-gian liên tiếp (`initState`, rồi `LayoutBuilder`).
>
> Cách của bản cũ **xoá cả lớp vấn đề đó**: nếu node và header là hộp pixel cố định với nội dung tự co (`FittedBox`), thì không có gì để nhân theo scale, không cần đọc `MediaQuery`, và `MapExtents`/`mapExtents()` **không còn cần tồn tại**.
>
> Đổi lại: nội dung phải **co trong hộp** thay vì hộp giãn theo nội dung. Với node là một con số và header là một badge ngắn thì đó là đánh đổi đúng.

**Hai chỗ bản cũ làm sai, không được sao lại:**

1. **`_chapterHeaderHeight = 32.0` là bug tiềm ẩn.** `BbBadge` cao nội tại ≈ 30.4 ở scale 1.0 (padding `sp1×2` = 8, border `bd2×2` = 6, `BbText.tiny` không khai `height` nên ≈ 16.4 theo metric font) — chỉ dư 1.6px. Mà chính màn đó **ép** text scale 1.18 trên tablet (`level_map_screen.dart:31-35`), cho ≈ 33.3 > 32.0. Nó overflow trên mọi tablet và mọi máy đặt cỡ chữ ≥ ~1.05. Dùng **`kChapterHeaderHeight = 40.0`** và bọc badge trong `FittedBox(fit: BoxFit.scaleDown)`.
2. **Không có clamp trên.** Bản cũ chỉ có `math.max(0, offset)`; nó sống được vì Flutter tự clamp `pixels` ở lần layout đầu. Design này **clamp tường minh** về `maxScrollExtent` để hành vi không phụ thuộc chi tiết nội bộ của framework.

### Chương: giữ bảng khoảng, mượn hình dạng accent

Bản cũ đặt `chapter` làm **field trên `Level`** (`level.dart:44`) rồi bucket + sort mỗi lần build (`level_map_screen.dart:206-214`). **Giữ nguyên quyết định của design này** — bảng khoảng `kChapters` — vì:

- Content bản cũ là **JSON** (`assets/levels/levels.json`), thêm màn không cần biên dịch lại nên field là bắt buộc. Content repo này là `const List<ArenaSpec> kArenas` — nhóm đã ngầm nằm trong thứ tự khai báo.
- `ArenaSpec` sống ở `lib/sim/`, vốn **không được** mang thông tin trình bày.
- Bản cũ đọc `chapterLevels.first.season` (`level_map_screen.dart:241`) — nó **giả định im lặng** mọi màn trong một chương cùng season, một bất biến mà model field-trên-level không cưỡng chế được. Bảng khoảng làm điều đó bất khả thi về cấu trúc.

**Mượn từ `BbChapterTheme`**: gộp `accent` **vào chính** `kChapters`, và giữ ý tra cứu có kẹp (`bb_chapter_theme.dart:94-95`) để chương ngoài phạm vi không bao giờ render mất theme. **Không** port `LevelSeason`/palette lễ hội (repo này không có content lễ hội) và **không** port `boss`.

### Thoại: bản cũ KHÔNG có nhân vật có tên

Đây là điều cần nói thẳng: `VoiceLine` bản cũ là `{vi, en, crowdKind}` (`voice_line.dart:6-17`) — **không có** field tên, không có `speaker`. 10 câu quip vô danh trong `assets/text/voice_lines.json`, và `mood` trong JSON **không bao giờ được đọc**. Thoại được vẽ bằng **canvas Flame** (`bubble_game.dart:2515-2558`), không phải widget.

Nên US-4 là **việc mới**, không phải việc port. Nhưng ba thứ đáng mượn:

| Mượn gì | Từ đâu | Dùng thế nào |
| --- | --- | --- |
| Bản ghi song ngữ + `forLocale` | `voice_line.dart:17` | Repo này **đã dùng đúng pattern** cho `hint`/`hintEn` (`arena.dart:145`). Lời thoại đi theo nó, **không** qua ARB — cùng lý do: `lib/sim/` không import Flutter |
| Vỏ overlay thoại | `GameplayLevelGuideOverlay` (`gameplay_screen.dart:1929-2068`) | `ColoredBox(ink900 @ 0.58)` + `SingleChildScrollView` + `ConstrainedBox(maxWidth: 420)` + `BbCard(cream)` + badge + `BbText.h1` + `BbButton.primary(expand)`. **Sao nguyên** khối `Semantics(scopesRoute, explicitChildNodes, namesRoute)` ở `:1999-2006` **kèm comment** — comment ghi rằng bỏ `explicitChildNodes` làm framework assert và hiện màn đỏ |
| Hình dạng bong bóng thoại | `_renderSpeech` (`bubble_game.dart:2515-2558`) | Pill `RRect` bán kính `h/2`, nền `surface`, viền `ink900` `strokeWidth 2.5`, đuôi tam giác, kẹp ngang `left.clamp(4, w-4)`. Port sang `CustomPainter` nếu thoại vẽ trong sân đấu |

**Chỉnh lại quyết định về l10n**: lời thoại nhân vật dùng `forLocale(code, vi, en)` như `arena.dart:145`, **không** qua ARB. Tên chương và nhãn UI **vẫn** qua ARB. Nên `localized_text.dart` chỉ còn giữ `chapterTitle` và `characterName`.

**`assets/images/mascot/ban_bua_mascot_v2.png` không phải chân dung nhân vật** — trong bản cũ nó chỉ là source art cho app icon (`pubspec.yaml:24`) và **0 dòng Dart nào** tham chiếu. Mọi mascot trên màn hình bản cũ được **vẽ vector** (`bubble_painter.dart`). Với nhân vật của game carom, đây là hạng mục cần quyết ở Phase 4: vẽ vector mới, hay dùng ảnh mới.

### Tự cuộn — vì sao phải là extent cố định

AC US-3/1.1 đòi mở ra đã cuộn tới màn đang chơi; AC US-3/2.1 đòi **không giật nhìn thấy được**. Hai điều đó cùng nhau loại hết các cách thông thường:

| Cách | Vì sao loại |
| --- | --- |
| `Scrollable.ensureVisible` sau khung đầu | Vẽ ở vị trí sai rồi mới nhảy — đúng cái "giật" AC-2.1 cấm |
| `GlobalKey` + post-frame callback | Cùng vấn đề, chỉ khác cơ chế |
| Thêm `scrollable_positioned_list` | Một dependency cho một lần cuộn; và nó cũng cuộn **sau** khi dựng |
| **`ScrollController(initialScrollOffset:)`** | Đặt vị trí **trước** khung đầu ⇒ không có khung nào ở vị trí sai. **Chọn cái này** |

`initialScrollOffset` đòi biết offset bằng **số học** trước khi layout, nên hai loại item phải có **extent cố định**:

```dart
class MapExtents {
  const MapExtents({required this.header, required this.tile,
                    required this.separator, required this.leadingPad});
  final double header;
  final double tile;
  final double separator;    // BbTokens.sp3 = 12.0
  final double leadingPad;   // ListView padding.top = BbTokens.sp3 = 12.0
}

MapExtents mapExtents(TextScaler scaler);
double offsetForLevel(List<MapItem> items, int levelId, MapExtents e);
```

**Công thức, viết ra dưới dạng số học chứ không dưới dạng lời** — vì test khoá extent là test quan trọng nhất của unit, nên công thức phải là **thứ được test**, không phải thứ implementer tự suy lại:

```
chrome  = 40.0            // BbCard: EdgeInsets.all(sp5=20) → 20×2
        +  8.0            // BbCard: Border.all(width: bd3=4) → 4×2
tile    = chrome
        + scaler.scale(20) * 1.2 * 2     // BbText.h3, 2 dòng
        + 4.0                            // SizedBox(BbTokens.sp1)
        + scaler.scale(14) * 1.3         // BbText.small, 1 dòng
                                         // + 0.0 cho badge "đã bỏ qua" — xem dưới

header  = scaler.scale(20) * 1.2         // BbText.h3, ĐÚNG 1 dòng (maxLines: 1)
        + 4.0                            // SizedBox(BbTokens.sp1)
        + scaler.scale(14) * 1.3         // BbText.small, 1 dòng — tiến độ "n/15"
        + 24.0                           // EdgeInsets.symmetric(vertical: sp3=12) → 12×2
```

Ở scale 1.0: `tile` = **118.2**, `header` = **70.2**.

`boxShadow` của `BbCard` (`BbTokens.sticker`, `bb_widgets.dart:324`) **không** góp extent — nó vẽ ngoài hộp layout. Ghi ra để người đọc sau không "sửa" công thức bằng cách cộng nó vào. Hệ quả phụ: khoảng trống thị giác giữa hai thẻ nhỏ hơn 12dp mà separator ngụ ý.

> ### Header phải được ghim y như tile
>
> Công thức trên giả định tiêu đề chương **đúng một dòng** — mà tên chương còn chưa chốt (Q2), nên chuỗi quyết định nó có xuống dòng hay không **chưa tồn tại**. Đây đúng là kiểu tiền đề đã sai hai lần trong design này. Nên header nhận **cùng** cách xử lý với tile: `maxLines: 1` + `TextOverflow.ellipsis` trên tiêu đề, và `SizedBox(height: e.header)` bọc header. Với `maxLines: 1` đã ghim thì tên chương dài cỡ nào cũng **không** phá được số học. Test khoá extent phải có assertion không-overflow cho **cả** header, không chỉ tile.

> ### Tiến độ chương dùng `BbText.small`, **không** `BbBadge`
>
> Bản trước ghi header là `BbText.h3() + BbBadge` — nhưng `BbBadge` gói `BbText.tiny`, và `tiny` là style **duy nhất** trong `bb_theme.dart` **không** khai `height:` (`bb_theme.dart:65-71`, khác `h3`/`small`/`button`). Chiều cao dòng của nó do ascent/descent/leading của font quyết định, tức **không** tính được bằng `fontSize × height`. Nên header không thể ghim bằng số học nếu tiến độ nằm trong `BbBadge`.
>
> Hai đường sửa: thêm `height:` vào `BbText.tiny` (đụng **mọi** `BbBadge` trong app — rủi ro lan rộng), hoặc **không dùng badge ở header**. Chọn cái thứ hai: tiến độ là `BbText.small`, vốn có `height: 1.3` tường minh. Header thành tính được, và không sửa một style dùng chung nào.
>
> Điều này quan trọng **gấp đôi** vì luật "lùi xuống một khoảng bằng `header`" lấy `header` làm đơn vị — sai ở header nhân vào mọi offset, và có **năm** header đứng trước một màn ở chương 4 (bốn chương + nhóm dự phòng).

> ### `kSkippedBadgeAllowance = 0.0` — kèm một ràng buộc lên Unit 1
>
> Unit 1 chỉ nói "thêm `BbBadge` vào thẻ màn khi `isSkipped`" (`tasks.md:399` của Unit 1) mà **không** nói đặt đâu. Nếu badge vào `Column` thì nó tốn ~22dp dọc và thẻ đã-bỏ-qua cao hơn thẻ thường; nếu vào `Row` cạnh cột sao thì tốn **0** dọc.
>
> **Chốt: badge đặt trong `Row`, cạnh cột sao.** Allowance = `0.0`. Đây là **ràng buộc lên Unit 1** — `tasks.md:399` của Unit 1 phải nói rõ vị trí ngang, nếu không thẻ có hai chiều cao nội tại và số học extent sai.

> ### Bản trước của design ghi 96.0 — và đó là lỗi gây overflow, không phải lệch cuộn
>
> Bản trước đưa ra 96.0 như một con số ước lượng. Số học thật từ source: `BbCard` dùng `EdgeInsets.all(BbTokens.sp5)` (`bb_widgets.dart:303`) và `Border.all(width: BbTokens.bd3)` (`bb_widgets.dart:321`) — riêng phần khung đã 48dp. `BbText.h3` là `fontSize 20 × height 1.2` = 24/dòng và `BbText.small` là `14 × 1.3` = 18.2 (`bb_theme.dart:37-42, 58-63`), cộng `SizedBox(BbTokens.sp1)` = 4 (`arena_map_screen.dart:132`). Tổng ≈ **118.2**. Ghim thẻ vào 96.0 khi nội dung nội tại cần ~118 sinh **constraint overflow**, tức lỗi layout thấy ngay, không phải lệch âm thầm. Công thức của bản trước cũng **bỏ sót** cả khoảng `sp1` và cả 8dp border.


**`offsetForLevel` phải cộng cả padding trên của `ListView`**: `ListView.separated` dùng `padding: EdgeInsets.symmetric(horizontal: gutter, vertical: sp3)` (`arena_map_screen.dart:54-57`), nên offset 0 là **đỉnh của padding**. Top của item thứ `n` nằm ở `leadingPad + Σ(extent) + n × separator`. Bản trước chỉ cộng item và separator, tức **mọi** offset thiếu đúng 12dp — cùng loại lỗi với việc bỏ sót separator đã sửa vòng trước.

> **Offset vượt `maxScrollExtent`** bị clamp trong lần layout **đầu**, trước khi paint — nên một màn ở chương 4 sẽ nằm thấp hơn đỉnh viewport chứ không nằm đúng đỉnh, và **không** có cú giật. Ghi ra để lần chạy thật đầu tiên không bị đọc nhầm là bug.

**Cuộn tới đâu**: đặt tile đích **lùi xuống một khoảng bằng `header`**, để tiêu đề chương chứa nó vẫn nằm trong viewport. Kết quả **kẹp sàn 0** (`math.max(0, ...)`) — với màn ở chương 1 thì `leadingPad + header - header` = 12.0, nhưng công thức phải chịu được mọi thứ tự. Cổng tỉ lệ đánh giá **trước** phép lùi: hết ngân sách thì trả 0 luôn, không lùi gì. Người chơi cần biết mình đang ở chương nào, không chỉ ở màn nào.

**Text scale rất lớn**: nếu `mapExtents(...).tile` vượt `kAutoScrollTileRatio` (= **0.5**) lần chiều cao viewport thì **bỏ tự cuộn**, trả offset `0`. Chiều cao viewport phải suy ra **bằng số học trước layout**:

```
viewport = MediaQuery.sizeOf(context).height
         - MediaQuery.paddingOf(context).vertical      // SafeArea
         - (BbTokens.sp4 * 2 + titleRowHeight)         // hàng tiêu đề
```

> **Không dùng `LayoutBuilder`** — và đây là lần thứ hai design này mắc **đúng một hình dạng lỗi**: `ScrollController` được tạo trong `didChangeDependencies`, tức **trước mọi layout**, còn `LayoutBuilder` chỉ cho constraints **trong lúc** layout. Chiều cao đó **không tồn tại** ở thời điểm phải chọn `initialScrollOffset`. Giống hệt lỗi `MediaQuery` trong `initState`: hai quyết định mỗi cái đúng riêng lẻ nhưng không thể cùng đúng **về thời gian**.
>
> Màn này **không có `AppBar`** — chrome là một `Padding(EdgeInsets.all(BbTokens.sp4))` bọc hàng tiêu đề (`arena_map_screen.dart:37-38`). Cách diễn đạt "app bar" ở bản trước là sai. Cuộn tới một tile chiếm gần hết màn hình là vô nghĩa, và đây đúng là đường accessibility ít chịu được một hành vi bịa nhất — nên quyết ở Phase 2 chứ không để Phase 4 tự nghĩ.

`offsetForLevel` cộng extent của mọi item đứng trước tile đích, **cộng cả separator** — `ListView.separated` chèn một separator giữa mỗi cặp item liền nhau, nên với `n` item đứng trước thì có đúng `n` separator đứng trước (kể cả cái nằm ngay trên tile đích).

> ### Cỡ chữ hệ thống làm extent cố định sai — phải nhân theo `TextScaler`
>
> Đây là lỗ thứ hai của tiền đề "extent cố định", và nó nghiêm trọng hơn chuyện xuống dòng: người chơi đặt cỡ chữ lớn trong cài đặt hệ thống thì **mọi** hằng số extent sai, tự cuộn lệch, và lệch **tích luỹ** theo số item. Một người dùng cần chữ to là đúng người dùng ít có khả năng chịu được một màn hình cuộn sai chỗ.
>
> `mapExtents(TextScaler scaler)` tính extent từ scale thật thay vì trả hằng số: phần padding của `BbCard` không đổi, phần chữ nhân theo `scaler.scale(...)` của `BbText.h3()` × 2 dòng cộng `BbText.small()` × 1 dòng. `arena_map_screen` đọc `MediaQuery.textScalerOf(context)` trong `didChangeDependencies` — xem § Tự cuộn để biết vì sao **không** phải `initState`.
>
> Test khoá extent vì thế phải chạy ở **ít nhất hai** mức text scale (1.0 và 2.0), không chỉ mặc định.

> ### `_ArenaTile` hôm nay **không** có chiều cao cố định — phải sửa nó trước
>
> Đây là tiền đề mà bản đầu của design bỏ qua. `_ArenaTile` dựng `Text(t.arenaHeading(...), style: BbText.h3())` bên trong `Expanded` → `Column` **không có `maxLines`** (`arena_map_screen.dart:126-133`). Tên màn dài nhất là `"Bắn thẳng không tính"` (26 ký tự), cộng tiền tố `"Màn 20 · "` thành ~35 ký tự; ở cỡ `h3` trên máy 375dp sau khi trừ `BbTokens.gutter` và cột sao, nó **xuống 2 dòng** và thẻ cao thêm. Chiều cao biến đổi thì số học offset sai, và sai **tích luỹ** — càng cuộn xuống càng lệch.
>
> **Sửa**: `maxLines: 2` + `TextOverflow.ellipsis` trên dòng tiêu đề, và thẻ được ghim chiều cao đúng `mapExtents(...).tile` (đủ chỗ cho 2 dòng). Chọn 2 dòng **không phải** 1 dòng vì AC US-1/2.1 đòi giữ nguyên mọi thông tin thẻ hiện có — cắt tên xuống 1 dòng là mất thông tin thị giác. Với 2 dòng thì mọi tên trong `kArenas` hiện tại đều hiện đủ.
>
> **Cơ chế ghim phải là `SizedBox(height: e.tile)` bọc từng item** — **không** `itemExtent` hay `prototypeItem` (header và tile cao khác nhau nên chúng không dùng được), và **không** `ClipRect`/`OverflowBox`/`FittedBox`. Lý do loại nhóm cắt: chúng cắt nội dung **im lặng**, khiến assertion `tester.takeException() == null` của test khoá extent vẫn xanh khi giá trị ghim cắt mất chữ. `SizedBox` + `Column` thì nội dung quá cao **throw** RenderFlex overflow, tức test mới có nghĩa.
>
> **Hệ quả chấp nhận có ý thức**: thẻ tên một dòng có ~24dp trống bên trong. Nội dung **canh giữa dọc** trong hộp đã ghim (`Center` bên trong `SizedBox`), để thẻ một dòng trông sát với vẻ hiện tại nhất — canh trên sẽ làm nó trông rỗng đầu. Vẫn là một thay đổi thị giác thật trên màn hình mà AC US-1/2.1 muốn giữ: giữ *thông tin*, không giữ *khoảng trắng*.
>
> Đây là thay đổi **[CHANGED]** trên `_ArenaTile`, không phải giả định. Nó cũng là lý do test khoá extent là test quan trọng nhất của unit: nếu ai đổi cỡ chữ, padding của `BbCard`, hay thêm một dòng vào thẻ mà không sửa hằng số, tự cuộn lệch dần và **không có gì báo**.
>
> `Semantics.label` của thẻ vẫn mang **tên đầy đủ** (`arena_map_screen.dart:113`), nên dù ellipsis có kích hoạt ở một locale nào đó trong tương lai, screen reader vẫn đọc trọn tên.

`targetLevelId` trả `null` (⇒ offset 0, mở ở đầu) khi: người chơi mới (AC US-3/1.3), đã xong cả 20 màn (AC US-3/1.2), hoặc `unlockedMax` trỏ tới màn không có trong `kArenas` (AC US-3/2.2).

**Không tự cuộn lại** sau khi người chơi đã tự cuộn (AC US-3/1.4): `initialScrollOffset` chỉ áp một lần lúc `ScrollController` được tạo. `ArenaMapScreen` đổi từ `ConsumerWidget` sang `ConsumerStatefulWidget`, và controller được tạo trong **`didChangeDependencies`** kèm chốt tạo-một-lần:

```dart
ScrollController? _controller;

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (_controller != null) return;                       // CHỐT: chỉ một lần
  final MapExtents e = mapExtents(MediaQuery.textScalerOf(context));
  _controller = ScrollController(initialScrollOffset: /* ... */);
}
```

> **Vì sao không phải `initState`** — bản trước ghi "đọc `MediaQuery.textScalerOf(context)` trước khi tạo `ScrollController` trong `initState`", và câu đó **tự mâu thuẫn**: phụ thuộc vào một `InheritedWidget` trong `initState` làm Flutter throw assertion. `didChangeDependencies` chạy **trước** khung đầu nên tính "không có khung nào ở vị trí sai" vẫn giữ. Nhưng nó **tái chạy** khi text scale hay locale đổi, nên chốt `if (_controller != null) return` là **bắt buộc** — không có nó thì bảo đảm một-lần của AC US-3/1.4 mất. Bản trước nói tính một-lần đúng "do cấu trúc"; điều đó chỉ đúng với `initState`.

Đọc tiến trình **giữ trong `build`** (`ConsumerState.build` có `ref`), **không** capture trong `didChangeDependencies` — AC US-2/1.3 đòi tiến độ chương cập nhật khi quay lại bản đồ, và điều đó chỉ đúng nếu `ref.watch(progressProvider)` nằm trong `build`.

**Reduced-motion** (AC US-3/2.3): `initialScrollOffset` **không phải hoạt ảnh** — không có gì để gate. Ghi ra đây vì một reviewer đọc AC-2.3 sẽ đi tìm `disableAnimationsOf` và không thấy; sự vắng mặt là đúng, không phải bỏ sót.

</details>

## Thiết kế nhân vật và thoại

### `lib/domain/character.dart` [NEW]

```dart
enum DialogueId { intro, levelWin, levelLose, levelLoseShort, finalVictory }

class DialogueSpec {
  const DialogueSpec(this.id, {required this.onceOnly});
  final DialogueId id;
  final bool onceOnly;
}   // THUẦN — không biết gì về l10n

const List<DialogueSpec> kDialogues = <DialogueSpec>[
  DialogueSpec(DialogueId.intro,          onceOnly: true),
  DialogueSpec(DialogueId.levelWin,       onceOnly: false),
  DialogueSpec(DialogueId.levelLose,      onceOnly: false),
  DialogueSpec(DialogueId.levelLoseShort, onceOnly: false),
  DialogueSpec(DialogueId.finalVictory,   onceOnly: true),
];

/// lib/ui/localized_text.dart — nơi DUY NHẤT nối id với chuỗi sinh sẵn.
/// Đặt ở lib/ui/ vì nó phụ thuộc l10n, tức là mối quan tâm trình bày.
String dialogueText(DialogueId id, AppLocalizations t) { /* switch */ }
String chapterTitle(Chapter c, AppLocalizations t)     { /* switch */ }
String characterName(AppLocalizations t) => t.characterName;
```

> ### Phân lớp: `Chapter` và `DialogueSpec` giữ **thuần**, bảng nối đặt ở `lib/ui/`
>
> Bản trước đặt `String Function(AppLocalizations)` **vào chính** `Chapter` và `DialogueSpec` trong `lib/domain/`. Nó chạy được, nhưng buộc `lib/domain/chapters.dart` phải `import '../l10n/app_localizations.dart'` — **import domain→l10n đầu tiên** trong repo (`player_progress.dart` không import gì). Và nó **trái luật phân lớp mà chính design này dùng** để biện minh việc đặt `map_items.dart` ở `lib/ui/`: "nó biết về extent widget nên là mối quan tâm trình bày".
>
> Nên `Chapter` chỉ giữ khoảng `levelId`, `DialogueSpec` chỉ giữ `id` + `onceOnly`, và **một** file `lib/ui/localized_text.dart` giữ hai `switch` nối id với getter. Vẫn "một nguồn duy nhất", vẫn vỡ compile khi đổi khoá, mà không đảo phân lớp.
>
> **Hai hàm này phải là top-level hoặc static**, không phải tear-off của instance getter — `AppLocalizations.characterName` không phải một tear-off hợp lệ.

Cùng lý do đó, `targetLevelId` — một luật suy ra thuần từ tiến trình, không có nội dung layout — nên nằm ở `lib/domain/`, **không** ở `map_items.dart`. Trộn nó với số học extent nghĩa là một luật miền chỉ test được qua một module mang mùi layout.

> ### Cơ chế "khoá ARB" của bản trước **không chạy được**
>
> Bản trước khai `kCharacterNameKey = 'characterName'`, `Chapter.titleKey`, `DialogueSpec.textKey` — toàn là `String`. Nhưng `AppLocalizations` do `flutter gen-l10n` sinh ra là một class **abstract với getter tĩnh** (`app_localizations.dart:64, 105-231`); **không có** tra cứu `key → String`. Nên ba field kia là chuỗi **không thể phân giải** thành text ở runtime, và cả AC US-4/1.4 lẫn AC US-1/1.4 treo trên đó.
>
> **Sửa**: ba resolver top-level nhận `(id, t)` trong `lib/ui/localized_text.dart`, mỗi cái trả về getter sinh sẵn. Vừa an toàn kiểu (đổi tên khoá ARB làm vỡ **compile**, không vỡ ở runtime), vừa giữ đúng ý "một nguồn duy nhất": hai `switch` trong file đó là chỗ duy nhất nối id với chuỗi.

Tên chương đi qua `chapterTitle(Chapter, AppLocalizations)` cùng lý do — và `Chapter` **không** giữ field nào về l10n (xem callout phân lớp ở trên).

`levelLoseShort` là một `DialogueId` **riêng**, không phải một biến thể ẩn của `levelLose` — nó cần khoá ARB riêng và cần chọn được bằng điều kiện tường minh (xem § Xung đột với lời nhắc Unit 1).

### `lib/data/dialogue_seen_repository.dart` [NEW]

```dart
abstract class DialogueSeenRepository {
  Future<Set<DialogueId>> load();
  Future<bool> save(Set<DialogueId> seen);   // bool, không void — theo Unit 1
}

class DialogueSeenController extends StateNotifier<Set<DialogueId>> {
  Future<void> restore();                    // gọi lúc khởi tạo provider
  Future<void> markSeen(DialogueId id);
  bool hasSeen(DialogueId id);
}
```

`dialogueSeenProvider` là `StateNotifierProvider<DialogueSeenController, Set<DialogueId>>`.

> **Tiền lệ đúng là `ProgressController` (`providers.dart:51-66`), không phải `SettingsController`.** Bản trước ghi "precedent: `settings_repository.dart`" — nhưng `SettingsRepository.load()` là **đồng bộ** (`settings_repository.dart:26`) nên `SettingsController` seed được state ngay trong constructor. `DialogueSeenRepository.load()` là `Future`, nên nó cần hình dạng **restore-rồi-notify** như `ProgressController`. Trỏ sai tiền lệ ở đây dẫn tới một controller không bao giờ nạp được trạng thái đã lưu.

`CharacterDialogue` nhận `DialogueId`, tra `kDialogues` lấy `onceOnly`, gọi `dialogueText(id, t)`, và hỏi `dialogueSeenProvider` — đây là đường nối `DialogueId → kDialogues (onceOnly) + dialogueText(id, t) → trạng thái đã xem` mà bản trước để trống.

Khoá `dialogue_seen_v1`, **riêng** với `progress_v1` (Q3). `save` trả `bool` theo đúng hợp đồng Unit 1 đã lập — nhất quán, và một lần ghi thất bại chỉ khiến người chơi xem lại một đoạn thoại (AC US-4/3.4).

Đọc lỗi ⇒ tập rỗng, tức mọi đoạn thoại coi như chưa xem. Hỏng theo hướng "hiện thoại lần nữa", không hỏng theo hướng "mất màn hình".

### `lib/ui/character_dialogue.dart` [NEW]

```dart
class CharacterDialogue extends StatelessWidget {
  final DialogueId id;
  final VoidCallback onDismiss;
}
```

**Một** component cho **mọi** lần thoại xuất hiện (AC US-4/4.2) — menu, overlay kết quả, kết chiến dịch. Dùng `BbCard` + `BbText` + mascot `assets/images/mascot/ban_bua_mascot_v2.png` (asset **đã có**, AC US-4/1.2 cấm asset mới).

| Ràng buộc | Cách thoả |
| --- | --- |
| Bỏ qua được bằng một lần chạm (AC US-4/3.2) | `BbButton` đóng, vùng chạm ≥ 48px; **không** tự đóng theo thời gian |
| Không hiện khi bi đang bay (AC US-4/3.1) | Chỉ dựng khi `_runner == null` |
| Không che `armed` (AC US-4/3.5) | Chỉ ở **`_guide()`** và **overlay kết quả** — không bao giờ trong lúc đang chơi thật. Menu **không** có thoại: sau khi `intro` chuyển vào `_guide()`, không `DialogueId` nào thuộc menu |
| Screen reader đọc được (AC US-4/4.3) | `Semantics` bọc cả tên nhân vật và lời thoại |
| Reduced-motion (AC US-4/4.3) | Hoạt ảnh xuất hiện gate bằng `disableAnimationsOf`; nội dung vẫn hiện |
| Cỡ chữ hệ thống (AC US-4/4.3) | Tôn trọng `MediaQuery.textScaler`; trong `_result()` phải nằm trong `SingleChildScrollView` |

> ### Luật "không bao giờ trên sân đấu" của bản trước làm AC US-4/2.1 mất chủ
>
> AC US-4/2.1 đòi nhân vật giới thiệu luật dội tường **"ở overlay hướng dẫn hiện có"** — và overlay đó là `_guide()`, vốn nằm **trong `Stack` của sân đấu**, trên `CustomPaint` (`game_screen.dart:260, 382-420`). Bản trước cấm thoại xuất hiện trên sân đấu và chuyển phần giới thiệu sang `menu_screen`, nên `_guide()` giữ nguyên chữ không có giọng và **AC US-4/2.1 không có ai cài**.
>
> Luật đó cũng **chặt quá mức**: `_guide()` không thể cùng tồn tại với bi đang bay — `_fire` return sớm khi `_guideVisible` (`game_screen.dart:203`) — và lúc nó hiện thì chưa có gì `armed`. Nên đặt thoại giới thiệu **vào `_guide()`** vẫn thoả AC US-4/3.1 và 3.5 do cấu trúc.
>
> Luật đúng là: **không hiện thoại khi `_runner != null`, và không hiện trong lúc chơi thật** — chứ không phải "không bao giờ trên sân đấu".

`_guide()` **đã có** `SingleChildScrollView` (`game_screen.dart:386`), nên thêm thoại vào đó không gây overflow.

### Xung đột với lời nhắc của Unit 1 — AC US-4/2.4

Overlay kết quả sau Unit 1 **đã có**: lời nhắc gợi ý (lần thua 2), lời nhắc gợi ý + bỏ qua màn (lần thua 3), và lựa chọn thử lại. Unit 3 thêm thoại nhân vật vào **cùng** overlay đó. Thứ tự dọc **dứt khoát**:

```
kết quả (sao/điểm) → THOẠI NHÂN VẬT → lời nhắc Unit 1 → thử lại → màn kế / về bản đồ
```

Thoại đứng **trên** lời nhắc vì nó là phản ứng cảm xúc với kết quả; lời nhắc là hành động cần làm. Đảo lại thì lời nhắc "hết 150 xu bỏ qua màn" bị một câu thoại vui vẻ chen xuống dưới.

**Khi overlay đông nhất**, thoại thua dùng `DialogueId.levelLoseShort` để nó không thành một bức tường chữ. Không có ràng buộc này thì lần thua thứ 3 — đúng lúc người chơi đang bực nhất — là lúc màn hình nói nhiều nhất.

**Điều kiện chọn biến thể ngắn phải đọc cùng nguồn với Unit 1**:

```dart
final int losses = progress.lossesFor(arena.id);        // Unit 1
final bool crowded = losses >= kSkipOfferAfterLosses;   // Unit 1, KHÔNG viết cứng 3
```

> `game_screen` **không có** bộ đếm thua của riêng nó — `_outcome` là theo từng lần load và `_load()` reset nó (`game_screen.dart:54, 87-101`). Nguồn duy nhất là `PlayerProgress.lossesFor` của Unit 1. Bản trước viết cứng "lần thua thứ 3" trong khi Unit 1 gate lời nhắc bằng `kSkipOfferAfterLosses` — **hai nguồn song song cho một ngưỡng**, thứ mà chính `tasks.md:336` của Unit 1 có một test cấm.

**`_result()` phải được bọc `SingleChildScrollView`.** Hiện nó là `Container(alignment: center)` → `Padding` → `Column(mainAxisSize: min)` **không có** scroll view (`game_screen.dart:428-478`) — khác `_guide()`, vốn đã có (`:386`). Ở lần thua thứ 3, cột phải chứa: kết quả + điểm + thoại + nhắc gợi ý + nhắc bỏ qua màn + thử lại + về menu. Ở text scale 2.0, cột 7 phần tử **hiện tại** đã có nguy cơ overflow. Dùng lại đúng hình dạng của `_guide()` nên đây không phải kiểu popup thứ tư.

## UI Design Specification

Ràng buộc đi từ `uiux-guideline.md` và hình tổng hợp trong
`Cu_Doi_UI_UX_Design_Spec.docx`:

- Shell: nền `nightIndigo`, panel/header `panelNavy`, tổng sao màu
  `primaryGold`; không dùng sky/cream.
- Level layout: grid 4 cột trong từng chapter, một vùng cuộn cấp màn hình; không
  có trail/zig-zag/cubic connector.
- Header chapter: tên + tiến độ `n/15`, canh trái, khác node bằng typography và
  khoảng cách; không phụ thuộc hue.
- Node giữ đủ số màn, sao, trạng thái khoá và dấu bỏ qua. `current` có gold
  outline + glow; locked có icon lock; completed có sao; skipped có nhãn/icon.
- `Semantics` của node là một nhãn đầy đủ gồm màn, tên, sao và trạng thái; nội dung
  trang trí bên trong bọc `ExcludeSemantics` để không đọc lặp.
- Mọi kích thước/màu đi qua token đích; không hex thô và không dùng variant coral
  cũ chỉ vì API tên `primary`.

**Chuỗi ARB mới**: `characterName`; `chapter1Title`..`chapter4Title`; `chapterProgressLabel` (có placeholder n/max); `chapterOtherTitle` (nhóm dự phòng); `dialogueIntro`, `dialogueWin`, `dialogueLose`, `dialogueLoseShort`, `dialogueFinalVictory`. Cả VI và EN, cùng bộ khoá (AC US-1/4.1, US-4/4.1).

## Data Models

| Field | Vị trí | New/Changed | Ghi chú |
| --- | --- | --- | --- |
| `seen: Set<DialogueId>` | khoá `dialogue_seen_v1` | **new**, tách riêng | Lưu dưới dạng list tên enum; tên không khớp ⇒ bỏ qua phần tử đó, không nổ |
| `PlayerProgress` | `progress_v1` | **Unit 3 không ghi**; file là `[CHANGED]` **bởi Unit 1** | Unit này chỉ đọc (AC US-2/2.3). Ghi "không đổi" là sai về file — Unit 1 sửa nó đáng kể |

**Các thành viên `PlayerProgress` sau-Unit-1 mà Unit 3 đọc** — liệt kê ra để nếu Unit 3 được cài **trước** Unit 1 thì vỡ ở compile-time chứ không âm thầm mất hành vi: `starsFor`, `isUnlocked`, `isSkipped`, `lossesFor`, `completedMax` (định nghĩa mới).
| `ArenaSpec` | `lib/sim/arena.dart` | **không đổi** | Chương suy ra từ `levelId`, **không** thêm field vào `ArenaSpec` — nếu thêm thì mỗi màn tự khai chương mình và "một nguồn duy nhất" của AC US-1/1.4 mất |

## Error Handling

| Scenario | Handling |
| --- | --- |
| `kArenas` có màn ngoài mọi chương | Vẫn hiện trong **nhóm dự phòng**: một `ChapterHeaderItem` dùng khoá ARB `chapterOtherTitle`, đặt **sau chương 4**, các màn xếp tăng theo `levelId`. Tiến độ của nhóm này tính max-stars theo **số màn thực có trong nhóm**, nên phép đối chiếu "tổng sao các chương == `totalStars`" ở AC US-2/2.1 vẫn đúng (AC US-1/1.5) |
| `tile > kAutoScrollTileRatio × viewport` | **Bỏ tự cuộn**, trả offset 0, mở ở đầu danh sách — cuộn tới một tile chiếm gần hết màn hình là vô nghĩa |
| Đường bỏ qua màn của Unit 1 dùng `pop()` | Phải đổi sang `pushReplacement` một `ArenaMapScreen` mới; `pop` về instance cũ không chạy lại `didChangeDependencies` nên `targetArenaId` vô hiệu |
| Tiến trình thiếu / đọc lỗi | Tiến độ chương hiện như chưa có sao, màn hình **không** hỏng (AC US-2/1.5) |
| `unlockedMax` trỏ màn không tồn tại | Mở ở đầu danh sách (AC US-3/2.2) |
| Đã hoàn thành cả 20 màn | Mở ở đầu danh sách (AC US-3/1.2) |
| Người chơi mới | Mở ở đầu danh sách (AC US-3/1.3) |
| Người chơi đã tự cuộn | Không tự cuộn lại — `initialScrollOffset` chỉ áp một lần (AC US-3/1.4) |
| Vào bản đồ kèm `targetArenaId` từ Unit 1 (vừa bỏ qua màn) | Ưu tiên `targetArenaId` trên luật suy ra — người chơi vừa trả 150 xu cho **màn đó** |
| `targetArenaId` không có trong `kArenas` | Bỏ qua, dùng luật suy ra — cùng cách xử `unlockedMax` sai |
| Ghi `dialogue_seen_v1` thất bại | Bỏ qua im lặng; hệ quả duy nhất là xem lại một đoạn thoại |
| Enum trong save không khớp `DialogueId` | Bỏ qua phần tử đó, giữ phần còn lại |
| Bi đang bay | Không dựng thoại (AC US-4/3.1) |
| Thoại `onceOnly` đã xem | Không hiện lại (AC US-4/3.3) |
| Thua lần 3 — thoại và lời nhắc Unit 1 cùng muốn hiện | Thoại dùng biến thể **ngắn**; thứ tự dọc cố định (AC US-4/2.4) |
| Thắng màn 20 | Thoại kết chiến dịch, `onceOnly` (AC US-4/2.3) |

## Testing Strategy

| Test level | What to verify |
| --- | --- |
| Unit — `chapters.dart` | 20 màn chia đúng 4 chương 5 màn; `chapterOf` đúng ở biên (1, 5, 6, 20); `chapterMaxStars` **tính** từ khoảng, không phải hằng 15; màn ngoài chương vẫn xuất hiện; `chapterEarnedStars` đếm màn bỏ qua là 0 sao |
| Unit — `map_items.dart` | `buildMapItems` xen đúng header/tile theo thứ tự `levelId` tăng; `offsetForLevel` khớp tổng extent tính tay |
| Unit — `targetLevelId` (ở `lib/domain/`) | Trả `null` cho cả ba ca (mới / xong hết / `unlockedMax` sai); ưu tiên `requestedArenaId` khi hợp lệ |
| Unit — **khoá extent** | Hai assertion, **không** chỉ một. (1) `mapExtents(...)` khớp chiều cao **thật** đã render. (2) Nội dung nội tại của **cả thẻ và header** vừa trong extent đã ghim mà **không overflow** — `tester.takeException()` là `null` ở cả `TextScaler.noScaling` và `TextScaler.linear(2.0)`. Chỉ có assertion (1) thì test **tautology**: thẻ đã ghim nên chiều cao render bằng đúng giá trị ghim, và test vẫn xanh khi giá trị ghim cắt mất nội dung |
| Unit — `offsetForLevel` cộng separator | Offset của tile thứ `n` = tổng extent `n` item trước **+ `n` separator**; kiểm bằng một danh sách nhỏ tính tay, vì bỏ sót separator là lỗi lệch dần khó thấy |
| Unit — `DialogueSeenRepository` | Lưu rồi đọc round-trip; save lỗi ⇒ `false` không throw; enum lạ trong payload bị bỏ qua chứ không nổ; khoá **không** phải `progress_v1` |
| Widget — `arena_map_screen` | 4 tiêu đề chương có mặt; tiến độ khớp tiến trình; **luật mở màn không đổi** (test hồi quy trực tiếp lên `isUnlocked`); chạm thẻ mở ⇒ vào màn; chạm thẻ khoá ⇒ vẫn snackbar cũ; dấu "đã bỏ qua" của Unit 1 vẫn hiện |
| Widget — tự cuộn | Mở với `unlockedMax` giữa danh sách ⇒ offset ban đầu khớp `offsetForLevel`; **khung đầu tiên** đã ở vị trí đúng (không có khung nào ở offset 0 trước đó) |
| Widget — điểm giao Unit 1 | Mở với `targetArenaId` khác `unlockedMax` ⇒ cuộn tới `targetArenaId`, **không** tới `unlockedMax`; `targetArenaId` không tồn tại ⇒ rơi về luật suy ra chứ không nổ |
| Widget — đường điều hướng Unit 1 | Bỏ qua màn ⇒ **`pushReplacement`** một `ArenaMapScreen` mới, **không** `pop`. Test chỉ pump `ArenaMapScreen` với tham số sẽ **xanh dù tính năng chết trong app** — phải test cả call site |
| Unit — `offsetForLevel` cộng `leadingPad` | Offset của tile đầu tiên = `leadingPad` (12.0) + `header`, **không** phải chỉ `header`. Bỏ sót padding trên là lỗi lệch đều 12dp |
| Widget — chốt tạo-một-lần | Sau khi người chơi cuộn, đổi text scale hoặc locale ⇒ `didChangeDependencies` tái chạy nhưng offset **không** được áp lại. Đây là test hồi quy thật của AC US-3/1.4 |
| Unit — luật lùi header và ngưỡng bỏ cuộn | Offset đặt tile đích lùi xuống đúng một `header`; `tile > kAutoScrollTileRatio × viewport` ⇒ offset trả về **0**, và cổng này đánh giá **trước** phép lùi header |
| Unit — nhóm dự phòng | Màn ngoài mọi chương ⇒ một header `chapterOtherTitle` **sau** chương 4, màn xếp tăng theo `levelId`, max-stars tính theo số màn thực có; tổng sao các nhóm == `totalStars` |
| Widget — `Semantics` của thẻ **và** header | Mỗi cái phát **đúng một** nhãn: `ExcludeSemantics` quanh nội dung cả hai, nếu không ellipsis làm lộ thêm một nhãn bị cắt. Nhãn header là **một câu**, không phải hai `Text` nối lại |
| Widget — `_result()` không overflow | Ở `TextScaler.linear(2.0)` với thoại + **cả hai** lời nhắc Unit 1 + thử lại + về menu ⇒ `tester.takeException()` là `null`. Đây là ca chật nhất của unit, và là thứ khiến `SingleChildScrollView` thành bắt buộc |
| Widget — race lúc restore seen-set | Cold start, seen-set **chưa** restore xong ⇒ `showGuide` là `false`; người chơi cũ **không** bị hiện lại hướng dẫn. Sau khi restore xong, người chơi mới **vẫn** thấy nó |
| Unit — cổng tỉ lệ và phép lùi header | Cổng `kAutoScrollTileRatio` đánh giá **trước** phép lùi; kết quả luôn `>= 0`; màn ở chương 1 cho `leadingPad` (12.0), không âm |
| Widget — `CharacterDialogue` | Đóng được bằng một lần chạm, vùng chạm ≥ 48px; không tự đóng; `Semantics` đọc được tên và lời; `onceOnly` không hiện lại sau khi đã xem |
| Widget — overlay kết quả | Thứ tự dọc đúng: kết quả → thoại → lời nhắc Unit 1 → thử lại; thua lần 3 ⇒ thoại dùng biến thể ngắn; thoại **không** hiện khi `_runner != null` |
| Ranh giới | `lib/sim/` không đổi; `PlayerProgress` không có phép ghi nào được gọi từ unit này |
| l10n | `app_vi.arb` và `app_en.arb` cùng bộ khoá; **không** còn chuỗi giữ chỗ nào (AC US-4/1.3) |

## Design Decisions

| Decision | Choice | Alternative rejected | Why (one line) |
| --- | --- | --- | --- |
| Nguồn định nghĩa chương | `kChapters` theo khoảng `levelId` | Thêm field `chapter` vào `ArenaSpec` | Field trên từng màn nghĩa là 20 chỗ khai chương, tức "một nguồn duy nhất" của AC US-1/1.4 mất; và nó đổi `lib/sim/`, vốn phải giữ nguyên |
| Cơ chế tự cuộn | `initialScrollOffset` + `mapExtents(TextScaler)` | `ensureVisible`; post-frame callback; `scrollable_positioned_list` | Ba cách kia đều vẽ ở vị trí sai rồi mới nhảy — đúng cái "giật" AC US-3/2.1 cấm. Đánh đổi: công thức extent phải được test giữ đúng ở hai mức text scale |
| Vòng đời `ScrollController` | Tạo trong **`didChangeDependencies`** kèm chốt tạo-một-lần | `initState`; hoặc `build` của `ConsumerWidget` hiện tại | `initState` **không** đọc được `MediaQuery` (assertion). `build` thì mỗi lần tiến trình đổi là cuộn lại, phá AC US-3/1.4. `didChangeDependencies` chạy trước khung đầu nhưng **tái chạy** khi text scale/locale đổi, nên chốt `if (_controller != null) return` là thứ giữ AC US-3/1.4 |
| Lưu trạng thái "đã xem thoại" | Khoá **riêng** `dialogue_seen_v1` | Nhồi vào `progress_v1` | Unit 1 đã đổi schema `progress_v1` một lần trong release này; thêm nữa là lần thứ ba trên cùng payload. Và thoại không phải tiến trình chơi — mất nó không mất sao hay xu |
| Tên nhân vật và tên chương | Ba resolver top-level `(id, t) → String` trong `lib/ui/localized_text.dart` | Khoá `String` tra cứu lúc runtime | `flutter gen-l10n` sinh getter tĩnh, **không có** tra cứu theo khoá — khoá `String` không phân giải được. Function reference làm việc đổi khoá vỡ **compile** chứ không vỡ runtime |
| Vị trí thoại | **`_guide()`** và **overlay kết quả** | "Không bao giờ trên sân đấu" | Luật chặt-quá-mức đó làm AC US-4/2.1 mất chủ: AC đòi thoại giới thiệu ở **overlay hướng dẫn hiện có**, mà `_guide()` nằm trong `Stack` sân đấu. Luật đúng: không hiện khi `_runner != null`, không hiện trong lúc chơi thật |
| Thứ tự dọc trên overlay kết quả | Thoại **trên** lời nhắc Unit 1 | Lời nhắc trên thoại | Thoại là phản ứng với kết quả, lời nhắc là hành động cần làm; đảo lại thì lời nhắc bị câu thoại chen xuống dưới |
| Thoại thua khi overlay đông | `DialogueId.levelLoseShort`, gate bằng `lossesFor >= kSkipOfferAfterLosses` của Unit 1 | Viết cứng "lần thua thứ 3"; hoặc bộ đếm riêng | Lần thua 3 là lúc overlay đông nhất (thoại + hai lời nhắc + thử lại) và là lúc người chơi bực nhất — không phải lúc màn hình nói nhiều nhất |
| Hợp đồng `save` của repo mới | `Future<bool>` | `Future<void>` | Nhất quán với hợp đồng Unit 1 đã lập cho `ProgressRepository` |

## Điều kiện chưa kiểm

| Hạng mục | Trạng thái |
| --- | --- |
| App **đã chạy** trên máy ảo (2026-08-05) | Release APK 19.1 MB cài và chạy trên Pixel 7 API 35: menu render, vào Màn 1, bắn được một cú — vệt ma, preview hai đoạn đứt nét, chip yêu cầu số dội, vạch đáy đều đúng. Nhưng đó là **máy ảo x86_64 trên CPU desktop**, không phải thiết bị tầm thấp; và **chưa có gì của unit này** được cài nên chưa đo được gì của nó |
| Hạ tầng test widget cho `arena_map_screen` | **Chưa có.** `test/` hiện chỉ có `app_smoke_test.dart` và `shot_runner_test.dart`; pump `ArenaMapScreen` cần override `sharedPreferencesProvider` (`providers.dart:12` throw nếu không). Phase 3 phải tính công cho harness này, đừng giả định nó có sẵn |
| Công thức extent (`tile` 118.2, `header` 70.2 ở scale 1.0) | **Suy ra từ source, chưa đo trên máy.** Phase 4 phải đối chiếu với chiều cao render thật; test khoá extent ở hai mức text scale là thứ giữ chúng đúng về sau |
| Ngưỡng "tile > nửa viewport" | Cách xử **đã quyết** (bỏ tự cuộn, mở ở đầu), nhưng **chưa đo** ngưỡng thật. Nguồn chiều cao **đã chốt** (suy ra số học từ `MediaQuery.sizeOf` trừ SafeArea trừ hàng tiêu đề — `LayoutBuilder` không dùng được vì controller tạo trước layout). Chỉ còn **tỉ lệ 0.5 chưa đo** |
| Tự cuộn có "cảm giác đúng chỗ" | Chưa kiểm trên máy. Luật **đã chốt**: lùi xuống một khoảng bằng `header` để tiêu đề chương còn trong viewport |
| Tên nhân vật và tên 4 chương | **Chưa chốt** (Q1, Q2) — quyết định thương hiệu. Cơ chế đã xong nên điền vào là đủ; AC US-4/1.3 cấm chuỗi giữ chỗ trôi ra bản build |
| Thứ tự dọc overlay kết quả | Chưa kiểm trên máy. Nó phụ thuộc Unit 1 đã cài xong lời nhắc — nếu Unit 3 làm trước Unit 1 thì chỗ chèn chưa tồn tại |
| Thiếu foundation doc | `codebase-summary.md` và `code-standards.md` **không tồn tại**. Vị trí `map_items.dart` (ở `lib/ui/`) đặt theo suy luận: nó biết về extent widget nên là mối quan tâm trình bày, không phải miền |

---

## Next Steps

Once this design is approved, proceed to Phase 3: Implementation Planning.

**What to do next:**
1. Use the slash command: `/aidlc.construction.create-tasks`
2. The agent will automatically read `references/phase-3-tasks.md` for detailed workflow instructions
3. Foundation docs will be referenced for implementation patterns

This will create `tasks.md` with actionable task checklist for code implementation.
