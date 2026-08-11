---
artifact_type: story-artifact
phase: inception
status: draft
created: 2026-08-05
updated: 2026-08-09
intent: haptics-and-characters
source_artifacts:
  - aidlc-docs/foundation/project-overview-pdr.md
  - aidlc-docs/foundation/system-architecture.md
  - aidlc-docs/foundation/uiux-guideline.md
---

# User Stories: Haptics và nhân vật có tên

## Overview

Hai mục cuối trong danh sách "trong phạm vi, chưa làm" của PDR §9: **haptics** và
**nhân vật có tên và thoại**. Cả hai đều là tầng cảm giác, không đổi luật chơi, và
cả hai đều nhỏ — nên gom vào một artifact.

Điểm chung đáng chú ý: game đã có sẵn **khuôn mặt biểu cảm trên mục tiêu** đang làm
việc kể chuyện (`uiux-guideline.md` §4.3 và §5.2 coi đổi biểu cảm là một kênh bắt
buộc của tín hiệu `armed`)
và một mascot trong `assets/images/mascot/`. Nhân vật có tên là bước tiếp của thứ đã
tồn tại, không phải một hệ thống mới dựng từ đầu.

### Giả định đang chờ xác nhận

| # | Giả định | Sửa ở đâu nếu sai |
|---|---|---|
| A6 | Haptics có **toggle riêng** trong Cài đặt, mặc định **bật**, theo đúng pattern `soundOn` / `musicOn` của `AppSettings` | US-002 |
| A6b | Cooldown rung **60ms** — con số khởi điểm để tune khi cầm máy thật, không phải giá trị đã đo | AC-2.1 |
| A7 | Story chỉ định nghĩa **hệ thống thoại** (khi nào hiện, ở đâu, không chặn gameplay, song ngữ). **Tên và lời thoại cụ thể chưa chốt** — do Construction viết | US-003 |
| A8 | Mọi chuỗi mới có ở **cả** `app_vi.arb` và `app_en.arb`, VI mặc định | AC-3.5 |

## User stories

### US-001: Cảm được cú dội qua rung tay

**User Story**: As a Người chơi, I want cảm được từng cú dội và từng mục tiêu vỡ qua
rung tay, so that cú bắn có sức nặng vật lý chứ không chỉ là hình ảnh trên kính

**Priority**: Low
**Business Value**: Game chơi dọc một ngón tay, mắt dán vào đường carom. Rung là
kênh phản hồi duy nhất **không** cạnh tranh với thứ mắt đang phải theo — và tầng
hình ảnh đã khá đông (quầng armed, vệt bay, vệt ma, tem chữ, hệ số sống).
**Dependencies**: None

**Acceptance Criteria**:

**1. Sự kiện có rung**

1.1 WHEN bi dội tường, khối chắn, hoặc vật cản chéo THEN system SHALL phát một rung
nhẹ, ngắn.

1.2 WHEN một mục tiêu bị phá THEN system SHALL phát một rung mạnh hơn rung dội, khớp
với cú rung màn hiện có.

1.3 WHEN cú bắn thẳng bị chặn (chưa đủ số lần dội) THEN system SHALL phát một rung
khác biệt về cảm giác với rung phá mục tiêu, vì đây là tín hiệu **sai ý tưởng**,
không phải tín hiệu thành công.

1.4 WHEN màn kết thúc thắng hoặc thua THEN system SHALL phát một rung kết màn.

**2. Không rung quá dày**

2.1 WHEN nhiều va chạm xảy ra sát nhau trong một cú bắn THEN system SHALL giữ tối
thiểu **60ms** giữa hai lần rung, bỏ qua rung của va chạm nằm trong khoảng đó — cùng
nguyên tắc cooldown mà `game_audio_service.dart` đã dùng cho âm thanh.

2.2 WHEN bi rơi ra khỏi đáy sân THEN system SHALL không phát rung phá mục tiêu, vì
cú đó đã mất.

2.3 WHILE người chơi đang kéo để ngắm THEN system SHALL không phát rung, để thao tác
ngắm không bị nhiễu.

**3. Thiết bị không hỗ trợ**

3.1 IF thiết bị không có bộ rung hoặc không cho phép rung THEN system SHALL bỏ qua
rung một cách im lặng và SHALL không hiện lỗi, không chặn gameplay.

3.2 IF người chơi đã tắt rung trong Cài đặt THEN system SHALL không phát rung nào.

---

### US-002: Tắt rung được

**User Story**: As a Người chơi, I want tắt rung, so that tôi chơi được ở chỗ cần
yên tĩnh hoặc khi rung làm tôi thấy khó chịu

**Priority**: Low
**Business Value**: Rung là thứ chia đôi người dùng — nhóm thấy sướng và nhóm thấy
phiền. Không có công tắc thì US-001 tự biến thành một lý do gỡ game.
**Dependencies**: US-001 — không có gì để tắt trước khi rung tồn tại

**Acceptance Criteria**:

**1. Công tắc trong Cài đặt**

1.1 WHEN người chơi mở màn hình Cài đặt THEN system SHALL hiện một công tắc rung
đặt cùng nhóm với công tắc Âm thanh và Nhạc nền, dùng cùng component `BbToggle`.

1.2 WHEN người chơi mới mở app lần đầu THEN system SHALL đặt rung **bật** làm mặc
định.

1.3 WHEN người chơi bật hoặc tắt công tắc rung THEN system SHALL:
- áp dụng ngay, không cần khởi động lại app
- lưu lựa chọn xuống bộ nhớ cục bộ

1.4 WHEN người chơi mở lại app THEN system SHALL khôi phục đúng lựa chọn rung đã lưu.

1.5 IF không đọc được lựa chọn đã lưu THEN system SHALL dùng mặc định **bật** và
SHALL không làm màn hình Cài đặt hỏng.

1.6 WHEN nhãn công tắc rung được thêm THEN system SHALL có bản dịch ở **cả**
`app_vi.arb` và `app_en.arb`.

---

### US-003: Nhân vật có tên nói chuyện với tôi

**User Story**: As a Người chơi, I want game có một nhân vật có tên nói với tôi ở
những khoảnh khắc quan trọng, so that game có giọng riêng thay vì chỉ là hình học và
con số

**Priority**: Low
**Business Value**: PDR §5 nói khoảnh khắc quan trọng nhất của game là cú bắn thẳng
đầu tiên bị nảy ra, và tín hiệu đó hiện chỉ là bốn chữ `Bắn thẳng à?`. Nếu câu đó có
một nhân vật đứng sau, khoảnh khắc dạy chơi thành khoảnh khắc có tính cách — và PDR
§10 xếp "gây tò mò hay gây khó hiểu?" là câu hỏi số một chưa ai trả lời.
**Dependencies**: None

**Acceptance Criteria**:

**1. Nhân vật và giọng**

1.1 WHEN nhân vật xuất hiện THEN system SHALL dùng **một** nhân vật có tên xuyên
suốt game, không đổi tên hay đổi giọng giữa các màn hình.

1.2 WHEN nhân vật cần hình ảnh THEN system SHALL dùng mascot đã có trong
`assets/images/mascot/` và SHALL không yêu cầu asset ảnh mới.

**2. Khi nào nói**

2.1 WHEN người chơi vào game lần đầu THEN system SHALL cho nhân vật giới thiệu luật
dội tường ở overlay hướng dẫn hiện có, thay cho văn bản không có giọng.

2.2 WHEN màn kết thúc thắng hoặc thua THEN system SHALL cho nhân vật nói một câu phù
hợp với kết quả đó.

2.3 WHEN người chơi thắng màn 20 — màn cuối THEN system SHALL cho nhân vật có một
câu kết chiến dịch, khác với câu thắng màn thường.

**3. Không cản đường chơi**

3.1 WHILE bi đang bay THEN system SHALL không hiện thoại nhân vật — khoảnh khắc đó
thuộc về sân đấu.

3.2 WHEN thoại nhân vật được hiện THEN system SHALL luôn cho người chơi bỏ qua hoặc
đóng nó bằng một thao tác, và SHALL không bắt chờ hết thoại.

3.3 WHEN người chơi đã xem một đoạn thoại một lần THEN system SHALL không bắt xem
lại đoạn đó ở lần sau, trừ thoại kết quả màn.

3.4 WHEN thoại nhân vật được hiện THEN system SHALL không che tín hiệu `armed` của
mục tiêu và không che sân đấu trong lúc chơi.

3.5 WHEN bất kỳ lời thoại nào được thêm THEN system SHALL có bản dịch ở **cả**
`app_vi.arb` và `app_en.arb`, với VI là mặc định, và giọng nhân vật SHALL giữ được ở
cả hai ngôn ngữ chứ không chỉ dịch nghĩa.

3.6 WHEN thoại được trình bày trong hướng dẫn hoặc kết quả THEN system SHALL dùng
panel karst jade/teal có khung bronze/gold, chữ cream/muted và scrim tối khi là
modal. Hướng dẫn modal dùng CTA gold + secondary hiện hành; thoại nhúng trong kết
quả SHALL không cạnh tranh với CTA chính Thử lại/Tiếp theo. Không dựng card
trắng/coral, panel galaxy/navy độc lập hoặc một kiểu popup thứ tư.

## Dependency Notes

- **US-001 → US-002**: công tắc chỉ có nghĩa sau khi rung tồn tại. Làm US-001 trước,
  nhưng làm cả hai trong cùng một lần giao là hợp lý — thả US-001 một mình ra người
  chơi là thả một tính năng không tắt được.
- **US-003 độc lập** với hai story rung, có thể làm song song.
- **Chờ playtest**: PDR §11 đặt playtest 20 màn **trước** mọi việc thêm. Cả ba story
  ở đây là tầng cảm giác, nên chúng nên đi sau khi câu hỏi "vòng chơi này có vui
  không?" ở PDR §10 đã có câu trả lời.
