---
artifact_type: story-artifact
phase: inception
status: draft
created: 2026-08-05
updated: 2026-08-09
intent: comic-effects-by-bank-count
source_artifacts:
  - aidlc-docs/foundation/project-overview-pdr.md
  - aidlc-docs/foundation/system-architecture.md
  - aidlc-docs/foundation/uiux-guideline.md
---

# User Stories: Hiệu ứng truyện tranh theo số lần dội

## Overview

`ban_bua` có `comic_effect_controller.dart` — 1.070 dòng code tốt, nhưng gắn vào
`popped` / `isCrit` / `isRage`, tức là ba khái niệm của game ghép-3 đã bị App Store
từ chối. PDR §11 việc thứ 4 yêu cầu **thiết kế lại tầng hiệu ứng quanh số lần dội
trước**, rồi mới port. Nhóm story này định nghĩa tầng hiệu ứng đó bằng ngôn ngữ của
cơ chế mới: **số lần dội** và **hệ số BỪA**.

Đây là story về *cảm giác*, không phải về luật chơi. Không story nào ở đây được đổi
điểm, sao, hay `kMaxBanks` / `kMaxMultiplier` / `kMinAimUp` — PDR §8 ghi rõ đổi một
trong ba con số đó là toàn bộ 20 màn vô hiệu.

### Giả định đang chờ xác nhận

| # | Giả định | Sửa ở đâu nếu sai |
|---|---|---|
| A4a | Hiệu ứng **tái dùng** âm thanh sẵn có (`wallImpact`, `blockedGap`, `comicImpact`, `politeClap`) và tem chữ sẵn có (`DỘI!`, `Bắn thẳng à?`), **không thêm asset ảnh mới** | AC-1.4, AC-2.3 |
| A4b | Tầng hiệu ứng vẽ trong `CustomPainter` + `Ticker` hiện tại, không đưa Flame game loop vào | AC-3.3 |

## User stories

### US-001: Hiệu ứng leo thang theo từng lần dội

**User Story**: As a Người chơi, I want mỗi lần bi dội tường cho tôi một phản hồi
mạnh dần, so that tôi *cảm* được hệ số đang lớn lên thay vì chỉ đọc con số

**Priority**: Medium
**Business Value**: PDR §5 đặt trải nghiệm đích là "kỹ năng và sự thuần thục" —
khoái cảm đến từ việc thực hiện một cú khó. Hệ số BỪA hiện chỉ là chữ `BỪA ×N` mờ
alpha `0x59`; nó nói cho người chơi biết, nhưng không khiến họ thấy sướng.
**Dependencies**: None

**Acceptance Criteria**:

**1. Leo thang theo số lần dội**

1.1 WHEN bi dội tường, khối chắn, hoặc vật cản chéo THEN system SHALL phát hiệu ứng
tại **đúng điểm va chạm**, với cường độ tăng theo số lần dội đã tích luỹ của cú bắn
đang bay.

1.2 WHEN số lần dội tăng THEN system SHALL làm rõ dần hệ số BỪA đang lên, ít nhất
qua kích cỡ hoặc độ đậm của chỉ số hệ số sống.

1.3 WHEN cú bắn đạt số lần dội **cao nhất có thể dùng (4)** THEN system SHALL cho
một phản hồi rõ rệt hơn hẳn các lần dội trước, vì đây là ngưỡng mà mọi mục tiêu
trong game đều đã phá được.

1.4 WHEN hiệu ứng dội được phát THEN system SHALL dùng các âm thanh sẵn có trong
`game_audio_service.dart` (`wallImpact`, `comicImpact`) và **không** yêu cầu asset
âm thanh hay ảnh mới.

1.5 WHEN bi dội vào **mục tiêu** mà chưa đủ số lần dội THEN system SHALL không tăng
cường độ hiệu ứng leo thang, vì dội vào mục tiêu **không tính công dội** (PDR §8.4).

**2. Không phát khi không có gì để ăn mừng**

2.1 IF cú bắn chưa dội lần nào THEN system SHALL vẫn hiện capsule hệ số ở `×1` như
trạng thái nghỉ, nhưng SHALL không phát punch, spark hay hiệu ứng ăn mừng. Số hệ số
luôn đọc được; chỉ phần ăn mừng bắt đầu sau một lần dội hợp lệ
(`uiux-guideline.md` §4.4 và §6.3).

2.2 WHEN bi rơi ra khỏi đáy sân THEN system SHALL kết thúc tầng hiệu ứng của cú đó
và **không** phát hiệu ứng ăn mừng, vì cú đó đã mất.

---

### US-002: Khoảnh khắc phá mục tiêu ở hệ số cao được tôn lên

**User Story**: As a Người chơi, I want một cú carom phá nhiều mục tiêu ở hệ số cao
trông xứng đáng với độ khó của nó, so that phần thưởng cho cú bắn giỏi là cảm giác,
không chỉ là điểm

**Priority**: Medium
**Business Value**: PDR §8.5 gọi "bi xuyên qua sau khi phá mục tiêu" là **toàn bộ
phần thưởng của cơ chế**. Hiện phần thưởng đó chỉ được thể hiện bằng tem `+điểm` và
một cú rung màn — cùng một cường độ cho cú ×2 tầm thường và cú ×6 khó nhất game.
**Dependencies**: US-001 — cường độ hiệu ứng phá mục tiêu bám theo thang leo của
US-001

**Acceptance Criteria**:

**1. Cường độ theo hệ số**

1.1 WHEN một mục tiêu bị phá THEN system SHALL đặt cường độ hiệu ứng theo **hệ số
BỪA tại thời điểm phá**, sao cho cú ở hệ số cao trông mạnh hơn rõ rệt cú ở hệ số
thấp.

1.2 WHEN một cú bắn phá **nhiều mục tiêu liên tiếp** THEN system SHALL cộng dồn cảm
giác thay vì phát lại y nguyên cùng một hiệu ứng, và SHALL không để hiệu ứng của
mục tiêu sau xoá hiệu ứng của mục tiêu trước.

1.3 WHEN cú bắn cuối dọn sạch mục tiêu cuối của màn THEN system SHALL phát một hiệu
ứng kết màn khác biệt với hiệu ứng phá mục tiêu thường.

**2. Giữ nguyên luật hiện có**

2.1 WHEN mục tiêu bị phá THEN system SHALL giữ nguyên rung màn tất định hiện tại
(giảm dần `dt × 4.5`, dịch canvas theo `sin`/`cos`) và **không** dùng `Random`
trong pass vẽ.

2.2 WHEN cú bắn thẳng bị chặn THEN system SHALL giữ tem `Bắn thẳng à?` dùng vai trò
`dangerRed`
đúng như hiện tại và **không** làm dịu nó thành phản hồi trung tính
(`uiux-guideline.md` §3.1 và §6.5).

2.3 WHEN hiệu ứng phá mục tiêu được phát THEN system SHALL dùng âm thanh sẵn có và
không yêu cầu asset mới.

2.4 WHEN vệt ma của cú bắn trước đang trên màn hình THEN system SHALL giữ nó lại
sau khi hiệu ứng kết thúc (`uiux-guideline.md` §5.1 và §10.1).

2.5 WHEN màu của hiệu ứng mới được chọn THEN system SHALL dùng token ngữ nghĩa:
`trajectoryCyan` cho spark/impact/trail và `primaryGold` cho multiplier/score,
không dùng `frame`, `cream` hoặc hex thô như tên vai trò triển khai mới.

---

### US-003: Hiệu ứng không được làm mờ luật chơi

**User Story**: As a Người chơi, I want hiệu ứng không che mất tín hiệu cho tôi biết
mục tiêu nào đã phá được, so that tầng ăn mừng không lấy đi thứ đang dạy tôi chơi

**Priority**: High
**Business Value**: PDR §5 và `uiux-guideline.md` §4.3, §5.2 đều xác định
quầng sáng + đổi biểu cảm khi mục tiêu `armed` là **tính năng dễ đọc
quan trọng nhất trong game**, và bất kỳ thay đổi làm mờ hoặc trễ nó là **hồi quy
sản phẩm**. Tầng hiệu ứng là thứ có nguy cơ cao nhất phá luật này, nên nó cần một
story riêng chứ không phải một dòng ghi chú.
**Dependencies**: US-001, US-002

**Acceptance Criteria**:

**1. Tín hiệu armed luôn thắng**

1.1 WHILE bi đang bay THEN system SHALL giữ quầng sáng, vòng viền, chip số dội và
biểu cảm hoảng của mục tiêu `armed` **nhìn thấy rõ**, kể cả khi hiệu ứng đang phát
ở cùng vùng màn hình.

1.2 WHEN số lần dội của cú đang bay đạt `requiredBanks` của một mục tiêu THEN system
SHALL bật tín hiệu `armed` của mục tiêu đó **ngay tại khoảnh khắc đó**, không trễ
vì đang chờ một hiệu ứng khác chạy xong.

1.3 IF một hiệu ứng phủ lên vùng có mục tiêu chưa bị phá THEN system SHALL vẽ mục
tiêu và biểu cảm của nó **trên** hiệu ứng đó.

**2. Không cản đường chơi**

2.1 WHILE hiệu ứng đang phát THEN system SHALL không chặn thao tác kéo để ngắm và
thả để bắn.

2.2 WHEN người chơi bắn cú tiếp theo trong khi hiệu ứng của cú trước còn dở THEN
system SHALL kết thúc hoặc nhường hiệu ứng cũ, và SHALL không hoãn cú bắn mới.

**3. Hiệu năng và ranh giới kiến trúc**

3.1 WHEN tầng hiệu ứng chạy ở cú bắn nặng nhất của game (màn 20: 6 mục tiêu, 5 cú
bắn, hệ số tới ×6) THEN system SHALL giữ **60fps**, tức không khung nào vượt
**16ms**, và SHALL không làm chậm bước mô phỏng cố định 1/480s.

3.2 WHEN tầng hiệu ứng được thêm vào THEN system SHALL không thay đổi `lib/sim/` —
`kMaxBanks`, `kMinAimUp`, `kMaxMultiplier`, điểm và mốc sao giữ **nguyên giá trị**
(PDR §8.1).

3.3 WHEN tầng hiệu ứng được thêm vào THEN system SHALL vẽ trong `CustomPainter` +
`Ticker` hiện tại và SHALL không đưa Flame game loop vào dự án.

3.4 WHEN `lib/sim/` được kiểm tra sau thay đổi THEN system SHALL không có import
Flutter nào trong thư mục đó (PDR §8.7).
