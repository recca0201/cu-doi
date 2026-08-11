---
artifact_type: requirements
phase: construction
status: draft
created: 2026-08-11
updated: 2026-08-11
unit: ho-so-nguoi-choi
source_artifacts:
  - aidlc-docs/foundation/project-overview-pdr.md
  - aidlc-docs/foundation/system-architecture.md
  - aidlc-docs/foundation/uiux-guideline.md
  - lib/domain/player_progress.dart
  - lib/data/progress_repository.dart
  - lib/state/providers.dart
  - lib/ui/screens/menu_screen.dart
  - pubspec.yaml
  - https://firebase.google.com/docs/auth/flutter/start
  - https://firebase.google.com/docs/auth/flutter/account-linking
  - https://firebase.google.com/docs/firestore/manage-data/enable-offline
  - https://firebase.google.com/docs/storage/flutter/upload-files
---

# Requirements: Hồ sơ người chơi

**Unit**: Hồ sơ người chơi và tài khoản Firebase
**Feature**: Hồ sơ khách hoặc tài khoản Google/Apple, đồng bộ Firebase, tiến trình, kỷ lục, huy hiệu, tên và avatar
**Created**: 2026-08-11
**User Stories**: US-1, US-2, US-3, US-4, US-5, US-6, US-7
**Estimation (BCP)**: Not yet estimated

---

## Introduction

Màn Hồ sơ biến thẻ người chơi hiện có trên màn chính thành một điểm tổng hợp tiến trình và
dấu ấn cá nhân. Người chơi được chơi ngay dưới dạng khách hoặc chủ động đăng nhập bằng
Google/Apple để bảo vệ và đồng bộ tiến trình, tên cùng avatar qua nhiều thiết bị.

Đây là thay đổi phạm vi và kiến trúc có chủ đích so với PDR hiện tại: Firebase Authentication
quản lý danh tính, Cloud Firestore lưu hồ sơ/tiến trình và Firebase Storage lưu ảnh avatar do
người chơi chọn. Ứng dụng vẫn local-first: khách không bị buộc tạo tài khoản; người đã đăng
nhập vẫn chơi được khi mất mạng và dữ liệu chờ tự đồng bộ khi có kết nối.

## Ràng buộc và quyết định đã chốt

| # | Nội dung | Trạng thái |
|---|---|---|
| D1 | Mở Hồ sơ bằng cách chạm thẻ hoặc avatar người chơi trên màn chính | Người dùng chốt 2026-08-11 |
| D2 | Tên mặc định là “Người chơi”; cho sửa tối đa 20 ký tự, bỏ khoảng trắng thừa và không cho lưu tên rỗng | Người dùng chốt 2026-08-11 |
| D3 | Avatar hỗ trợ cả bộ ảnh dựng sẵn và ảnh từ thiết bị | Người dùng chốt 2026-08-11 |
| D4 | Không lưu nhật ký từng lượt; chỉ dùng kỷ lục tốt nhất theo từng màn | Người dùng chốt 2026-08-11 |
| D5 | Huy hiệu được mở tự động từ dữ liệu tiến trình hiện có, không có nhiệm vụ hoặc bộ đếm gameplay mới | Người dùng chốt 2026-08-11 |
| D6 | Cho chơi khách ngay; đăng nhập Google/Apple là tùy chọn trong Hồ sơ, không chặn menu hay gameplay | Người dùng chốt 2026-08-11 |
| D7 | VI và EN đều được hỗ trợ; VI tiếp tục là ngôn ngữ mặc định | Ràng buộc từ sản phẩm hiện tại |
| D8 | Khi gộp tiến trình, mỗi màn lấy sao và điểm cao hơn; xu lấy số dư cao hơn, không cộng | Người dùng chốt 2026-08-11 |
| D9 | Tài khoản đăng nhập hoạt động local-first; khi offline vẫn chơi/lưu cục bộ rồi tự đồng bộ khi có mạng | Người dùng chốt 2026-08-11 |
| D10 | Mỗi Firebase UID có cache riêng; dữ liệu khách chưa có chủ chỉ được nhập vào tài khoản đầu tiên và không tự chuyển sang UID khác | Người dùng chốt 2026-08-11 |
| D11 | Tên và avatar đồng bộ qua Firebase; ảnh thiết bị lưu trên Firebase Storage, metadata và tiến trình lưu trên Firestore | Người dùng chốt 2026-08-11 |
| D12 | Cho phép liên kết Google và Apple vào cùng Firebase UID từ Hồ sơ; không tự ghép tài khoản chỉ dựa trên email | Người dùng chốt 2026-08-11 |
| D13 | Đăng xuất giữ một bản sao cục bộ để tiếp tục chơi khách; xóa tài khoản xóa Auth + cloud nhưng cũng giữ tiến trình cục bộ dưới dạng khách | Người dùng chốt 2026-08-11 |
| D14 | Quy tắc lấy số xu cao hơn ưu tiên đơn giản và tránh cộng trùng khi gộp, nhưng có thể khôi phục số xu đã tiêu nếu bản sao kia cũ hơn; đây là đánh đổi đã chấp nhận của yêu cầu D8 | Hệ quả cần Phase 2 ghi rõ và kiểm thử |

## Requirements

### US-1: Mở và xem tổng quan hồ sơ

**User Story**: As a Người chơi, I want mở hồ sơ từ danh tính của mình trên màn chính, so that tôi có thể nhanh chóng xem tiến trình và thành quả cá nhân

**Priority**: High
**Business Value**: Thẻ người chơi hiện đã chiếm vị trí nổi bật trên menu nhưng chưa có hành động; biến nó thành lối vào Hồ sơ làm rõ ý nghĩa của danh tính và dữ liệu tiến trình đang tích lũy.
**Dependencies**: None

**Acceptance Criteria**:

**1. Điểm vào và điều hướng**

1.1 WHEN người chơi chạm vào avatar hoặc vùng thẻ danh tính trên màn chính THEN system SHALL mở màn Hồ sơ người chơi.

1.2 WHEN người chơi quay lại từ màn Hồ sơ THEN system SHALL trở về màn chính và giữ nguyên trạng thái điều hướng trước đó.

1.3 WHEN thẻ danh tính được hiển thị trên màn chính THEN system SHALL:
- thể hiện toàn bộ vùng thẻ và avatar là một control có thể chạm
- có vùng chạm tối thiểu 48dp
- có semantic label mô tả hành động mở hồ sơ
- không làm mất nút Cài đặt hoặc các bộ đếm xu và sao hiện có

**2. Tổng quan hồ sơ**

2.1 WHEN màn Hồ sơ tải thành công THEN system SHALL hiển thị:
- avatar hiện tại
- tên người chơi hiện tại
- tổng sao trên tối đa 60 sao
- số xu hiện có
- số màn đã hoàn thành thật trên tổng số 20 màn
- điểm cao nhất đạt được trong một màn

2.2 WHEN tính số màn đã hoàn thành thật THEN system SHALL chỉ đếm màn có ít nhất 1 sao; màn chỉ được bỏ qua SHALL không được tính là đã hoàn thành.

2.3 WHEN người chơi chưa hoàn thành màn nào THEN system SHALL hiển thị các giá trị tiến trình bằng 0 và một lời khích lệ ngắn, không hiển thị lỗi hoặc placeholder kỹ thuật.

2.4 WHILE dữ liệu tiến trình cục bộ chưa khôi phục xong THEN system SHALL hiển thị trạng thái tải ổn định thay cho các số liệu; WHEN có snapshot đã khôi phục THEN system SHALL chỉ hiển thị snapshot đó và không chuyển ngược sang hồ sơ rỗng trong cùng lần mở màn.

2.5 WHEN người chơi là khách THEN system SHALL hiển thị trạng thái “Đang chơi với tư cách khách” và CTA đăng nhập; WHEN người chơi đã đăng nhập THEN system SHALL hiển thị trạng thái tài khoản, các provider đã liên kết và trạng thái đồng bộ gần nhất.

**3. Trình bày và khả năng tiếp cận**

3.1 WHEN màn Hồ sơ được hiển thị THEN system SHALL tuân theo hệ karst adventure
arcade của `uiux-guideline.md`: backdrop karst, panel jade/teal, khung
bronze/gold, CTA chính vàng và bóng sticker cứng; SHALL không dùng shell
galaxy/indigo/navy.

3.2 WHEN nội dung vượt quá chiều cao khả dụng THEN system SHALL cho phép cuộn dọc, giữ nút quay lại trong safe area và không cắt nội dung ở phone nhỏ hoặc tablet.

3.3 WHEN text scale của hệ thống tăng THEN system SHALL cho phép nội dung reflow hoặc cuộn thay vì cắt mất tên, số liệu hay nhãn control.

3.4 WHEN số liệu hoặc trạng thái được biểu đạt bằng màu THEN system SHALL kèm chữ, icon hoặc hình dạng; màu không được là kênh truyền đạt duy nhất.

3.5 WHEN bất kỳ chuỗi mới nào của Hồ sơ được thêm THEN system SHALL có bản dịch ở cả tiếng Việt và tiếng Anh, với tiếng Việt là mặc định.

---

### US-2: Đổi và đồng bộ tên người chơi

**User Story**: As a Người chơi, I want đặt tên hiển thị local-first và đồng bộ tên khi đăng nhập, so that danh tính của tôi nhất quán trên thiết bị hiện tại và các thiết bị khác

**Priority**: High
**Business Value**: Một tên ngắn do người chơi chọn tạo cảm giác sở hữu; local-first giữ trải nghiệm khách tức thời, còn Firebase bảo vệ danh tính khi người chơi chủ động đăng nhập.
**Dependencies**: US-1

**Acceptance Criteria**:

**1. Giá trị mặc định và chỉnh sửa**

1.1 WHEN chưa có tên người chơi được lưu THEN system SHALL dùng “Người chơi” trong tiếng Việt và bản dịch tương ứng trong tiếng Anh làm tên hiển thị mặc định.

1.2 WHEN người chơi chọn chỉnh sửa tên THEN system SHALL hiển thị control nhập liệu với giá trị hiện tại, hành động Lưu và hành động Hủy.

1.3 WHEN người chơi lưu tên hợp lệ THEN system SHALL:
- bỏ khoảng trắng ở đầu và cuối
- thay mỗi chuỗi khoảng trắng liên tiếp bên trong bằng một khoảng trắng
- lưu tên đã chuẩn hóa trên thiết bị
- cập nhật tên trên màn Hồ sơ và thẻ người chơi ở màn chính ngay trong phiên hiện tại

**2. Kiểm tra hợp lệ và an toàn dữ liệu**

2.1 WHEN đếm độ dài tên THEN system SHALL giới hạn tối đa 20 ký tự người dùng nhìn thấy, không cắt giữa một emoji hoặc cụm ký tự Unicode.

2.2 IF tên sau khi chuẩn hóa là rỗng THEN system SHALL:
- không lưu
- giữ nguyên tên đã lưu trước đó
- hiển thị thông báo lỗi dễ hiểu ngay tại vùng nhập

2.3 IF tên vượt quá 20 ký tự người dùng nhìn thấy THEN system SHALL không cho lưu và SHALL hiển thị số ký tự tối đa.

2.4 WHEN người chơi chọn Hủy hoặc rời luồng chỉnh sửa mà chưa lưu THEN system SHALL giữ nguyên tên trước đó.

2.5 IF lần ghi tên thất bại THEN system SHALL giữ tên đã lưu trước đó, báo không thể lưu và cho phép thử lại mà không làm mất nội dung đang nhập.

**3. Lưu trữ và tương thích**

3.1 WHEN người chơi đóng rồi mở lại ứng dụng THEN system SHALL khôi phục tên từ cache cục bộ tương ứng với khách hoặc Firebase UID hiện tại mà không cần mạng.

3.2 WHEN ứng dụng đọc dữ liệu từ phiên bản cũ chưa có trường tên THEN system SHALL dùng tên mặc định và SHALL giữ nguyên sao, điểm cao, xu, trạng thái bỏ qua và số lần thua đã có.

3.3 WHEN tên được hiển thị trong không gian hẹp THEN system SHALL co hoặc lược bớt phần trình bày một cách dễ đọc, không làm tăng chiều cao thẻ đến mức đẩy các control chính khỏi viewport.

3.4 WHEN khách đăng nhập lần đầu và tài khoản chưa có tên tùy chỉnh THEN system SHALL dùng tên khách đã lưu làm tên tài khoản; IF tài khoản đã có tên THEN system SHALL giữ tên tài khoản.

3.5 WHEN người đã đăng nhập lưu tên hợp lệ THEN system SHALL cập nhật cache cục bộ ngay và xếp thay đổi vào hàng đợi đồng bộ Firestore; IF đang offline THEN system SHALL giữ trạng thái chờ đồng bộ mà không chặn người chơi tiếp tục.

---

### US-3: Chọn và đồng bộ avatar

**User Story**: As a Người chơi, I want chọn avatar dựng sẵn hoặc ảnh từ thiết bị và đồng bộ nó khi đăng nhập, so that tôi nhận diện hồ sơ theo cách mình thích trên mọi thiết bị

**Priority**: High
**Business Value**: Avatar tạo tín hiệu cá nhân hóa mạnh nhất trên một màn hồ sơ nhỏ; khách vẫn dùng hoàn toàn cục bộ, còn tài khoản có thể khôi phục avatar qua Firebase.
**Dependencies**: US-1

**Acceptance Criteria**:

**1. Avatar dựng sẵn**

1.1 WHEN người chơi mở bộ chọn avatar THEN system SHALL hiển thị tối thiểu 6 avatar dựng sẵn phù hợp art direction của game, bao gồm avatar mặc định hiện tại.

1.2 WHEN người chơi chọn một avatar dựng sẵn THEN system SHALL hiển thị trạng thái đang chọn trước khi xác nhận và SHALL không chỉ dùng màu để biểu đạt lựa chọn.

1.3 WHEN người chơi xác nhận avatar dựng sẵn THEN system SHALL lưu lựa chọn cục bộ và cập nhật avatar ở Hồ sơ cùng thẻ người chơi trên màn chính.

**2. Ảnh từ thiết bị**

2.1 WHEN người chơi chọn “Ảnh từ thiết bị” THEN system SHALL mở bộ chọn ảnh do hệ điều hành cung cấp và chỉ yêu cầu quyền truy cập cần thiết tại thời điểm đó, không yêu cầu quyền khi khởi động app.

2.2 WHEN người chơi chọn được ảnh hợp lệ THEN system SHALL cho xem trước và căn/cắt ảnh theo khung vuông trước khi xác nhận; hình tròn chỉ là cách hiển thị avatar, không được phá hủy bản xem trước vuông.

2.3 WHEN người chơi xác nhận ảnh THEN system SHALL:
- tạo bản sao avatar đã xử lý trong vùng lưu trữ riêng của ứng dụng
- giới hạn cạnh dài của bản sao không quá 1024 pixel
- sửa hướng ảnh theo metadata trước khi lưu
- mã hóa bản upload-ready thành `image/jpeg` hoặc `image/webp`
- giảm chất lượng/kích thước để bản upload-ready không quá 2 MB
- không đưa ảnh vào telemetry và không chia sẻ ảnh cho ứng dụng khác
- cập nhật ảnh ở Hồ sơ và thẻ người chơi trên màn chính

2.4 IF người chơi hủy bộ chọn ảnh, hủy màn xem trước hoặc từ chối quyền THEN system SHALL giữ avatar hiện tại và SHALL không hiển thị lỗi chặn luồng.

2.5 IF tệp được chọn không đọc được hoặc không phải định dạng ảnh được hệ điều hành hỗ trợ THEN system SHALL giữ avatar hiện tại, thông báo ảnh không dùng được và cho phép chọn lại.

2.6 IF việc giải mã, căn/cắt, sao chép hoặc ghi ảnh thất bại sau khi người chơi xác nhận THEN system SHALL:
- giữ nguyên avatar đã lưu trước đó
- xóa mọi file tạm hoặc bản sao chưa hoàn tất của lần xử lý đó
- hiển thị thông báo dễ hiểu
- cho phép người chơi thử lại

2.7 IF không thể tạo ảnh JPEG/WebP đồng thời thỏa cạnh dài tối đa 1024 pixel và dung lượng tối đa 2 MB THEN system SHALL dùng cùng hành vi phục hồi ở AC-2.6 và SHALL không đưa file không hợp lệ vào hàng đợi upload.

**3. Quản lý avatar và khôi phục**

3.1 WHEN người chơi đóng rồi mở lại ứng dụng THEN system SHALL khôi phục avatar từ cache cục bộ tương ứng với khách hoặc Firebase UID hiện tại mà không cần mạng.

3.2 WHEN người chơi chọn quay về avatar mặc định THEN system SHALL yêu cầu xác nhận một lần, áp dụng avatar mặc định và xóa bản sao ảnh cá nhân không còn được dùng khỏi vùng lưu trữ của ứng dụng.

3.3 WHEN người chơi thay ảnh thiết bị bằng ảnh thiết bị khác hoặc avatar dựng sẵn THEN system SHALL xóa bản sao ảnh cũ sau khi lựa chọn mới được lưu thành công.

3.4 IF đường dẫn ảnh đã lưu không còn đọc được THEN system SHALL tự dùng avatar mặc định, giữ nguyên toàn bộ tiến trình và cho phép người chơi chọn ảnh khác.

3.5 WHEN ứng dụng đọc dữ liệu từ phiên bản cũ chưa có trường avatar THEN system SHALL dùng avatar mặc định hiện tại.

3.6 WHEN khách đăng nhập lần đầu và tài khoản chưa có avatar tùy chỉnh THEN system SHALL nhập avatar khách vào tài khoản; IF đó là ảnh thiết bị THEN system SHALL tải bản đã xử lý lên vùng Firebase Storage của UID sau khi xác thực thành công.

3.7 WHEN người đã đăng nhập xác nhận ảnh thiết bị mới THEN system SHALL cập nhật cache cục bộ ngay và tải ảnh lên vùng Firebase Storage chỉ UID đó được truy cập; IF đang offline THEN system SHALL giữ ảnh cục bộ cùng trạng thái chờ tải lên và tự thử lại khi có mạng.

3.8 WHEN tải avatar mới lên thành công THEN system SHALL cập nhật tham chiếu avatar trong Firestore trước khi xóa file cloud cũ; IF upload hoặc cập nhật metadata thất bại THEN system SHALL tiếp tục dùng avatar cũ trên cloud và cho phép thử lại.

3.9 WHEN người đã đăng nhập thay ảnh cloud bằng avatar dựng sẵn hoặc avatar mặc định THEN system SHALL:
- ghi tham chiếu avatar mới vào Firestore trước
- chỉ xóa file Storage cũ sau khi Firestore xác nhận thành công
- giữ trạng thái retry có thể tiếp tục IF cập nhật tham chiếu hoặc xóa file thất bại
- không làm avatar đang hiển thị trở thành ảnh hỏng trong bất kỳ trạng thái trung gian nào

**4. Quyền riêng tư và khả năng tiếp cận**

4.1 WHEN giải thích quyền chọn ảnh THEN system SHALL dùng nội dung ngắn, đúng mục đích “chọn và đồng bộ avatar”, có cả VI và EN và không tuyên bố ứng dụng cần truy cập toàn bộ thư viện nếu bộ chọn hệ thống không yêu cầu điều đó.

4.2 WHEN avatar là control tương tác THEN system SHALL có semantic label mô tả hành động; WHEN avatar chỉ để hiển thị THEN system SHALL không tạo focus thừa cho screen reader.

---

### US-4: Xem tiến trình chi tiết và huy hiệu

**User Story**: As a Người chơi, I want xem kỷ lục từng màn, tiến độ từng chương và huy hiệu đã mở, so that tôi biết mình đã làm tốt ở đâu và còn mục tiêu nào để chinh phục

**Priority**: Medium
**Business Value**: Dữ liệu tốt nhất theo màn đã tồn tại nhưng đang rời rạc; tổng hợp nó thành mục tiêu dài hạn tăng giá trị chơi lại mà không thay đổi luật chơi hoặc thêm nhật ký theo dõi mới.
**Dependencies**: US-1

**Acceptance Criteria**:

**1. Tiến độ theo chương**

1.1 WHEN hiển thị tiến độ chương THEN system SHALL chia đúng 20 màn thành 4 chương, mỗi chương 5 màn theo campaign hiện tại.

1.2 WHEN hiển thị một chương THEN system SHALL cho biết:
- số màn hoàn thành thật trên 5
- tổng sao đạt được trên 15
- trạng thái “Chưa mở” IF màn đầu chương chưa mở
- trạng thái “Đang tiến hành” IF màn đầu chương đã mở nhưng chưa đủ 5 màn có ít nhất 1 sao
- trạng thái “Đã hoàn thành” IF cả 5 màn có ít nhất 1 sao

1.3 WHEN xác định một chương đã hoàn thành THEN system SHALL yêu cầu cả 5 màn trong chương có ít nhất 1 sao; màn chỉ được bỏ qua SHALL không thỏa điều kiện.

**2. Kỷ lục tốt nhất theo màn**

2.1 WHEN hiển thị danh sách kỷ lục THEN system SHALL có đúng một mục cho mỗi màn từ 1 đến 20 với tên màn theo locale hiện tại.

2.2 WHEN một màn đã hoàn thành với ít nhất 1 sao THEN system SHALL hiển thị số sao tốt nhất và điểm cao nhất đã lưu của màn đó.

2.3 IF một màn chưa từng được hoàn thành nhưng đã được bỏ qua THEN system SHALL hiển thị trạng thái “Đã bỏ qua”, 0 sao và không trình bày điểm 0 như một kỷ lục.

2.4 IF một màn chưa hoàn thành và chưa được bỏ qua THEN system SHALL:
- hiển thị “Chưa mở” IF màn đó chưa mở theo tiến trình hiện tại
- hiển thị “Chưa hoàn thành” IF màn đó đã mở
- không hiển thị điểm 0 như một kỷ lục, kể cả khi `LevelResult` tồn tại chỉ vì đã ghi nhận một lần thua

2.5 WHEN người chơi đạt kết quả mới thấp hơn kỷ lục đã lưu THEN system SHALL tiếp tục hiển thị số sao và điểm cao nhất trước đó; không lưu lịch sử từng lượt.

**3. Huy hiệu tự động**

3.1 WHEN hiển thị khu vực Huy hiệu THEN system SHALL có một danh mục cố định gồm:
- “Ngôi sao đầu tiên”: tổng sao ít nhất 1
- “Ba sao trọn vẹn”: có ít nhất một màn đạt 3 sao
- bốn huy hiệu “Chinh phục Chương 1–4”: hoàn thành thật cả 5 màn của chương tương ứng
- “Phá đảo”: hoàn thành thật cả 20 màn
- “Bầu trời đầy sao”: đạt đủ 60 sao

3.2 WHEN điều kiện của một huy hiệu trở thành đúng THEN system SHALL tự mở huy hiệu từ dữ liệu tiến trình tốt nhất hiện có, không yêu cầu người chơi nhận thủ công.

3.3 WHEN một huy hiệu chưa mở THEN system SHALL hiển thị tên, điều kiện và tiến độ số học, giới hạn tử số không vượt mẫu số, theo công thức:
- “Ngôi sao đầu tiên”: tổng sao / 1
- “Ba sao trọn vẹn”: số màn đã đạt 3 sao / 1
- “Chinh phục Chương N”: số màn hoàn thành thật trong chương / 5
- “Phá đảo”: tổng màn hoàn thành thật / 20
- “Bầu trời đầy sao”: tổng sao / 60

3.4 WHEN một huy hiệu đã mở THEN system SHALL hiển thị trạng thái mở bằng ít nhất hai kênh như icon/outline và chữ, không chỉ đổi màu.

3.5 WHEN ứng dụng được nâng cấp từ phiên bản chưa có huy hiệu THEN system SHALL suy ra ngay các huy hiệu đã đủ điều kiện từ tiến trình cũ; SHALL không thêm trường trạng thái huy hiệu có thể lệch khỏi dữ liệu nguồn.

**4. Giới hạn thu thập dữ liệu**

4.1 WHEN tạo thống kê và huy hiệu THEN system SHALL chỉ dùng số sao tốt nhất, điểm cao nhất, xu, trạng thái hoàn thành/bỏ qua và cấu trúc campaign đã có.

4.2 WHEN người chơi hoàn thành hoặc thua một lượt THEN system SHALL không tạo nhật ký lượt chơi mới, không lưu timestamp và không bổ sung bộ đếm tổng lượt chơi, tổng thắng/thua hay tổng mục tiêu đã phá cho unit này.

4.3 WHEN tính hoặc hiển thị hồ sơ THEN system SHALL không thay đổi `lib/sim/`, luật dội, tham số cân bằng, dữ liệu sinh trong `arenas.dart`, điểm, sao hoặc quy tắc mở màn.

---

### US-5: Chơi khách hoặc đăng nhập Google/Apple

**User Story**: As a Người chơi, I want được chơi ngay mà không đăng nhập và có thể đăng nhập sau bằng Google hoặc Apple, so that tôi tự chọn giữa khởi đầu nhanh và bảo vệ tiến trình trên cloud

**Priority**: High
**Business Value**: Đăng nhập tùy chọn giữ trải nghiệm vào game trong một chạm, đồng thời tạo con đường bảo vệ dữ liệu cho người chơi gắn bó mà không dựng hệ thống mật khẩu riêng.
**Dependencies**: US-1

**Acceptance Criteria**:

**1. Chế độ khách mặc định**

1.1 WHEN người chơi mở ứng dụng lần đầu THEN system SHALL vào menu bằng hồ sơ khách cục bộ mà không buộc đăng nhập, không tạo Firebase UID ẩn danh và không cần kết nối mạng.

1.2 WHILE người chơi là khách THEN system SHALL cho phép đầy đủ gameplay, lưu tiến trình, đổi tên, chọn avatar dựng sẵn và chọn ảnh thiết bị như các story trước.

1.3 WHEN khách hoàn thành thật màn đầu tiên THEN system SHALL hiển thị đúng một nhắc nhở không chặn rằng đăng nhập sẽ bảo vệ tiến trình; nhắc nhở SHALL:
- không xuất hiện khi bi đang bay hoặc trước khi kết quả màn đã ổn định
- có hành động Đăng nhập và Bỏ qua
- không hiển thị lại sau khi người chơi đã bỏ qua hoặc đăng nhập

**2. Điểm vào đăng nhập**

2.1 WHEN người chơi là khách và mở Hồ sơ THEN system SHALL hiển thị CTA đăng nhập cùng hai lựa chọn riêng: “Tiếp tục với Google” và “Tiếp tục với Apple”.

2.2 WHEN lựa chọn Google hoặc Apple được hiển thị THEN system SHALL dùng nhãn, biểu tượng và cách trình bày tuân theo yêu cầu thương hiệu của provider, đồng thời có semantic label và vùng chạm tối thiểu 48dp.

2.3 WHEN người chơi chọn một provider THEN system SHALL dùng luồng xác thực Firebase Authentication của provider đó và SHALL không yêu cầu ứng dụng tự thu thập hoặc lưu mật khẩu Google/Apple.

2.4 WHEN đăng nhập thành công THEN system SHALL xác định Firebase UID, chuyển sang cache riêng của UID, chạy quy tắc gộp ở US-6 và chỉ báo hoàn tất sau khi đã có snapshot cục bộ an toàn để tiếp tục chơi.

**3. Hủy và lỗi đăng nhập**

3.1 IF người chơi hủy màn xác thực THEN system SHALL quay lại Hồ sơ khách, giữ nguyên toàn bộ dữ liệu và không hiển thị lỗi nghiêm trọng.

3.2 IF đăng nhập thất bại do mất mạng, cấu hình provider, credential hết hạn hoặc lỗi Firebase THEN system SHALL:
- giữ chế độ khách và dữ liệu hiện tại
- hiển thị thông báo dễ hiểu có thể thử lại
- không tạo hồ sơ cloud dở dang mà UI trình bày như đã đăng nhập

3.3 WHEN khách đăng nhập bằng credential đã thuộc một Firebase UID THEN system SHALL coi đó là đăng nhập bình thường vào UID đó và chạy US-6; IF một người đang đăng nhập UID A cố liên kết credential đã thuộc UID B THEN system SHALL không tự ghép hai UID dựa trên email và SHALL dùng xử lý xung đột ở US-7 AC-1.4.

---

### US-6: Tự gộp và đồng bộ hồ sơ Firebase

**User Story**: As a Người chơi đã đăng nhập, I want tiến trình được tự gộp và đồng bộ qua Firebase kể cả sau thời gian chơi offline, so that tôi tiếp tục từ thành quả tốt nhất trên các thiết bị mà không phải chọn bản lưu thủ công

**Priority**: High
**Business Value**: Đồng bộ đáng tin cậy là giá trị chính của đăng nhập; một lỗi gộp có thể làm mất sao, điểm hoặc xu và phá niềm tin mạnh hơn việc không có cloud ngay từ đầu.
**Dependencies**: US-2, US-3, US-4, US-5

**Acceptance Criteria**:

**1. Phạm vi dữ liệu cloud**

1.1 WHEN một Firebase UID có hồ sơ THEN system SHALL lưu trong Cloud Firestore dữ liệu cần thiết để khôi phục:
- tên đã chuẩn hóa và loại avatar/tham chiếu avatar
- xu hiện có
- kết quả tốt nhất theo từng màn gồm sao, điểm cao, trạng thái bỏ qua và số lần thua đang dùng
- metadata phiên bản schema và metadata đồng bộ cần thiết

> `losses` ở AC-1.1 là dữ liệu nguồn tương thích với schema tiến trình hiện có cho luồng gợi ý/bỏ qua màn, không phải thống kê hồ sơ mới và không tạo nhật ký từng lượt.

1.2 WHEN avatar là ảnh thiết bị THEN system SHALL lưu file đã xử lý trong Firebase Storage dưới namespace của UID và chỉ lưu tham chiếu hợp lệ trong Firestore.

1.3 WHEN huy hiệu, tổng sao, số màn hoàn thành, tiến độ chương hoặc trạng thái mở màn được đọc THEN system SHALL suy ra chúng từ dữ liệu nguồn sau gộp, không lưu các bản tổng hợp có thể lệch.

**2. Quy tắc gộp tất định**

2.1 WHEN gộp hai bản tiến trình của cùng một UID hoặc nhập dữ liệu khách chưa có chủ vào tài khoản đầu tiên THEN system SHALL tạo đúng một kết quả theo từng màn:
- `stars` = giá trị cao hơn
- `highScore` = giá trị cao hơn
- `skipped` = false IF kết quả sau gộp có ít nhất 1 sao; nếu không thì true khi một trong hai bản đã bỏ qua
- `losses` = giá trị cao hơn

2.2 WHEN gộp số dư xu THEN system SHALL lấy số cao hơn giữa hai bản, không cộng hai số dư và không cho kết quả âm.

2.3 WHEN gộp xong THEN system SHALL suy ra lại màn mở, tổng sao, số màn hoàn thành và huy hiệu từ kết quả đã gộp; SHALL không thay đổi luật mở màn hiện có.

2.4 WHEN tài khoản chưa có tên hoặc avatar tùy chỉnh THEN system SHALL nhập giá trị khách; IF tài khoản đã có giá trị tùy chỉnh THEN system SHALL giữ giá trị tài khoản ở lần nhận dữ liệu khách đầu tiên.

2.5 WHEN tên hoặc avatar được sửa bởi người đã đăng nhập THEN system SHALL gắn một `mutationId` ổn định, duy nhất và giữ mutation cục bộ ở trạng thái pending cho tới khi server xác nhận; hệ thống SHALL không loại mutation pending chỉ vì đọc được một snapshot cloud cũ hơn.

2.6 WHEN hai hay nhiều mutation tên/avatar của cùng UID đã được server xác nhận THEN system SHALL chọn thay đổi lớn nhất theo thứ tự toàn phần `(serverCommittedAt, mutationId)`; `serverCommittedAt` SHALL đến từ thời gian commit đáng tin cậy của server, client SHALL không tự chọn giá trị này, và cùng một `mutationId` được retry SHALL idempotent, không tạo thay đổi thứ hai.

2.7 WHEN quy tắc xu AC-2.2 chọn bản cũ có số dư cao hơn sau một lần tiêu xu offline THEN system SHALL chấp nhận số dư cao hơn là kết quả theo D14; hệ thống SHALL không âm thầm cộng thêm cả hai bản.

**3. Tách dữ liệu theo danh tính**

3.1 WHEN lưu cache cục bộ THEN system SHALL tách namespace khách và namespace của từng Firebase UID, không dùng chung một khóa tiến trình không có chủ sở hữu.

3.2 WHEN dữ liệu khách chưa có chủ xác thực thành công vào UID đầu tiên THEN system SHALL ghi bền vững claim cục bộ `guest → UID` trước khi bắt đầu gộp hoặc upload; IF ghi claim cục bộ thất bại THEN system SHALL không chuyển dữ liệu, không trình bày UI như đã đăng nhập, kết thúc phiên Firebase vừa tạo, báo lỗi và giữ khách an toàn.

3.3 WHEN claim `guest → UID` đã ghi nhưng gộp/upload bị gián đoạn hoặc thất bại THEN system SHALL giữ claim và trạng thái pending chỉ cho UID đó, tự tiếp tục khi có thể và SHALL không trả dữ liệu về pool khách chưa có chủ.

3.4 IF một UID khác đăng nhập trên cùng thiết bị THEN system SHALL tải cache/cloud của UID đó và SHALL không nhập dữ liệu khách đã được đánh dấu thuộc UID trước.

3.5 WHEN UID ban đầu đăng nhập lại THEN system SHALL gộp cache riêng của UID đó, bản sao khách có provenance từ UID đó và cloud của cùng UID; SHALL không đọc cache của UID khác.

**4. Local-first và đồng bộ lại**

4.1 WHEN người đã đăng nhập tạo tiến trình hoặc sửa hồ sơ THEN system SHALL ghi snapshot cục bộ trước để gameplay/UI tiếp tục, rồi xếp thay đổi cloud vào hàng đợi.

4.2 WHILE thiết bị mất mạng THEN system SHALL cho phép tiếp tục chơi và sửa hồ sơ, hiển thị trạng thái “Chờ đồng bộ” nhưng không chặn gameplay.

4.3 WHEN kết nối trở lại hoặc ứng dụng mở lại với mạng THEN system SHALL tự đọc bản cloud mới nhất, chạy gộp tất định, ghi kết quả về local và cloud rồi hiển thị “Đã đồng bộ” khi hoàn tất.

4.4 IF đồng bộ thất bại THEN system SHALL giữ snapshot cục bộ mới nhất, hiển thị trạng thái lỗi không chặn, tự thử lại có kiểm soát và cung cấp hành động thử lại từ Hồ sơ.

4.5 WHEN app bị đóng trong lúc đồng bộ THEN system SHALL không để lần mở sau chọn một snapshot thiếu field hoặc mất tiến trình; hàng đợi/chỉ dấu pending SHALL có thể tiếp tục sau khi khởi động lại.

**5. Bảo mật và quyền riêng tư**

5.1 WHEN Firestore nhận yêu cầu đọc/ghi hồ sơ THEN system SHALL thực thi Security Rules để:
- UID đã xác thực chỉ truy cập tài liệu thuộc chính UID đó
- chỉ chấp nhận field, kiểu dữ liệu và key được schema Phase 2 liệt kê
- ràng buộc `stars` trong 0..3, mọi điểm/xu/losses là số nguyên không âm trong giới hạn model, level ID trong 1..20 và chuỗi trong giới hạn đã đặc tả
- chỉ chấp nhận mutation metadata đúng schema, `mutationId` hợp lệ và `serverCommittedAt` do server gán
- từ chối field ngoài schema hoặc đường dẫn ngoài namespace user

5.2 WHEN Storage nhận upload avatar THEN system SHALL thực thi Security Rules để:
- UID đã xác thực chỉ đọc/ghi dưới đường dẫn avatar của chính UID đó
- chỉ chấp nhận ảnh đã xử lý có MIME `image/jpeg` hoặc `image/webp`
- từ chối object lớn hơn 2 MB
- từ chối mọi đường dẫn ngoài cấu trúc avatar Phase 2 quy định

5.3 WHILE người chơi là khách THEN system SHALL không gửi tên, avatar, tiến trình hoặc định danh thiết bị lên Firebase.

5.4 WHEN provider trả về token hoặc credential THEN system SHALL chỉ dùng chúng cho Firebase Authentication/linking và SHALL không lưu token provider dưới dạng dữ liệu hồ sơ thông thường.

5.5 WHEN dữ liệu được truyền tới Firebase THEN system SHALL chỉ gồm dữ liệu cần cho xác thực, đồng bộ hồ sơ và vận hành bảo mật; unit này SHALL không bật analytics, quảng cáo, leaderboard hoặc social graph.

---

### US-7: Quản lý provider, đăng xuất và xóa tài khoản

**User Story**: As a Người chơi đã đăng nhập, I want liên kết phương thức đăng nhập, đăng xuất hoặc xóa tài khoản, so that tôi kiểm soát cách truy cập và dữ liệu cloud của mình

**Priority**: High
**Business Value**: Tài khoản chỉ đáng tin khi người chơi có thể khôi phục đường đăng nhập và tự kiểm soát vòng đời dữ liệu mà không cần hỗ trợ thủ công.
**Dependencies**: US-5, US-6

**Acceptance Criteria**:

**1. Liên kết Google và Apple**

1.1 WHEN người đã đăng nhập mở phần Tài khoản trong Hồ sơ THEN system SHALL hiển thị Google và Apple với trạng thái đã liên kết/chưa liên kết.

1.2 WHEN người chơi chọn liên kết provider chưa có THEN system SHALL yêu cầu xác thực provider đó và liên kết credential vào Firebase UID hiện tại, không tạo hồ sơ tiến trình thứ hai khi liên kết thành công.

1.3 WHEN liên kết thành công THEN system SHALL cho phép người chơi dùng bất kỳ provider đã liên kết nào để quay lại cùng UID và cùng dữ liệu cloud.

1.4 IF credential provider đã thuộc Firebase UID khác THEN system SHALL:
- không tự liên kết hoặc tự gộp chỉ vì email giống nhau
- giữ nguyên tài khoản hiện tại
- giải thích credential đang thuộc tài khoản khác
- cho phép hủy và quay lại Hồ sơ mà không mất dữ liệu

1.5 IF liên kết bị hủy hoặc thất bại THEN system SHALL giữ nguyên danh sách provider và cho phép thử lại.

**2. Đăng xuất**

2.1 WHEN người chơi chọn Đăng xuất THEN system SHALL yêu cầu xác nhận và cho biết họ vẫn có thể tiếp tục chơi khách trên thiết bị này.

2.2 WHEN đăng xuất được xác nhận THEN system SHALL:
- chụp snapshot cục bộ đầy đủ của UID hiện tại
- đăng xuất Firebase Authentication
- giữ cache riêng của UID cho lần đăng nhập lại
- tạo/giữ bản sao khách có provenance từ UID đó để tiếp tục chơi ngay
- cập nhật Hồ sơ sang trạng thái khách

2.3 IF còn thay đổi chưa đồng bộ khi đăng xuất THEN system SHALL giữ chúng trong cache riêng của UID; WHEN cùng UID đăng nhập lại THEN system SHALL tiếp tục gộp/đồng bộ, không chuyển thay đổi đó sang UID khác.

2.4 WHEN người chơi đăng xuất trong lúc offline THEN system SHALL vẫn cho chuyển sang khách cục bộ; việc đăng xuất SHALL không xóa tiến trình chỉ vì không liên hệ được Firebase.

**3. Xóa tài khoản và dữ liệu cloud**

3.1 WHEN người chơi chọn Xóa tài khoản THEN system SHALL hiển thị xác nhận phá hủy nêu rõ:
- Firebase Authentication và dữ liệu cloud sẽ bị xóa
- thao tác cloud không thể hoàn tác
- tiến trình hiện tại trên thiết bị sẽ được giữ để chơi khách

3.2 WHEN Firebase/provider yêu cầu xác thực gần đây trước khi xóa THEN system SHALL yêu cầu người chơi xác thực lại bằng một provider đã liên kết trước khi tiếp tục.

3.3 WHEN xóa tài khoản được xác nhận và xác thực hợp lệ THEN system SHALL trước tiên tạo bền vững snapshot khách cục bộ cùng trạng thái `deletionPending` chứa UID và các bước cần hoàn tất; IF không ghi được snapshot/trạng thái này THEN system SHALL dừng trước khi xóa bất kỳ dữ liệu cloud nào.

3.4 WHEN `deletionPending` được tạo THEN system SHALL nguyên tử:
- dừng và vô hiệu mọi hàng đợi/nguồn ghi cloud cho UID đang xóa
- chuyển UI cùng mọi gameplay/chỉnh sửa hồ sơ tiếp theo sang snapshot khách được giữ lại
- tiếp tục cập nhật snapshot khách này bằng tiến trình mới trong suốt thời gian cleanup
- ngăn mọi retry hoặc listener tái tạo tài liệu/file của UID đã bắt đầu xóa

3.5 WHILE `deletionPending` THEN system SHALL thực hiện và ghi nhận idempotent từng bước theo đúng thứ tự:
1. xóa mọi avatar của UID trong Firebase Storage
2. xóa tài liệu hồ sơ/tiến trình của UID trong Firestore
3. thu hồi mọi liên kết/ủy quyền mà từng provider đã liên kết yêu cầu
4. chỉ sau khi ba bước trên thành công, xóa Firebase Authentication user **cuối cùng**

3.6 WHEN tất cả bước ở AC-3.5 hoàn tất THEN system SHALL:
- báo xóa tài khoản thành công
- giữ snapshot khách mới nhất, gồm cả tiến trình phát sinh trong lúc cleanup, dưới dạng dữ liệu chưa gắn UID
- xóa cache và metadata đăng nhập/deletion của UID đã xóa
- cho phép chơi tiếp ngay dưới dạng khách

3.7 IF một bước bắt buộc ở AC-3.5 thất bại THEN system SHALL:
- không xóa Auth user khi các bước đứng trước chưa hoàn tất
- không báo “Đã xóa tài khoản”
- giữ snapshot khách và trạng thái `deletionPending` với checkpoint bước đã hoàn tất
- cho phép retry tiếp từ checkpoint bằng cùng UID/credential hợp lệ
- không cho UID khác nhận hoặc đọc dữ liệu đang chờ xóa
- cung cấp đường liên hệ hỗ trợ IF retry không thể hoàn tất

3.8 IF người chơi hủy xác nhận hoặc hủy xác thực lại trước khi `deletionPending` được tạo THEN system SHALL không xóa tài khoản, dữ liệu cloud hoặc cache cục bộ.

---

## Ngoài phạm vi

- Leaderboard, chia sẻ hồ sơ, kết bạn, mạng xã hội, telemetry hoặc analytics.
- Email/mật khẩu, số điện thoại, đăng nhập ẩn danh Firebase hoặc provider ngoài Google/Apple.
- Tự động hợp nhất hai Firebase UID khác nhau; liên kết chỉ thực hiện khi credential chưa thuộc UID khác.
- Chụp ảnh mới bằng camera; unit này chỉ chọn ảnh đã có qua bộ chọn của hệ điều hành.
- Nhật ký từng lượt, timestamp, tổng lượt chơi, tổng thắng/thua hoặc thống kê va chạm trong gameplay.
- Huy hiệu cần bộ đếm mới, nhiệm vụ ngày, phần thưởng xu hoặc thao tác “nhận thưởng”.
- Chỉnh sửa luật chơi, `lib/sim/`, campaign, mốc sao hoặc cân bằng toàn cục.
- Xóa toàn bộ tiến trình; nếu cần, đây là luồng riêng trong Cài đặt.

## Điều kiện chất lượng chung

- Khách và cache của tài khoản phải hoạt động đầy đủ khi thiết bị không có mạng; chỉ xác thực, liên kết, upload và đồng bộ cloud được phép chờ kết nối.
- Việc đọc, ghi, chọn hoặc xử lý avatar không được làm mất sao, điểm, xu hay trạng thái màn đã lưu.
- Màn Hồ sơ và bộ chọn phải hỗ trợ phone portrait, safe area, text scale, semantic labels và control tối thiểu 48dp theo `uiux-guideline.md`.
- Các phép tính tiến trình và huy hiệu phải tất định từ cùng một `PlayerProgress`; không duy trì bản sao số liệu tổng hợp có thể lệch.
- Phase 2 phải thiết kế Firebase Auth, Firestore, Storage, schema/versioning, Security Rules, cache theo UID và cơ chế retry/merge; không được kéo dependency Flutter/Firebase vào `lib/sim/`.
- Các thay đổi cloud phải có kiểm thử bằng Firebase Emulator Suite hoặc môi trường test tương đương trước khi dùng project production.

---

## Next Steps

Once these requirements are approved, proceed to Phase 2: Design Document Creation.

**What to do next:**
1. Use the slash command: `/aidlc.construction.create-design`
2. The agent will automatically read `references/phase-2-design.md` for detailed workflow instructions
3. Foundation docs will be referenced for architecture alignment

This will create `design.md` with comprehensive design based on these requirements.
