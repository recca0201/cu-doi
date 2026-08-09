---
artifact_type: story-artifact
phase: inception
status: draft
created: 2026-08-05
updated: 2026-08-05
intent: hint-and-skip-level
source_artifacts:
  - aidlc-docs/foundation/project-overview-pdr.md
  - aidlc-docs/foundation/system-architecture.md
  - aidlc-docs/foundation/uiux-guideline.md
---

# User Stories: Gợi ý và bỏ qua màn

## Overview

Puzzle dội tường có thể làm người chơi **tắc hẳn** — khác ghép-3 nơi luôn còn một
nước đi hợp lệ. PDR §10 xếp gợi ý/bỏ qua màn là **bắt buộc, không phải tuỳ chọn**,
và PDR §11 đặt nó là việc thứ 3 sau playtest. Nhóm story này cho `Người chơi` một
đường ra khỏi màn bí, và đồng thời cho **xu** ý nghĩa đầu tiên: hiện tại xu chỉ là
điểm hiển thị tích luỹ, chưa có chỗ tiêu (`lib/domain/player_progress.dart:39-40`).

### Xung đột thiết kế đã được người dùng quyết định

`uiux-guideline.md` §"Preview ngắm" và PDR §5 đặt luật `[Confirmed]`: preview
**không bao giờ hiện lời giải đầy đủ**, vì game tiền nhiệm tô sáng mọi bong bóng
sẽ nổ và "điều đó xoá gần hết kỹ năng ngắm".

Gợi ý trong US-001 **vẽ trọn đường carom của một cú giải được** — tức là đúng thứ
luật trên tránh. Người dùng đã được nêu xung đột này và vẫn chọn phương án đó, với
lý do: hint **tốn xu và do người chơi chủ động bấm**, nên nó là một đánh đổi có
giá, không phải thông tin miễn phí ép vào mắt người chơi. Luật `[Confirmed]` vẫn
giữ nguyên cho **preview ngắm thụ động** (AC-1.5).

### Giả định đang chờ playtest xác nhận

| # | Giả định | Sửa ở đâu nếu sai |
|---|---|---|
| A1 | Gợi ý = **50 xu**, bỏ qua màn = **150 xu**. Cân theo mức thu: clear 1-sao cả 20 màn ≈ 1.700 xu, 3-sao đầy ≈ 3.000 xu (`score ~/ 10`, chỉ tính điểm tăng thêm) | AC-1.1, AC-2.1 |
| A2 | Bỏ qua màn tính là **hoàn thành 0 sao**: mở màn sau nhưng không ghi sao, không ghi điểm cao, không thu xu | AC-2.4 |
| A3 | Đường carom trong gợi ý lấy từ solver đã có trong `tools/solver/` | AC-1.2 |
| A9 | Bộ đếm thua theo màn được **lưu cùng tiến trình**, không phải biến tạm theo phiên | US-003 AC-1.4 |
| A8 | Mọi chuỗi mới có ở **cả** `app_vi.arb` và `app_en.arb`, VI mặc định | AC-3.4 |

## User stories

### US-001: Mua gợi ý đường carom bằng xu

**User Story**: As a Người chơi, I want mua một gợi ý chỉ ra đường carom giải được
màn hiện tại, so that tôi không phải bỏ game ở một màn mình không tự nhìn ra hình
học

**Priority**: High
**Business Value**: PDR §10 xác định "tắc hẳn" là rủi ro sản phẩm thật của cơ chế
dội tường. Đây cũng là chỗ tiêu xu đầu tiên, biến xu từ số trang trí thành tài
nguyên.
**Dependencies**: None

**Acceptance Criteria**:

**1. Mua và hiển thị gợi ý**

1.1 WHEN người chơi đang ở màn chơi và bấm nút gợi ý THEN system SHALL:
- trừ **50 xu** khỏi số dư
- lưu số dư mới xuống bộ nhớ cục bộ ngay, không chờ tới lúc kết màn
- hiện đường carom của một cú giải được màn hiện tại

1.2 WHEN gợi ý được hiện THEN system SHALL vẽ **trọn** quỹ đạo của một cú bắn hợp
lệ do solver sinh ra: từ bệ phóng, qua từng điểm dội, tới mục tiêu cuối mà cú đó
phá được.

1.3 WHILE gợi ý đang hiện THEN system SHALL:
- vẽ đường gợi ý **khác biệt rõ** với vệt ma của cú bắn trước và với preview ngắm,
  để người chơi không nhầm ba lớp đường với nhau
- giữ đường gợi ý trên màn hình cho tới khi người chơi bắn cú tiếp theo
- không tự động ngắm hộ, không tự bắn: người chơi vẫn phải tự kéo và tự thả

1.4 WHEN người chơi bắn sau khi xem gợi ý THEN system SHALL xoá đường gợi ý và
tính điểm, sao, hệ số BỪA **y như một cú bắn bình thường** — mua gợi ý không hạ
điểm và không hạ mốc sao.

1.5 WHILE gợi ý đang hiện THEN system SHALL giữ nguyên luật preview ngắm hiện tại:
preview thụ động vẫn **chỉ hiện hai đoạn đầu** quỹ đạo và vẫn bị ẩn khi bóng đang
bay (`uiux-guideline.md` §"Preview ngắm", luật `[Confirmed]`).

**2. Không đủ xu**

2.1 IF số dư xu < 50 WHEN người chơi mở màn chơi THEN system SHALL:
- hiện nút gợi ý ở trạng thái vô hiệu, **vẫn nhìn thấy được**
- nêu rõ lý do và giá còn thiếu, không im lặng bỏ qua cú bấm

2.2 IF người chơi bấm nút gợi ý đang vô hiệu THEN system SHALL không trừ xu, không
hiện gợi ý, và không rời khỏi màn chơi.

**3. Trạng thái và ràng buộc**

3.1 WHEN người chơi đã mua gợi ý cho màn hiện tại và chơi lại cùng màn đó trong
cùng một lượt vào màn THEN system SHALL hiện lại gợi ý đã mua **mà không trừ xu
lần hai**.

3.2 WHEN người chơi thoát khỏi màn chơi rồi vào lại THEN system SHALL coi gợi ý là
chưa mua cho lượt mới.

3.3 IF solver không tìm được cú giải được cho trạng thái sân hiện tại THEN system
SHALL không trừ xu và cho người chơi biết gợi ý không dùng được ở trạng thái này.

3.4 WHEN bất kỳ chuỗi văn bản mới nào được thêm cho tính năng này THEN system SHALL
có bản dịch ở **cả** `app_vi.arb` và `app_en.arb`, với VI là ngôn ngữ mặc định.

3.5 WHEN nút gợi ý được đặt lên HUD màn chơi THEN system SHALL giữ vùng chạm tối
thiểu **48px** (`tapMin`) và không che sân đấu ở vùng bóng bay.

3.6 WHEN xu bị trừ cho bất kỳ giao dịch nào THEN system SHALL không bao giờ để số dư
xuống dưới **0**, kể cả khi hai giao dịch xảy ra sát nhau.

---

### US-002: Bỏ qua màn đang tắc bằng xu

**User Story**: As a Người chơi, I want bỏ qua một màn tôi không giải được, so that
một màn quá khó không chặn tôi khỏi toàn bộ nội dung còn lại

**Priority**: High
**Business Value**: Luật mở màn hiện tại là tuyến tính (`unlockedMax = completedMax
+ 1`), nên một màn bí chặn **toàn bộ** phần còn lại của game. Đây là van an toàn
cho rủi ro số một ở PDR §10.
**Dependencies**: None

**Acceptance Criteria**:

**1. Điều kiện xuất hiện**

1.1 WHEN người chơi thua màn hiện tại **3 lần liên tiếp** mà chưa từng hoàn thành
màn đó THEN system SHALL hiện lựa chọn bỏ qua màn trên màn hình kết quả.

1.2 IF người chơi đã hoàn thành màn đó trước đây THEN system SHALL không hiện lựa
chọn bỏ qua màn, vì màn sau đã mở.

**2. Trả phí và hiệu lực**

2.1 WHEN người chơi chọn bỏ qua màn và có tối thiểu **150 xu** THEN system SHALL:
- trừ 150 xu và lưu số dư mới xuống bộ nhớ cục bộ
- mở màn kế tiếp
- đưa người chơi tới màn kế tiếp hoặc về bản đồ chọn màn

2.2 IF số dư xu < 150 THEN system SHALL hiện lựa chọn bỏ qua ở trạng thái vô hiệu
kèm giá và số xu còn thiếu, không trừ xu.

2.3 WHEN người chơi chọn bỏ qua màn THEN system SHALL yêu cầu xác nhận một lần
trước khi trừ xu, vì đây là hành động tiêu tài nguyên và ghi vào tiến trình.

2.4 WHEN màn được bỏ qua THEN system SHALL ghi màn đó là hoàn thành **0 sao** và:
- không ghi điểm cao cho màn đó
- không thu xu từ màn đó
- vẫn cho phép chơi lại màn đó bất cứ lúc nào để lấy sao thật

2.5 WHEN màn được bỏ qua với 0 sao THEN system SHALL vẫn mở màn kế tiếp.

2.6 WHEN trạng thái mở màn được suy ra THEN system SHALL coi "đã bỏ qua" là một
điều kiện mở màn **riêng**, độc lập với số sao, sao cho:
- màn bỏ qua mở được màn kế tiếp dù có 0 sao
- màn bỏ qua **không** đóng góp sao nào vào tổng sao của người chơi
- "thắng thật" vẫn là một trạng thái phân biệt được với "đã bỏ qua"

> **Ràng buộc từ code hiện tại [đã giải quyết ở mức luật]**: luật mở màn hiện suy ra
> từ sao (`isCompleted(levelId) => starsFor(levelId) >= 1`, rồi `unlockedMax =
> completedMax + 1` trong `lib/domain/player_progress.dart`), nên nếu chỉ ghi 0 sao
> thì AC-2.4 và AC-2.5 không thể cùng đúng. AC-2.6 là cách giải: tách "đã bỏ qua"
> khỏi số sao thay vì tặng sao giả. Tặng 1 sao cho màn bỏ qua đã được cân và **loại**
> — nó làm `totalStars` đếm cả sao người chơi chưa lấy, tức phá tiến độ sao theo
> chương ở `003_arena-map-chapters`.

**3. Hiển thị trên bản đồ**

3.1 WHEN màn đã bỏ qua được hiện trên bản đồ chọn màn THEN system SHALL phân biệt
nó với màn hoàn thành thật, để người chơi biết mình còn sao chưa lấy ở đó.

3.2 WHEN người chơi chơi lại và thắng một màn đã bỏ qua THEN system SHALL ghi sao
và điểm cao bình thường, và bỏ dấu "đã bỏ qua".

---

### US-003: Được nhắc rằng có đường ra khi đang tắc

**User Story**: As a Người chơi, I want game cho tôi biết gợi ý và bỏ qua màn đang
tồn tại đúng lúc tôi bí, so that tôi không bỏ game vì tưởng mình hết cách

**Priority**: Medium
**Business Value**: Một van an toàn người chơi không biết là không có van. Chi phí
nhỏ, nhưng nó quyết định US-001 và US-002 có thực sự cứu được người chơi hay không.
**Dependencies**: US-001, US-002 — không có gì để nhắc trước khi hai story đó xong

**Acceptance Criteria**:

**1. Thời điểm nhắc**

1.1 WHEN người chơi thua cùng một màn **lần thứ 2** THEN system SHALL nhắc trên
màn hình kết quả rằng có thể mua gợi ý, kèm giá.

1.2 WHEN người chơi thua cùng một màn **lần thứ 3** THEN system SHALL nhắc cả gợi
ý và bỏ qua màn, kèm giá của từng lựa chọn.

1.3 WHEN người chơi thắng màn đó THEN system SHALL đặt lại bộ đếm thua của màn đó
về 0.

1.4 WHEN người chơi tắt app rồi mở lại THEN system SHALL giữ nguyên bộ đếm thua của
từng màn. Bộ đếm **không** được reset theo phiên chơi: người chơi bí tới mức tắt app
chính là người cần được nhắc nhất, và họ sẽ không thua thêm 3 lần nữa chỉ để nghe
lời nhắc đó.

1.5 WHEN tiến trình được xoá từ Cài đặt THEN system SHALL đặt lại mọi bộ đếm thua về
0 cùng với phần tiến trình còn lại.

**2. Không gây khó chịu**

2.1 WHILE người chơi đang trong một cú bắn THEN system SHALL không hiện bất kỳ nhắc
nhở nào — chỉ nhắc trên màn hình kết quả.

2.2 WHEN nhắc nhở được hiện THEN system SHALL luôn kèm lựa chọn tiếp tục thử lại,
và lựa chọn đó SHALL không kém nổi bật hơn gợi ý/bỏ qua màn.

2.3 IF người chơi bỏ qua nhắc nhở THEN system SHALL không hiện lại cùng nhắc nhở
đó cho tới lần thua tiếp theo của cùng màn.

## Dependency Notes

- **Xu là tài nguyên tiêu được lần đầu tiên ở artifact này.** US-001 AC-3.6 ("số dư
  không bao giờ xuống dưới 0") là luật chung cho **cả** US-001 và US-002, không phải
  luật riêng của gợi ý.
- **US-003 phụ thuộc bộ đếm thua theo màn** (AC-1.4), thứ cũng là điều kiện xuất hiện
  của US-002 AC-1.1. Làm bộ đếm đó **một lần**, dùng cho cả hai — đừng dựng hai bộ
  đếm song song.
- **Không ảnh hưởng `003_arena-map-chapters`.** AC-2.6 cố tình giữ tổng sao sạch, nên
  tiến độ sao theo chương ở 003 không cần biết gì về bỏ qua màn.
- **Đi sau playtest.** PDR §11 đặt playtest 20 màn trước mọi việc thêm; nhưng nếu
  playtest cho thấy người chơi tắc thật, artifact này là thứ nên làm ngay sau đó.
