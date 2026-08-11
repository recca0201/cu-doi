---
artifact_type: story-artifact
phase: inception
status: draft
created: 2026-08-05
updated: 2026-08-09
intent: arena-map-chapters
source_artifacts:
  - aidlc-docs/foundation/project-overview-pdr.md
  - aidlc-docs/foundation/system-architecture.md
  - aidlc-docs/foundation/uiux-guideline.md
---

# User Stories: Nhóm màn theo chương trên bản đồ

> **Visual note — 2026-08-11:** story/acceptance criteria về cấu trúc 4 chương
> vẫn giữ nguyên. Cụm từ navy/arcade đêm cũ không còn quyết style; dùng golden
> arena map và `foundation/uiux-guideline.md` cho karst art direction hiện hành.

## Overview

`arena_map_screen.dart` hiện là một `ListView.separated` phẳng trải 20 màn
(`itemCount: kArenas.length`). Comment trong file ghi rõ lý do: nó được viết khi
game chỉ có ba màn, lúc đó "một bản đồ được trang trí sẽ là diễn kịch". Giờ có 20
màn chia làm 4 chương (PDR §6), và danh sách phẳng đã che mất cấu trúc đó — người
chơi không thấy mình đang học **nhóm kỹ năng** nào.

PDR §11 đặt việc này thứ 5. Nhóm story này chỉ đổi **cách trình bày** bản đồ: luật
mở màn tuyến tính (`unlockedMax = completedMax + 1`) giữ nguyên, không chương nào
bị khoá theo cụm.

### Giả định đang chờ xác nhận

| # | Giả định | Sửa ở đâu nếu sai |
|---|---|---|
| A5a | 4 chương đúng tên và đúng phân chia trong PDR §6, mỗi chương 5 màn (1-5, 6-10, 11-15, 16-20) | AC-1.1 |
| A5b | **Giữ nguyên** luật mở màn tuyến tính — chương không phải một cửa khoá mới | AC-1.5 |
| A5c | Bản đồ dùng **grid 4 cột** trên điện thoại, mỗi chương là một section; không dùng đường mòn uốn lượn | AC-2.1, AC-2.2 |
| A8 | Tên chương có ở **cả** `app_vi.arb` và `app_en.arb` | AC-1.6 |

## User stories

### US-001: Thấy 20 màn được nhóm theo 4 chương

**User Story**: As a Người chơi, I want bản đồ chọn màn nhóm các màn theo chương có
tên, so that tôi biết mỗi cụm màn đang dạy tôi kỹ năng gì thay vì thấy một danh
sách 20 dòng không có cấu trúc

**Priority**: Medium
**Business Value**: 4 chương trong PDR §6 không phải nhãn trang trí — chúng là một
đường cong dạy chơi ("Học luật dội" → "Kệ và hốc" → "Zig-zag" → "Vật cản chéo").
Cấu trúc đó hiện tồn tại trên giấy nhưng người chơi không bao giờ thấy.
**Dependencies**: None

**Acceptance Criteria**:

**1. Nhóm và đặt tên**

1.1 WHEN người chơi mở màn hình chọn màn THEN system SHALL nhóm 20 màn thành 4
chương theo đúng phân chia của PDR §6:
- Chương 1 — Học luật dội: màn 1-5
- Chương 2 — Kệ và hốc: màn 6-10
- Chương 3 — Zig-zag: màn 11-15
- Chương 4 — Vật cản chéo: màn 16-20

1.2 WHEN mỗi chương được hiện THEN system SHALL hiện tiêu đề chương gồm số chương
và tên chương, phân biệt rõ với node màn.

1.3 WHEN các màn trong một chương được hiện THEN system SHALL giữ nguyên thứ tự
tăng theo `levelId`.

1.4 WHEN node màn được hiện THEN system SHALL hiện số màn, 0–3 sao và trạng thái
mở/khoá/current/skipped. Tên màn đầy đủ SHALL nằm trong semantic label; không bắt
buộc nhét tên dài vào node grid hẹp.

1.5 WHEN trạng thái mở/khoá của một màn được tính THEN system SHALL dùng đúng luật
tuyến tính hiện tại (`unlockedMax = completedMax + 1`) và SHALL **không** thêm điều
kiện khoá theo chương.

1.6 WHEN tên chương được thêm THEN system SHALL có bản dịch ở **cả** `app_vi.arb` và
`app_en.arb`, với VI là mặc định.

**2. Bố cục và thao tác**

2.1 WHEN màn hình chọn màn được dựng trên điện thoại THEN system SHALL dùng một vùng
cuộn chứa bốn section chương, mỗi section là **grid 4 cột**; SHALL không dùng đường
mòn, connector cubic hoặc bố cục zig-zag.

2.2 WHEN màn hình chọn màn được hiện trên điện thoại THEN system SHALL giữ bề rộng
nội dung tối đa **440dp** và vùng chạm node tối thiểu **48dp**.

2.3 WHEN người chơi chạm một node màn đã mở THEN system SHALL vào màn đó, y như hành
vi hiện tại.

2.4 IF người chơi chạm một node màn chưa mở THEN system SHALL giữ nguyên phản hồi
hiện có (`arenaLockedHint`) và không vào màn.

2.5 WHEN shell và node được vẽ THEN system SHALL dùng `nightIndigo`/`panelNavy`,
`primaryGold` cho current và sao, cùng icon/outline/chữ để phân biệt trạng thái;
SHALL không dùng nền sky/cream hoặc coral/teal như vai trò mới.

---

### US-002: Thấy tiến độ của từng chương

**User Story**: As a Người chơi, I want thấy mình đã lấy bao nhiêu sao trong mỗi
chương, so that tôi biết chương nào còn sao để quay lại cày

**Priority**: Low
**Business Value**: Sao là nguồn tái chơi duy nhất của game (không có leaderboard,
không có nội dung sinh ngẫu nhiên). Tổng sao theo chương cho người chơi một mục
tiêu nhỏ, đúng cỡ, mà không cần thêm hệ thống nào mới.
**Dependencies**: US-001 — cần khối chương tồn tại trước

**Acceptance Criteria**:

**1. Tiến độ theo chương**

1.1 WHEN tiêu đề một chương được hiện THEN system SHALL hiện số sao đã lấy trên tổng
sao có thể lấy của chương đó, tính từ tiến trình đã lưu.

1.2 WHEN mỗi chương có 5 màn và mỗi màn tối đa 3 sao THEN system SHALL tính tổng
tối đa của mỗi chương là **15 sao**.

1.3 WHEN người chơi lấy thêm sao ở một màn rồi quay lại màn hình chọn màn THEN system
SHALL hiện số sao chương đã cập nhật, không cần khởi động lại app.

1.4 IF người chơi chưa lấy sao nào trong một chương THEN system SHALL hiện `0` trên
tổng, không ẩn chỉ số đi.

1.5 IF tiến trình đã lưu bị thiếu hoặc đọc lỗi THEN system SHALL hiện tiến độ như
chưa có sao nào và SHALL không làm màn hình chọn màn hỏng.

---

### US-003: Vào bản đồ là thấy ngay chỗ mình đang chơi

**User Story**: As a Người chơi, I want bản đồ tự đưa tôi tới màn tiếp theo cần
chơi, so that tôi không phải cuộn qua các chương đã xong mỗi lần mở màn hình này

**Priority**: Low
**Business Value**: Ở chương 4, người chơi phải cuộn qua 15 node đã xong để tới
chỗ cần chơi — mỗi lần mở màn hình. Chi phí nhỏ, nhưng nó là ma sát lặp lại đúng ở
đoạn cuối game, nơi người chơi đã bỏ nhiều công nhất.
**Dependencies**: US-001

**Acceptance Criteria**:

**1. Vị trí cuộn ban đầu**

1.1 WHEN người chơi mở màn hình chọn màn THEN system SHALL cuộn sẵn tới màn mở gần
nhất chưa hoàn thành (`unlockedMax`) và làm nó nhìn thấy được mà không cần thao tác.

1.2 WHEN người chơi đã hoàn thành cả 20 màn THEN system SHALL mở màn hình ở đầu danh
sách, vì không còn màn nào "tiếp theo".

1.3 WHEN người chơi mới hoàn toàn, chưa chơi màn nào THEN system SHALL mở màn hình ở
đầu danh sách, ở Chương 1.

1.4 WHEN người chơi tự cuộn sau khi màn hình đã mở THEN system SHALL không tự cuộn
lại về vị trí ban đầu.
