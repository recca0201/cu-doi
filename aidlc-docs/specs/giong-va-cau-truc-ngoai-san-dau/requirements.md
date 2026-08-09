---
artifact_type: requirements
phase: construction
status: draft
created: 2026-08-05
updated: 2026-08-09
unit: giong-va-cau-truc-ngoai-san-dau
source_artifacts:
  - aidlc-docs/requirements/001_remaining-scope_units_decomposition.md
  - aidlc-docs/story-artifacts/003_arena-map-chapters_user_stories.md
  - aidlc-docs/story-artifacts/004_haptics-and-characters_user_stories.md
  - aidlc-docs/foundation/project-overview-pdr.md
  - aidlc-docs/foundation/system-architecture.md
  - aidlc-docs/foundation/uiux-guideline.md
  - Cu_Doi_UI_UX_Design_Spec.docx
  - aidlc-docs/specs/duong-ra-khoi-man-bi/requirements.md
  - lib/ui/screens/arena_map_screen.dart
  - lib/ui/screens/game_screen.dart
  - lib/domain/player_progress.dart
  - lib/sim/arenas.dart
---

# Requirements: giong-va-cau-truc-ngoai-san-dau

**Unit**: Unit 3 — Giọng và cấu trúc ngoài sân đấu
**Feature**: 20 màn nhóm theo 4 chương có tên, tiến độ sao theo chương, bản đồ mở ở chỗ đang chơi, và một nhân vật có tên dẫn dắt ở các khoảnh khắc quan trọng
**Created**: 2026-08-05
**User Stories**: US-1, US-2, US-3, US-4
**Estimation (BCP)**: Not yet estimated

**Truy vết ngược Inception**:

| Story ở đây | Story gốc | Tiêu đề gốc |
|---|---|---|
| US-1 | `003/US-001` | Thấy 20 màn được nhóm theo 4 chương |
| US-2 | `003/US-002` | Thấy tiến độ của từng chương |
| US-3 | `003/US-003` | Vào bản đồ là thấy ngay chỗ mình đang chơi |
| US-4 | `004/US-003` | Nhân vật có tên nói chuyện với tôi |

---

## Introduction

Unit này cho thứ người chơi gặp **giữa** các cú bắn một cấu trúc và một giọng nói. 4 chương ở
PDR §6 không phải nhãn trang trí — chúng là một đường cong dạy chơi ("Học luật dội" → "Kệ và
hốc" → "Zig-zag" → "Vật cản chéo") hiện chỉ tồn tại trên giấy, vì `arena_map_screen` là một
danh sách phẳng 20 dòng. Và khoảnh khắc dạy chơi quan trọng nhất của game — cú bắn thẳng đầu
tiên bị nảy ra — hiện chỉ có bốn chữ `Bắn thẳng à?` đứng sau, không có ai nói nó.

Unit này chỉ đổi **cách trình bày và giọng**: luật mở màn tuyến tính giữ nguyên, không chương
nào bị khoá theo cụm, và mọi thứ ở đây chỉ **đọc** tiến trình — với **một ngoại lệ duy nhất**:
trạng thái "đã xem thoại" ở US-4 AC-3.4.

> **Ranh giới yếu nhất trong ba unit, và đó là điều đã biết.** Chương và nhân vật khác nhau về
> từ vựng (điều hướng vs. kể chuyện). Cái chúng thật sự chia nhau: cùng nằm ngoài sân đấu, chỉ
> đọc tiến trình, cùng tầng màn hình, cùng đòi chuỗi song ngữ mới, cùng hồ sơ rủi ro thấp. Với
> 1 người làm, gộp là lựa chọn đúng; nếu team lớn lên, đây là unit nên tách trước tiên.

---

## Phụ thuộc lên Unit 1

**Unit này phải đi sau `duong-ra-khoi-man-bi`.** Lý do không phải luật chơi mà là công việc:
Unit 1 thêm dấu "đã bỏ qua" tái sử dụng được trên item/node màn (US-2 AC-5.1..5.3), Unit 3 dựng lại toàn bộ
`arena_map_screen` thành 4 chương. Làm ngược lại thì dấu "đã bỏ qua" phải viết **hai lần** —
một cho danh sách phẳng, một cho bố cục chương.

Đây **không** phải phụ thuộc vòng: Unit 1 không cần chương để chạy.

---

## Ràng buộc từ code hiện tại

| # | Ràng buộc | Nguồn |
|---|---|---|
| C1 | `arena_map_screen` hiện là `ListView.separated` phẳng, `itemCount: kArenas.length`, mỗi dòng một `BbCard`. Đây chỉ là baseline code; target đã đổi thành grid 4 cột theo D5 | `arena_map_screen.dart`, `uiux-guideline.md` §6.2 |
| C2 | Luật mở màn: `completedMax` = màn xa nhất có `stars >= 1`, `unlockedMax = completedMax + 1`. Unit 1 mở rộng điều kiện này bằng dấu "đã bỏ qua" — Unit 3 **đọc** kết quả, không định nghĩa lại | `player_progress.dart:27-37` |
| C3 | `totalStars` = tổng `stars` của mọi màn. Unit 1 AC-3.2 cố tình giữ tổng này **sạch** (màn bỏ qua đóng góp 0 sao), nên tiến độ sao theo chương không cần biết gì về bỏ qua màn | `player_progress.dart:20`, Unit 1 US-2 AC-3.2 |
| C4 | `kArenas` có 20 phần tử với `id` 1..20 và `name`/`nameEn` mỗi màn. **Không có field chương nào** — nhóm chương phải được định nghĩa mới | `arenas.dart`, `arena.dart` |
| C5 | Chạm màn đã khoá hiện phản hồi bằng `SnackBar` (`arenaLockedHint`) và không điều hướng; target thêm shake ngắn + tooltip/snackbar | `arena_map_screen.dart`, `uiux-guideline.md` §6.2 |
| C6 | Overlay hướng dẫn và kết quả hiện tự dựng bằng `Container`. Unit không tạo popup thứ tư, nhưng mọi phần nó chạm tới phải migrate sang panel navy/scrim/hierarchy CTA đích | `game_screen.dart`, `uiux-guideline.md` §4.2, §6.8–6.10 |
| C7 | Mascot `assets/images/mascot/ban_bua_mascot_v2.png` đã khai báo trong `pubspec.yaml` nhưng chưa được dùng | `pubspec.yaml` |
| C8 | Biểu cảm target đang là một kênh bắt buộc của tín hiệu `armed`; nhân vật có tên bổ sung giọng kể, không thay tín hiệu gameplay | `uiux-guideline.md` §4.3, §5.2 |
| C9 | Shell hiện dùng `BbTokens.screenMax = 440`; target giữ maxWidth 440dp cho nội dung ngoài sân và kiểm phone/tablet/text scale | `uiux-guideline.md` §8 |
| C10 | Trạng thái “đã xem thoại” không thuộc `PlayerProgress`; lưu ở khoá riêng `dialogue_seen_v1`. Thiếu khoá hoặc entry enum lạ ⇒ seen-set rỗng/bỏ qua entry, không ảnh hưởng `progress_v1` | `dialogue_seen_repository.dart` mới, design Q3 |

## Quyết định và giả định

| # | Nội dung | Trạng thái |
|---|---|---|
| D1 | 4 chương đúng tên và đúng phân chia PDR §6, mỗi chương 5 màn (1-5, 6-10, 11-15, 16-20) | Đã chốt ở Inception (A5a) |
| D2 | **Giữ nguyên** luật mở màn tuyến tính — chương **không** phải một cửa khoá mới | Đã chốt ở Inception (A5b) |
| D3 | Tên chương và mọi chuỗi mới có ở **cả** `app_vi.arb` và `app_en.arb`, VI mặc định | Đã chốt ở Inception (A8) |
| D4 | **US-4 chỉ đặc tả hệ thống thoại**: khi nào hiện, ở đâu, không chặn gameplay, song ngữ, dùng mascot sẵn có. **Tên nhân vật và lời thoại cụ thể là việc của Phase 4** | **Đã chốt** với người dùng 2026-08-05 (xác nhận giả định A7) |
| D5 | Bản đồ dùng **grid node trên nền navy**, 4 cột ở điện thoại; không dùng đường mòn uốn lượn của `ban_bua` | Đã chốt từ UI/UX Design Spec 1.0 ngày 2026-08-09 |
| A-open | **Tên nhân vật và nội dung từng câu thoại chưa được viết.** Đây là open decision cố ý, không phải sót. Phase 4 SHALL không tự đặt tên rồi coi là đã chốt — xem US-4 AC-1.3 | Mở — cần nội dung trước khi cài US-4 |

---

## Requirements

### US-1: Thấy 20 màn được nhóm theo 4 chương

**User Story**: As a Người chơi, I want bản đồ chọn màn nhóm các màn theo chương có tên, so that
tôi biết mỗi cụm màn đang dạy tôi kỹ năng gì thay vì thấy một danh sách 20 dòng không có cấu trúc

**Priority**: Medium
**Business Value**: 4 chương trong PDR §6 là một đường cong dạy chơi. Cấu trúc đó hiện tồn tại
trên giấy nhưng người chơi không bao giờ thấy.
**Dependencies**: Unit 1 (`duong-ra-khoi-man-bi`) — xem § Phụ thuộc lên Unit 1

**Acceptance Criteria**:

**1. Nhóm và đặt tên**

1.1 WHEN người chơi mở màn hình chọn màn THEN system SHALL nhóm 20 màn thành 4 chương theo đúng
phân chia của PDR §6:
- Chương 1 — Học luật dội: màn 1-5
- Chương 2 — Kệ và hốc: màn 6-10
- Chương 3 — Zig-zag: màn 11-15
- Chương 4 — Vật cản chéo: màn 16-20

1.2 WHEN mỗi chương được hiện THEN system SHALL hiện tiêu đề chương gồm số chương và tên chương,
phân biệt rõ với node màn.

1.3 WHEN các màn trong một chương được hiện THEN system SHALL giữ nguyên thứ tự tăng theo `levelId`.

1.4 WHEN định nghĩa chương được cài THEN system SHALL suy ra nhóm từ **một nguồn duy nhất**, và
SHALL không viết cứng số 20 hoặc số 4 rải rác — thêm màn hoặc thêm chương SHALL không cần sửa
nhiều chỗ (ràng buộc C4).

1.5 IF `kArenas` có màn không thuộc chương nào đã định nghĩa THEN system SHALL vẫn hiện màn đó
và SHALL không làm màn hình chọn màn hỏng.

**2. Giữ nguyên hành vi, đổi composition thành node**

2.1 WHEN node màn được hiện THEN system SHALL hiện số màn, 0–3 sao và trạng thái
mở/khoá/current/skipped. Tên màn đầy đủ SHALL có trong semantic label; không bắt
buộc hiển thị trực tiếp trong node grid 4 cột.

2.2 WHEN node màn được hiện THEN system SHALL giữ nguyên dấu "đã bỏ qua" do Unit 1 US-2 AC-5.1
định nghĩa, và SHALL không làm mất phân biệt giữa "thắng thật" và "đã bỏ qua".

2.3 WHEN trạng thái mở/khoá của một màn được tính THEN system SHALL dùng đúng luật tuyến tính
hiện tại và SHALL **không** thêm điều kiện khoá theo chương (D2).

2.4 WHEN người chơi chạm một node màn đã mở THEN system SHALL vào màn đó, y như hành vi hiện tại.

2.5 IF người chơi chạm một node màn chưa mở THEN system SHALL giữ nguyên phản hồi hiện có
(`arenaLockedHint`) và SHALL không vào màn (ràng buộc C5).

**3. Bố cục và thao tác**

3.1 WHEN danh sách chương dài hơn màn hình THEN system SHALL cho cuộn mượt qua toàn bộ 4 chương
trong **một** vùng cuộn, và SHALL không lồng vùng cuộn trong vùng cuộn.

3.2 WHEN màn hình chọn màn được hiện trên điện thoại THEN system SHALL giữ bề rộng nội dung tối
đa **440dp** và vùng chạm node tối thiểu **48dp**.

3.3 WHEN tiêu đề chương được hiện THEN system SHALL dùng token semantic và typography
đích; SHALL không viết hex thô hoặc giữ màu legacy dưới tên variant cũ
(`uiux-guideline.md` §3.1–3.4).

3.4 WHEN tiêu đề chương và node màn được dựng THEN system SHALL bọc `Semantics` +
`ExcludeSemantics` cho phần tử tương tác theo `uiux-guideline.md` §8.

3.5 WHEN các màn trong một chương được dựng trên điện thoại THEN system SHALL dùng
**grid 4 cột** với node tròn hoặc bo tròn, và SHALL không dùng đường mòn uốn lượn,
đường cubic hay bố cục zig-zag kế thừa từ `ban_bua`.

3.6 WHEN trạng thái node được dựng THEN system SHALL phân biệt ít nhất `locked`,
`unlocked`, `current`, `completed` và `skipped` bằng nhiều hơn một kênh:
outline/glow/icon/chữ/sao, không chỉ bằng hue.

3.7 WHEN màn hình chọn màn được dựng THEN system SHALL dùng nền `nightIndigo`,
panel/header `panelNavy`, current outline `primaryGold` và chữ tương phản theo
`uiux-guideline.md`; SHALL không dùng nền sky/cream của thiết kế cũ.

3.8 WHEN một chapter có 5 màn THEN system SHALL giữ node thứ 5 canh theo lưới của
chapter, không kéo giãn để lấp đủ 4 cột và không trộn node của chapter kế tiếp vào
cùng section mà không có header phân cách.

**4. Bản địa hoá**

4.1 WHEN tên chương được thêm THEN system SHALL có bản dịch ở **cả** `app_vi.arb` và
`app_en.arb`, với VI là mặc định.

---

### US-2: Thấy tiến độ của từng chương

**User Story**: As a Người chơi, I want thấy mình đã lấy bao nhiêu sao trong mỗi chương, so that
tôi biết chương nào còn sao để quay lại cày

**Priority**: Low
**Business Value**: Sao là nguồn tái chơi duy nhất của game (không leaderboard, không nội dung
sinh ngẫu nhiên). Tổng sao theo chương cho người chơi một mục tiêu nhỏ, đúng cỡ, mà không cần
thêm hệ thống nào mới.
**Dependencies**: US-1 — cần khối chương tồn tại trước

**Acceptance Criteria**:

**1. Tiến độ theo chương**

1.1 WHEN tiêu đề một chương được hiện THEN system SHALL hiện số sao đã lấy trên tổng sao có thể
lấy của chương đó, tính từ tiến trình đã lưu.

1.2 WHEN mỗi chương có 5 màn và mỗi màn tối đa 3 sao THEN system SHALL tính tổng tối đa của mỗi
chương là **15 sao**, suy ra từ số màn thật trong chương chứ không viết cứng số 15.

1.3 WHEN người chơi lấy thêm sao ở một màn rồi quay lại màn hình chọn màn THEN system SHALL hiện
số sao chương đã cập nhật, không cần khởi động lại app.

1.4 IF người chơi chưa lấy sao nào trong một chương THEN system SHALL hiện `0` trên tổng, và
SHALL không ẩn chỉ số đi.

1.5 IF tiến trình đã lưu bị thiếu hoặc đọc lỗi THEN system SHALL hiện tiến độ như chưa có sao
nào và SHALL không làm màn hình chọn màn hỏng.

**2. Nhất quán với tổng sao thật**

2.1 WHEN một màn đã bỏ qua nằm trong chương THEN system SHALL đếm **0 sao** cho màn đó, khớp với
Unit 1 US-2 AC-3.2 — tổng sao theo chương SHALL khớp với `totalStars` khi cộng cả 4 chương, **với
điều kiện mọi màn trong `kArenas` đều thuộc một chương** (ràng buộc C3; xem US-1 AC-1.5 cho trường
hợp ngược lại).

2.2 WHEN người chơi chơi lại và thắng một màn đã bỏ qua THEN system SHALL cộng sao mới vào tiến
độ chương của màn đó.

2.3 WHEN tiến độ chương được tính THEN system SHALL chỉ **đọc** tiến trình và SHALL không ghi
bất cứ gì vào tiến trình.

---

### US-3: Vào bản đồ là thấy ngay chỗ mình đang chơi

**User Story**: As a Người chơi, I want bản đồ tự đưa tôi tới màn tiếp theo cần chơi, so that tôi
không phải cuộn qua các chương đã xong mỗi lần mở màn hình này

**Priority**: Low
**Business Value**: Ở chương 4, người chơi phải cuộn qua 15 node đã xong để tới chỗ cần chơi —
mỗi lần mở màn hình. Chi phí nhỏ, nhưng nó là ma sát lặp lại đúng ở đoạn cuối game, nơi người
chơi đã bỏ nhiều công nhất.
**Dependencies**: US-1

**Acceptance Criteria**:

**1. Vị trí cuộn ban đầu**

1.1 WHEN người chơi mở màn hình chọn màn THEN system SHALL cuộn sẵn tới màn mở gần nhất chưa hoàn
thành (`unlockedMax`) và làm nó nhìn thấy được **mà không cần thao tác**.

1.2 WHEN người chơi đã hoàn thành cả 20 màn THEN system SHALL mở màn hình ở **đầu** danh sách, vì
không còn màn nào "tiếp theo".

1.3 WHEN người chơi mới hoàn toàn, chưa chơi màn nào THEN system SHALL mở màn hình ở **đầu** danh
sách, ở Chương 1.

1.4 WHEN người chơi tự cuộn sau khi màn hình đã mở THEN system SHALL **không** tự cuộn lại về vị
trí ban đầu.

**2. Chất lượng của việc tự cuộn**

2.1 WHEN màn hình mở ở vị trí đã cuộn THEN system SHALL không hiện một cú giật nhìn thấy được từ
đầu danh sách tới vị trí đích.

2.2 IF `unlockedMax` trỏ tới màn không tồn tại trong `kArenas` THEN system SHALL mở ở đầu danh
sách và SHALL không lỗi.

2.3 WHEN màn hình mở THEN system SHALL áp vị trí ban đầu trước khung đầu và SHALL
không dùng hoạt ảnh cuộn. Vì không có animation nên reduced motion không cần nhánh riêng.

---

### US-4: Nhân vật có tên nói chuyện với tôi

**User Story**: As a Người chơi, I want game có một nhân vật có tên nói với tôi ở những khoảnh
khắc quan trọng, so that game có giọng riêng thay vì chỉ là hình học và con số

**Priority**: Low
**Business Value**: PDR §5 nói khoảnh khắc quan trọng nhất của game là cú bắn thẳng đầu tiên bị
nảy ra, và tín hiệu đó hiện chỉ là bốn chữ `Bắn thẳng à?`. Nếu câu đó có một nhân vật đứng sau,
khoảnh khắc dạy chơi thành khoảnh khắc có tính cách — và PDR §10 xếp "gây tò mò hay gây khó
hiểu?" là câu hỏi số một chưa ai trả lời.
**Dependencies**: None trong unit này (độc lập với US-1..US-3). AC-2.4 cần lời nhắc của Unit 1 US-3
mục 2 đã tồn tại. Cần **nội dung** thoại — xem § Điều kiện tiên quyết mục 3

**Acceptance Criteria**:

**1. Nhân vật và giọng**

1.1 WHEN nhân vật xuất hiện THEN system SHALL dùng **một** nhân vật có tên xuyên suốt game, và
SHALL không đổi tên hay đổi giọng giữa các màn hình.

1.2 WHEN nhân vật cần hình ảnh THEN system SHALL dùng mascot đã có trong `assets/images/mascot/`
và SHALL **không** yêu cầu asset ảnh mới (ràng buộc C7).

1.3 WHEN tên nhân vật và lời thoại được cài THEN system SHALL không chứa chuỗi giữ chỗ,
`TODO`/`FIXME`, hay tên/câu thoại nằm ngoài danh sách nội dung đã chốt ở § Điều kiện tiên quyết
mục 3 — mọi chuỗi thoại SHALL tồn tại trong `app_vi.arb`/`app_en.arb` với nội dung đã chốt (A-open).

1.4 WHEN tên nhân vật được dùng THEN system SHALL đọc từ **một nguồn duy nhất**, để đổi tên không
phải sửa nhiều chỗ.

**2. Khi nào nói**

2.1 WHEN người chơi vào game lần đầu THEN system SHALL cho nhân vật giới thiệu luật dội tường ở
**overlay hướng dẫn hiện có**, thay cho văn bản không có giọng.

2.2 WHEN màn kết thúc thắng hoặc thua THEN system SHALL cho nhân vật nói một câu phù hợp với kết
quả đó.

2.3 WHEN người chơi thắng màn 20 — màn cuối THEN system SHALL cho nhân vật có một câu **kết chiến
dịch**, khác với câu thắng màn thường.

2.4 WHEN thoại được thêm vào overlay kết quả THEN system SHALL không xung đột với lời nhắc gợi
ý/bỏ qua màn của Unit 1 US-3 mục 2 — cả hai cùng nằm trên màn hình kết quả, và lựa chọn **tiếp
tục thử lại** SHALL vẫn không kém nổi bật hơn (Unit 1 US-3 AC-3.2).

**3. Không cản đường chơi**

3.1 WHILE bi đang bay THEN system SHALL không hiện thoại nhân vật — khoảnh khắc đó thuộc về sân đấu.

3.2 WHEN thoại nhân vật được hiện THEN system SHALL luôn cho người chơi bỏ qua hoặc đóng nó bằng
**một thao tác**, và SHALL không bắt chờ hết thoại.

3.3 WHEN người chơi đã xem một đoạn thoại một lần THEN system SHALL không bắt xem lại đoạn đó ở
lần sau, **trừ** thoại kết quả màn.

3.4 WHEN trạng thái "đã xem đoạn thoại nào" được lưu THEN system SHALL bền qua lần
mở app trong khoá `dialogue_seen_v1`; save cũ thiếu khoá ⇒ chưa xem đoạn nào, entry
enum lạ ⇒ bỏ qua, và `progress_v1` không bị sửa (ràng buộc C10).

3.5 WHEN thoại nhân vật được hiện THEN system SHALL không che tín hiệu `armed` của mục tiêu và
SHALL không che sân đấu trong lúc chơi.

**4. Bản địa hoá và trình bày**

4.1 WHEN bất kỳ lời thoại nào được thêm THEN system SHALL có bản dịch ở **cả** `app_vi.arb` và
`app_en.arb`, với VI là mặc định, và giọng nhân vật SHALL giữ được ở cả hai ngôn ngữ chứ không
chỉ dịch nghĩa.

4.2 WHEN thoại được trình bày THEN system SHALL dùng **một component thoại duy nhất**
cho mọi lần nhân vật nói, nhúng vào overlay hướng dẫn/kết quả hiện có và SHALL không
tạo cơ chế overlay mới. Component dùng `panelNavy`, chữ white/muted, scrim 70–80%
khi là modal. Variant modal dùng CTA gold/blue; variant nhúng trong kết quả không
thêm CTA gold cạnh tranh với Thử lại/Tiếp theo (`uiux-guideline.md` §4.2, §6.8–6.10).

4.3 WHEN thoại nhân vật được dựng THEN system SHALL đọc được bởi screen reader và SHALL tôn trọng
`MediaQuery.textScaler` — đây là widget thật, không phải chữ vẽ trong `ArenaPainter`.

---

## Ngoài phạm vi

- **Đổi luật mở màn.** Chương không phải cửa khoá (D2). Unit 3 đọc kết quả của luật, không định
  nghĩa lại nó.
- **Ghi vào `PlayerProgress`/`progress_v1`.** Unit chỉ đọc tiến trình gameplay.
  Seen-set thoại ở US-4 AC-3.4 dùng khoá riêng `dialogue_seen_v1`.
- **Dấu "đã bỏ qua" và toàn bộ luồng gợi ý/bỏ qua màn** — thuộc Unit 1. Unit 3 chỉ có nghĩa vụ
  không làm mất nó (US-1 AC-2.2).
- **Chuẩn hoá popup không bị unit này chạm tới.** Overlay hướng dẫn/kết quả và
  component thoại do unit chạm tới vẫn phải đạt target tối mới.
- **Viết nội dung tên và lời thoại nhân vật** — cố ý để mở (A-open); đây là đầu vào cho Phase 4,
  không phải sản phẩm của Phase 1.
- **Rung tay và công tắc rung** (`004/US-001`, `004/US-002`) — cùng story artifact với US-4 nhưng
  thuộc Unit 2 (`phan-hoi-cu-ban`).

## Điều kiện tiên quyết

1. **Unit 1 (`duong-ra-khoi-man-bi`) xong trước** — xem § Phụ thuộc lên Unit 1.
2. PDR §11: `flutter test` chạy được và **playtest 20 màn**. Repo hiện chưa từng được biên dịch.
3. **Nội dung nhân vật**: tên + lời thoại cho **US-4** AC-2.1, AC-2.2, AC-2.3 phải được chốt trước
   khi cài US-4. US-1..US-3 **không** bị chặn bởi việc này.

---

## Next Steps

Once these requirements are approved, proceed to Phase 2: Design Document Creation.

**What to do next:**
1. Use the slash command: `/aidlc.construction.create-design`
2. The agent will automatically read `references/phase-2-design.md` for detailed workflow instructions
3. Foundation docs will be referenced for architecture alignment

This will create `design.md` with comprehensive design based on these requirements.
