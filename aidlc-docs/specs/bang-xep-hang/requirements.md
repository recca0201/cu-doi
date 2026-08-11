---
artifact_type: requirements
phase: construction
status: draft
created: 2026-08-11
updated: 2026-08-11
unit: bang-xep-hang
source_artifacts:
  - aidlc-docs/foundation/project-overview-pdr.md
  - aidlc-docs/foundation/system-architecture.md
  - aidlc-docs/foundation/uiux-guideline.md
  - aidlc-docs/specs/ho-so-nguoi-choi/requirements.md
  - lib/domain/player_progress.dart
  - lib/data/progress_repository.dart
  - lib/state/providers.dart
  - lib/ui/screens/arena_map_screen.dart
  - lib/ui/screens/game_screen.dart
  - aidlc-docs/specs/bang-xep-hang/design-assets/leaderboard-reference-v2.png
  - aidlc-docs/specs/bang-xep-hang/mockup.html
  - https://developer.apple.com/documentation/gamekit/authenticating-a-player
  - https://developer.apple.com/documentation/gamekit/encourage-progress-and-competition-with-leaderboards
  - https://developer.android.com/games/pgs/platform-authentication
  - https://developer.android.com/games/pgs/android/leaderboards
---

# Requirements: Bảng xếp hạng

**Unit**: Bảng xếp hạng theo màn
**Feature**: Bảng điểm cao nhất riêng cho 20 màn qua Game Center và Google Play Games
**Created**: 2026-08-11
**User Stories**: US-1, US-2, US-3, US-4
**Estimation (BCP)**: Not yet estimated

---

## Introduction

Bảng xếp hạng cho phép Người chơi so sánh điểm cao nhất của từng màn với bạn bè và
cộng đồng ngay trong giao diện karst adventure arcade của game. Tính năng dùng Game Center trên iOS
và Google Play Games trên Android, nhưng giữ nguyên nguyên tắc offline-first: không yêu
cầu đăng nhập để khởi động hoặc chơi, và lỗi mạng không được làm mất tiến trình cục bộ.

Đây là mở rộng phạm vi có chủ đích so với PDR và foundation kiến trúc hiện tại, vốn ghi
bảng xếp hạng là ngoài phạm vi và chưa mô tả tích hợp dịch vụ trò chơi. Tính năng không
thêm backend bảng xếp hạng, không dùng Firebase làm nguồn điểm, không gộp dữ liệu giữa
iOS và Android, và không thay đổi luật chơi hoặc bất kỳ file nào trong `lib/sim/`.

## Ràng buộc và quyết định đã chốt

| # | Nội dung | Trạng thái |
|---|---|---|
| D1 | Có đúng 20 bảng, mỗi màn dùng điểm cao nhất của riêng màn đó | Người dùng chốt 2026-08-11 |
| D2 | iOS dùng Game Center; Android dùng Google Play Games; hai hệ xếp hạng độc lập | Người dùng chốt 2026-08-11 |
| D3 | Điểm vào nằm ở màn Chọn màn và màn Thắng | Người dùng chốt 2026-08-11 |
| D4 | Không bắt đăng nhập để chơi; chỉ đưa người chơi vào luồng xác thực khi họ mở bảng hoặc chủ động gửi điểm | Người dùng chốt 2026-08-11 |
| D5 | Sau khi xác thực, kỷ lục mới hợp lệ được tự động gửi; lỗi mạng được lưu chờ thử lại | Người dùng chốt 2026-08-11 |
| D6 | Lần xác thực thành công đầu tiên gửi toàn bộ kỷ lục hợp lệ đang lưu của tối đa 20 màn | Người dùng chốt 2026-08-11 |
| D7 | Tên và ảnh đại diện trên bảng lấy từ hồ sơ Game Center/Google Play Games, không dùng tên tự đặt hoặc hồ sơ Firebase | Ràng buộc của phương án nền tảng đã xác nhận |
| D8 | Có hai phạm vi người xem: Toàn cầu và Bạn bè; chỉ có kỳ Mọi thời đại | Người dùng chốt 2026-08-11 |
| D9 | Dùng giao diện riêng trong game, không mở giao diện leaderboard native của nền tảng | Người dùng chốt 2026-08-11 |
| D10 | Mỗi bảng hiển thị top 100 và vị trí của Người chơi nếu họ nằm ngoài top 100 | Người dùng chốt 2026-08-11 |
| D11 | Khi offline, hiển thị dữ liệu đã lưu gần nhất với cảnh báo dữ liệu có thể đã cũ | Người dùng chốt 2026-08-11 |
| D12 | Chống gian lận chỉ ở phía ứng dụng; không thêm máy chủ xác minh điểm | Người dùng chốt 2026-08-11 |
| D13 | Bộ lọc mở lần đầu mặc định là Toàn cầu; những lần sau nhớ bộ lọc gần nhất trên thiết bị | Người dùng chốt 2026-08-11 |
| D14 | VI và EN đều được hỗ trợ; VI tiếp tục là ngôn ngữ mặc định | Ràng buộc từ sản phẩm hiện tại |
| D15 | Khi không thể xác thực lại offline, cho xem cache nếu danh tính nền tảng trên thiết bị chưa thay đổi; không gửi điểm cho tới khi xác thực lại | Người dùng chốt 2026-08-11 |
| D16 | Điểm bị từ chối bằng lỗi không thể tự retry chuyển sang “Không gửi được”, giữ kỷ lục local và cho gửi lại thủ công | Người dùng chốt 2026-08-11 |
| D17 | Mỗi hàng có avatar nền tảng; khi không tải được ảnh thì dùng avatar mặc định trung tính | Người dùng chốt 2026-08-11 |
| D18 | Visual v2 được duyệt: backdrop karst Việt Nam, panel jade/teal, khung bronze/gold, Baloo 2 + Nunito và bóng sticker cứng; không dùng shell galaxy/indigo/navy | Người dùng duyệt 2026-08-11 |

## Requirements

### US-1: Mở bảng xếp hạng của một màn

**User Story**: As a Người chơi, I want mở bảng xếp hạng của màn đang quan tâm từ các điểm vào quen thuộc, so that tôi có thể so sánh thành tích mà không mất ngữ cảnh chơi

**Priority**: High
**Business Value**: Đặt cạnh tranh ngay cạnh lựa chọn màn và kết quả thắng giúp bảng xếp hạng gắn với kỹ năng ở từng bài hình học thay vì trở thành một mục phụ tách rời.
**Dependencies**: None

**Acceptance Criteria**:

**1. Điểm vào từ màn Chọn màn**

1.1 WHEN Người chơi chọn một màn đã mở khóa trên màn Chọn màn THEN system SHALL hiển thị hành động mở bảng xếp hạng cho đúng ID màn đang được chọn.

1.2 WHEN Người chơi kích hoạt hành động bảng xếp hạng từ màn Chọn màn THEN system SHALL mở giao diện bảng xếp hạng trong game và giữ đúng màn đã chọn làm ngữ cảnh.

1.3 WHEN Người chơi quay lại từ bảng xếp hạng THEN system SHALL khôi phục màn Chọn màn tại cùng chương, màn được chọn và vị trí cuộn trước đó.

1.4 IF một màn còn khóa THEN system SHALL giữ nguyên hành vi khóa hiện có và không dùng bảng xếp hạng để mở hoặc làm thay đổi trạng thái màn.

**2. Điểm vào từ màn Thắng**

2.1 WHEN màn Thắng hiển thị kết quả THEN system SHALL cung cấp hành động xem bảng xếp hạng của đúng màn vừa hoàn thành mà không thay thế các hành động Tiếp theo và Chọn màn hiện có.

2.2 WHEN Người chơi mở bảng từ màn Thắng THEN system SHALL giữ kết quả vừa đạt làm ngữ cảnh để giao diện có thể cho biết điểm đó đã gửi, đang chờ gửi hay chưa thể gửi.

2.3 WHEN Người chơi đóng bảng được mở từ màn Thắng THEN system SHALL trở lại cùng màn kết quả và không ghi lại phần thưởng, sao, xu hoặc kết quả lần thứ hai.

**3. Khả dụng và bản địa hóa**

3.1 WHEN bất kỳ hành động bảng xếp hạng nào được hiển thị THEN system SHALL dùng nhãn VI hoặc EN theo locale hiện tại và có semantic label mô tả cả hành động lẫn số màn.

3.2 WHEN giao diện được dùng trên điện thoại portrait hoặc tablet THEN system SHALL giữ nội dung chính trong safe area, tôn trọng text scale hệ thống và cung cấp vùng chạm tối thiểu 48dp cho mọi điều khiển.

3.3 WHILE Người chơi đang ngắm hoặc bi đang bay THEN system SHALL không mở bảng xếp hạng, gọi mạng hoặc hiển thị lời nhắc xác thực làm gián đoạn cú bắn.

### US-2: Xác thực dịch vụ trò chơi theo nhu cầu

**User Story**: As a Người chơi, I want chỉ kết nối dịch vụ trò chơi khi tôi chọn dùng bảng xếp hạng, so that tôi vẫn có thể bắt đầu và chơi game hoàn toàn offline

**Priority**: High
**Business Value**: Xác thực theo nhu cầu giữ lời hứa offline-first và tránh biến một tính năng cạnh tranh tùy chọn thành cổng chặn vòng chơi cốt lõi.
**Dependencies**: US-1; Game Center capability và Google Play Games Services đã được cấu hình với 20 leaderboard ID tương ứng

**Acceptance Criteria**:

**1. Khởi tạo không chặn chơi**

1.1 WHEN ứng dụng khởi động mà chưa có người chơi nền tảng khả dụng THEN system SHALL cho phép vào menu, chọn màn và chơi mà không hiển thị lời nhắc đăng nhập bắt buộc.

1.2 IF SDK nền tảng thực hiện xác thực im lặng ở nền THEN system SHALL không đổi màn hình, không chặn tương tác và không dùng kết quả đó để thay đổi hồ sơ Firebase hoặc tiến trình cục bộ.

1.3 WHILE Người chơi không kích hoạt hành động mở bảng hoặc gửi điểm THEN system SHALL không chủ động hiển thị giao diện đăng nhập Game Center/Google Play Games.

**2. Xác thực từ hành động rõ ràng**

2.1 WHEN Người chơi mở bảng hoặc chọn gửi điểm mà chưa xác thực THEN system SHALL bắt đầu luồng xác thực do nền tảng hiện tại cung cấp và giải thích rằng kết nối này dùng cho bảng xếp hạng.

2.2 WHEN xác thực thành công trên iOS THEN system SHALL dùng người chơi Game Center hiện tại cho việc đọc và gửi bảng xếp hạng iOS.

2.3 WHEN xác thực thành công trên Android THEN system SHALL dùng người chơi Google Play Games hiện tại cho việc đọc và gửi bảng xếp hạng Android.

2.4 IF Người chơi hủy, bị hạn chế tài khoản hoặc xác thực thất bại THEN system SHALL:
- giữ nguyên điểm, sao, xu và tiến trình cục bộ
- hiển thị phản hồi có thể hiểu được bằng locale hiện tại
- không tự bật lại giao diện xác thực cho tới một hành động bảng xếp hạng rõ ràng tiếp theo
- IF có cache khớp với danh tính nền tảng đã xác nhận gần nhất và danh tính trên thiết bị chưa thay đổi, mở cache với cảnh báo dữ liệu có thể đã cũ và không gửi điểm
- OTHERWISE trở lại ngữ cảnh trước luồng xác thực

**3. Danh tính và ranh giới tài khoản**

3.1 WHEN hiển thị danh tính trên bảng THEN system SHALL dùng tên hiển thị và ảnh đại diện do Game Center hoặc Google Play Games trả về.

3.2 IF Người chơi đổi tên hoặc ảnh trong hồ sơ nền tảng THEN system SHALL dùng dữ liệu mới ở lần tải thành công tiếp theo mà không ghi đè tên hoặc avatar trong hồ sơ game/Firebase.

3.3 WHEN tài khoản Firebase đăng nhập, đăng xuất, liên kết hoặc bị xóa THEN system SHALL không tự coi thao tác đó là đăng nhập, đăng xuất hoặc xóa dữ liệu Game Center/Google Play Games.

3.4 WHEN tài khoản nền tảng thay đổi trên thiết bị THEN system SHALL không hiển thị hàng “Của tôi”, cache cá nhân hoặc trạng thái gửi của người chơi nền tảng trước như thể thuộc người chơi mới.

### US-3: Xem bảng điểm toàn cầu và bạn bè

**User Story**: As a Người chơi, I want xem người dẫn đầu và vị trí của mình theo từng màn, so that tôi biết thành tích hiện tại cạnh tranh đến đâu

**Priority**: High
**Business Value**: Top 100 tạo mục tiêu dài hạn, còn vị trí cá nhân và bảng bạn bè tạo phản hồi có ý nghĩa cho cả người chơi chưa thể vào nhóm dẫn đầu.
**Dependencies**: US-1, US-2

**Acceptance Criteria**:

**1. Phạm vi và dữ liệu bảng**

1.1 WHEN bảng xếp hạng mở lần đầu trên một thiết bị THEN system SHALL chọn bộ lọc Toàn cầu; những lần mở sau SHALL khôi phục bộ lọc Toàn cầu hoặc Bạn bè được dùng gần nhất.

1.2 WHEN Người chơi chọn bộ lọc Toàn cầu hoặc Bạn bè THEN system SHALL tải dữ liệu Mọi thời đại của đúng màn và làm rõ bộ lọc đang hoạt động.

1.3 WHEN tải thành công THEN system SHALL hiển thị tối đa 100 mục dẫn đầu theo thứ hạng do dịch vụ nền tảng trả về.

1.4 WHEN hiển thị một mục xếp hạng THEN system SHALL trình bày tối thiểu:
- thứ hạng
- ảnh đại diện nền tảng, hoặc avatar mặc định trung tính nếu ảnh không có hay tải thất bại
- tên hiển thị nền tảng
- điểm cao nhất
- dấu hiệu không chỉ dựa vào màu nếu đó là mục của Người chơi hiện tại

1.5 IF Người chơi hiện tại nằm trong top 100 THEN system SHALL đánh dấu đúng mục đó và không lặp lại ở một hàng riêng.

1.6 IF Người chơi hiện tại có hạng hợp lệ nhưng nằm ngoài top 100 THEN system SHALL hiển thị thêm vị trí và điểm của họ tách biệt nhưng cùng định dạng với danh sách.

1.7 IF dịch vụ nền tảng trả các điểm bằng nhau THEN system SHALL hiển thị thứ hạng do dịch vụ trả về và không tự đặt quy tắc phá hòa khác trong app.

1.8 WHEN Người chơi xem bảng trên iOS hoặc Android THEN system SHALL chỉ hiển thị dữ liệu của dịch vụ trên nền tảng đó; không tuyên bố đây là bảng gộp đa nền tảng.

**2. Trạng thái rỗng, quyền bạn bè và lỗi dịch vụ**

2.1 WHILE dữ liệu đang tải và chưa có cache phù hợp THEN system SHALL hiển thị trạng thái tải không khóa nút quay lại hoặc đổi ngữ cảnh.

2.2 IF bảng hợp lệ nhưng chưa có điểm THEN system SHALL hiển thị trạng thái rỗng cho đúng màn và bộ lọc, không trình bày điểm 0 giả.

2.3 IF danh sách Bạn bè không khả dụng do quyền riêng tư, hạn chế tài khoản hoặc nền tảng không trả dữ liệu THEN system SHALL giải thích trạng thái đó và vẫn cho phép chuyển sang Toàn cầu.

2.4 IF dịch vụ trả lỗi không phải lỗi xác thực THEN system SHALL giữ Người chơi trong giao diện bảng, cung cấp hành động thử lại và không làm thay đổi tiến trình hoặc hàng đợi gửi điểm.

**3. Cache và chế độ offline**

3.1 WHEN tải thành công một bảng THEN system SHALL lưu bản gần nhất riêng theo nền tảng, ID màn và bộ lọc Toàn cầu/Bạn bè.

3.2 IF không có kết nối hoặc yêu cầu tải thất bại và có cache phù hợp THEN system SHALL:
- hiển thị cache đó cùng nhãn rõ ràng rằng dữ liệu có thể đã cũ
- cho phép xem cache khi không thể xác thực lại nếu cache thuộc danh tính nền tảng đã xác nhận gần nhất và danh tính trên thiết bị chưa thay đổi
- không trình bày dữ liệu cache như đang trực tuyến hoặc gửi điểm cho tới khi xác thực lại

3.3 IF không có kết nối và chưa có cache phù hợp THEN system SHALL hiển thị trạng thái không có dữ liệu offline, vẫn cho phép quay lại và không thay bằng dữ liệu của màn hoặc bộ lọc khác.

3.4 WHEN tải trực tuyến thành công sau một lần dùng cache THEN system SHALL thay cache bằng dữ liệu mới và bỏ cảnh báo dữ liệu cũ.

**4. Giao diện và khả năng tiếp cận**

4.1 WHEN bảng xếp hạng hiển thị THEN system SHALL dùng hệ thị giác karst adventure
arcade đã duyệt trong `uiux-guideline.md` và `leaderboard-reference-v2.png`; SHALL
không dùng shell galaxy/indigo/navy và không dùng màu như tín hiệu duy nhất cho bộ
lọc, trạng thái hoặc hàng của Người chơi.

4.2 WHEN screen reader bật THEN system SHALL đọc mỗi mục theo thứ tự hạng, tên và điểm; đồng thời công bố trạng thái tải, lỗi, offline và đổi bộ lọc.

4.3 WHEN text scale tăng THEN system SHALL giữ hạng, tên và điểm đọc được mà không cắt mất hành động quay lại, đổi bộ lọc hoặc thử lại.

4.4 WHEN giao diện hiển thị THEN system SHALL không cung cấp bộ lọc Ngày, Tuần hoặc bảng tổng chiến dịch.

### US-4: Gửi và khôi phục điểm cao nhất

**User Story**: As a Người chơi, I want kỷ lục hợp lệ của mình được gửi và tự khôi phục sau lỗi mạng, so that vị trí xếp hạng phản ánh thành tích tốt nhất mà không bắt tôi lặp lại thao tác

**Priority**: High
**Business Value**: Gửi tự động và hàng đợi bền vững loại bỏ ma sát sau lần kết nối đầu, trong khi kiểm tra điểm phía app ngăn dữ liệu sai rõ ràng làm bẩn bảng.
**Dependencies**: US-2

**Acceptance Criteria**:

**1. Điều kiện điểm hợp lệ**

1.1 WHEN đánh giá một điểm để gửi THEN system SHALL chỉ coi điểm hợp lệ nếu:
- ID màn nằm trong 1..20
- màn đã được hoàn thành bằng một lượt chơi thắng, không phải bỏ qua hoặc thua
- điểm là số nguyên lớn hơn 0
- điểm bằng kỷ lục đang lưu của màn tại thời điểm xếp hàng
- điểm không vượt quá `số mục tiêu của màn × 100 × kMaxMultiplier`

1.2 IF một kết quả không thỏa bất kỳ điều kiện nào ở 1.1 THEN system SHALL không gửi hoặc xếp hàng kết quả đó và SHALL giữ nguyên kỷ lục hợp lệ trước đó.

1.3 WHEN kiểm tra giới hạn điểm THEN system SHALL đọc số mục tiêu và `kMaxMultiplier` từ dữ liệu/luật hiện có, không sao chép một trần điểm tune tay cho từng màn.

1.4 WHEN một điểm hợp lệ được gửi THEN system SHALL dùng bảng có ID tương ứng đúng với ID màn và nền tảng hiện tại.

**2. Lần kết nối đầu và gửi kỷ lục cũ**

2.1 WHEN một danh tính dịch vụ trò chơi xác thực thành công lần đầu trên bản cài đặt hiện tại THEN system SHALL rà soát cả 20 màn và xếp hàng cho danh tính đó mỗi kỷ lục cục bộ thỏa 1.1.

2.2 IF một màn chưa hoàn thành, chỉ được bỏ qua, chỉ có lần thua hoặc có điểm 0 THEN system SHALL không tạo mục gửi cho màn đó.

2.3 WHEN nhiều kỷ lục cũ được xếp hàng THEN system SHALL giữ tối đa một điểm cao nhất cho mỗi màn và không tạo quá 20 mục chờ.

2.4 IF luồng gửi hàng loạt bị gián đoạn THEN system SHALL ghi bền vững các mục chưa xác nhận để lần chạy sau tiếp tục mà không gửi nhầm sang một tài khoản nền tảng khác.

**3. Tự động gửi kỷ lục mới**

3.1 WHEN Người chơi đã xác thực và hoàn thành một màn với điểm cao hơn kỷ lục trước đó THEN system SHALL lưu tiến trình cục bộ trước rồi tự động xếp hàng điểm mới cho màn đó.

3.2 WHEN Người chơi hoàn thành màn với điểm bằng hoặc thấp hơn kỷ lục đã lưu THEN system SHALL không tạo mục gửi mới.

3.3 IF Người chơi chưa xác thực và có kỷ lục hợp lệ THEN system SHALL giữ kỷ lục cục bộ, cho phép hành động gửi điểm rõ ràng từ ngữ cảnh kết quả/bảng và chỉ bắt đầu xác thực sau hành động đó.

3.4 WHEN một điểm cao hơn thay thế điểm đang chờ của cùng màn THEN system SHALL chỉ giữ điểm cao hơn trong hàng đợi.

3.5 WHEN nền tảng xác nhận điểm đã gửi THEN system SHALL xóa mục chờ tương ứng và cập nhật trạng thái hiển thị mà không thay đổi sao, xu hoặc điểm cục bộ.

**4. Lỗi mạng, thu hồi xác thực và thử lại**

4.1 IF gửi điểm thất bại do mất mạng hoặc lỗi tạm thời THEN system SHALL lưu bền vững điểm hợp lệ để còn tồn tại sau khi đóng/mở app và hiển thị trạng thái đang chờ thay vì báo đã gửi.

4.2 WHEN app hoạt động trở lại với kết nối và danh tính nền tảng phù hợp mà không cần lời nhắc đăng nhập THEN system SHALL tự thử lại các mục đang chờ.

4.3 WHEN Người chơi mở bảng hoặc hoàn thành một màn trong lúc còn mục chờ THEN system SHALL thử lại các mục phù hợp mà không tạo bản sao trùng lặp.

4.4 IF phiên nền tảng hết hạn hoặc quyền truy cập bị thu hồi THEN system SHALL giữ hàng đợi, không bật lời nhắc đăng nhập ngoài ngữ cảnh và chỉ tiếp tục sau một hành động xác thực rõ ràng của Người chơi.

4.5 IF lỗi gửi được nền tảng xác định là không thể tự thử lại THEN system SHALL:
- giữ nguyên kỷ lục cục bộ
- chuyển mục khỏi hàng đợi retry tự động sang trạng thái “Không gửi được”
- lưu và hiển thị lý do lỗi có thể hiểu được bằng locale hiện tại
- cung cấp hành động gửi lại thủ công
- không làm gián đoạn gameplay

**5. Ranh giới vận hành**

5.1 WHILE cú bắn đang được mô phỏng hoặc render THEN system SHALL không thực hiện đọc bảng, gửi hàng loạt hoặc retry mạng trên đường xử lý frame của gameplay.

5.2 WHEN tính năng được triển khai THEN system SHALL không sửa luật dội, hằng số cân bằng, hình học campaign hoặc tạo phụ thuộc Flutter/mạng trong `lib/sim/`.

5.3 WHEN lưu cache hoặc hàng đợi THEN system SHALL tách dữ liệu theo nền tảng và danh tính người chơi nền tảng để không hiển thị hoặc gửi dữ liệu cá nhân của tài khoản trước cho tài khoản sau.

5.4 WHEN xóa dữ liệu ứng dụng khỏi thiết bị THEN system SHALL xóa cache bảng và hàng đợi cục bộ; điểm đã được nền tảng chấp nhận tiếp tục tuân theo chính sách của Game Center/Google Play Games.

## Ngoài phạm vi

- Bảng xếp hạng chung giữa iOS và Android.
- Bảng tổng điểm chiến dịch, bảng theo chương, hoặc bảng theo số sao.
- Bảng Ngày, Tuần, mùa giải hoặc cơ chế đặt lại định kỳ.
- Tên bảng xếp hạng tự đặt trong game; chỉnh sửa tên/ảnh hồ sơ nền tảng.
- Bắt buộc đăng nhập trước khi chơi, đồng bộ tiến trình qua dịch vụ trò chơi, thành tích hoặc multiplayer.
- Giao diện leaderboard native của Game Center/Google Play Games.
- Backend riêng, Firebase leaderboard, xác minh điểm phía máy chủ, telemetry hoặc hệ thống moderation riêng trong app.
- Thay đổi luật chơi, cân bằng, solver hoặc file được sinh `lib/sim/arenas.dart`.

## Phê duyệt thiết kế

- **Trạng thái**: approved ngày 2026-08-11.
- **Ảnh chuẩn**: `design-assets/leaderboard-reference-v2.png`.
- **Handoff triển khai**: `mockup.html` (8 state tabs). Bản trước đã được chụp và
  so sánh đủ 8 state; sau audit token/accessibility ngày 2026-08-11, Browser bị
  URL policy chặn khi mở localhost nên metadata hiện ghi trung thực
  `skipped:no-browser-tool` thay vì tuyên bố revalidation đã hoàn tất.
- **Nguồn style**: `test/ui/goldens/arena_map_390x844.png`, backdrop karst và
  `assets/images/ui/karst/`; copy/hành vi vẫn lấy từ requirements này.
- Bản `leaderboard-reference.png` navy/galaxy là phương án bị loại, không được
  dùng làm nguồn cho code hoặc thiết kế tiếp theo.

---

## Next Steps

Once these requirements are approved, proceed to Phase 2: Design Document Creation.

**What to do next:**
1. Use the slash command: `/aidlc.construction.create-design`
2. The agent will automatically read `references/phase-2-design.md` for detailed workflow instructions
3. Foundation docs will be referenced for architecture alignment

This will create `design.md` with comprehensive design based on these requirements.
