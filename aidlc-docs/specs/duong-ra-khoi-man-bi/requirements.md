---
artifact_type: requirements
phase: construction
status: draft
created: 2026-08-05
updated: 2026-08-09
unit: duong-ra-khoi-man-bi
source_artifacts:
  - aidlc-docs/requirements/001_remaining-scope_units_decomposition.md
  - aidlc-docs/story-artifacts/001_hint-and-skip-level_user_stories.md
  - aidlc-docs/foundation/project-overview-pdr.md
  - aidlc-docs/foundation/system-architecture.md
  - aidlc-docs/foundation/uiux-guideline.md
  - lib/domain/player_progress.dart
  - lib/data/progress_repository.dart
  - lib/sim/arena.dart
  - lib/sim/shot_runner.dart
  - lib/ui/screens/game_screen.dart
  - lib/ui/screens/arena_map_screen.dart
---

# Requirements: duong-ra-khoi-man-bi

**Unit**: Unit 1 — Đường ra khỏi màn bí
**Feature**: Gợi ý đường carom mua bằng xu, bỏ qua màn bằng xu, và lời nhắc khi người chơi đang tắc
**Created**: 2026-08-05
**User Stories**: US-1, US-2, US-3
**Estimation (BCP)**: Not yet estimated

**Truy vết ngược Inception**:

| Story ở đây | Story gốc | Tiêu đề gốc |
|---|---|---|
| US-1 | `001/US-001` | Mua gợi ý đường carom bằng xu |
| US-2 | `001/US-002` | Bỏ qua màn đang tắc bằng xu |
| US-3 | `001/US-003` | Được nhắc rằng có đường ra khi đang tắc |

---

## Introduction

Cơ chế dội tường có thể làm người chơi **tắc hẳn** — khác ghép-3 nơi luôn còn một nước
đi hợp lệ — nên PDR §10 xếp gợi ý/bỏ qua màn là **bắt buộc, không phải tuỳ chọn**. Unit
này cho người chơi một đường ra khỏi màn không giải được, và đồng thời cho **xu** ý nghĩa
đầu tiên: hiện `PlayerProgress.coins` chỉ tích luỹ, chưa có chỗ tiêu.

Đây là unit duy nhất trong ba unit của `001_remaining-scope` **ghi state mới vào tiến
trình**: dấu "đã bỏ qua", bộ đếm thua theo màn, và xu bị trừ. Cả ba phải nhất quán trong
cùng một lần ghi — nếu trừ xu thành công mà ghi dấu thất bại, người chơi mất xu và vẫn tắc.

---

## Ràng buộc từ code hiện tại

Đọc trước khi viết design. Đây là **quan sát từ code**, không phải quyết định thiết kế.

| # | Ràng buộc | Nguồn |
|---|---|---|
| C1 | Luật mở màn suy ra từ **sao**: `completedMax` chỉ tính `stars >= 1`, rồi `unlockedMax = completedMax + 1`. Ghi màn bỏ qua ở 0 sao mà không sửa gì thì màn kế tiếp **không mở** | `player_progress.dart:27-37` |
| C2 | `LevelResult.fromJson` đọc `j['stars'] as int` — **không chịu null**. Mọi field mới thêm vào schema phải đọc bằng `as T?` kèm giá trị mặc định, nếu không save cũ crash khi parse | `player_progress.dart:8-9` |
| C3 | `withResult` là **đường ghi duy nhất** hiện có, và nó chỉ **cộng** xu (`score ~/ 10` cho phần điểm tăng thêm). Chưa có đường trừ xu | `player_progress.dart:41-55` |
| C4 | `ArenaSpec.hint` / `hintEn` **đã tồn tại** và là hint **chữ** tĩnh mỗi màn, đang hiện ở footer màn chơi. Đây **không phải** thứ US-1 bán — US-1 bán một **đường carom vẽ được** | `arena.dart:94-111`, `arenas.dart` |
| C5 | Solver duy nhất trong repo là `tools/solver/*.js` — **Node JS, không ship trong app**. Không có đường tìm cú giải nào chạy được trong Dart runtime ở thời điểm này | `tools/solver/` |
| C6 | `lib/sim/` là Dart thuần không import Flutter, và `ShotRunner` mô phỏng tất định — nên một phép quét góc **chạy được trong Dart** về mặt nguyên tắc; nhưng nó chưa tồn tại | PDR §7, §8.7 |
| C7 | `arena_map_screen` là `ListView.separated` phẳng 20 màn. Unit 3 (`giong-va-cau-truc-ngoai-san-dau`) sẽ dựng lại màn hình này thành 4 chương — dấu "đã bỏ qua" của US-2 phải viết sao cho Unit 3 dùng lại được, không viết cứng vào bố cục phẳng | `arena_map_screen.dart`, `001_remaining-scope` §Chồng lấn |
| C8 | Toàn bộ `PlayerProgress` được lưu **một chuỗi JSON dưới một khoá `progress_v1`** — nên xu, dấu "đã bỏ qua" và bộ đếm thua **vốn đã nằm trong cùng một lần ghi**. Tính nguyên tử là thuộc tính có sẵn, không phải thứ phải dựng | `progress_repository.dart:18,40` |
| C9 | `save()` là `Future<void>` và **nuốt mọi exception** — docstring ghi rõ "never throw up to the UI (US-017 AC-1.1)". Hiện **không có cách nào phát hiện ghi thất bại**. US-2 AC-2.3 đòi đổi hợp đồng này để báo được thành công/thất bại | `progress_repository.dart:13-14,38-49` |
| C10 | `load()` đã có `try/catch` rơi về `PlayerProgress()` rỗng — nên US-2 AC-4.3 là **chốt chống hồi quy**, không phải việc mới | `progress_repository.dart:21-35` |

## Quyết định và giả định

| # | Nội dung | Trạng thái |
|---|---|---|
| D1 | Gợi ý **50 xu**, bỏ qua màn **150 xu** | **Đã chốt** với người dùng 2026-08-05. Vẫn là con số chờ playtest tune — xem US-1 AC-4.1 |
| D2 | Bỏ qua màn tính là hoàn thành **0 sao**: mở màn sau, không ghi sao, không ghi điểm cao, không thu xu | Đã chốt ở Inception (A2) |
| D3 | Bộ đếm thua **lưu cùng tiến trình**, không phải biến tạm theo phiên | Đã chốt ở Inception (A9) |
| D4 | Mọi chuỗi mới có ở **cả** `app_vi.arb` và `app_en.arb`, VI mặc định | Đã chốt ở Inception (A8) |
| D5 | **Gợi ý trả phí được phép vẽ trọn lời giải**, dù `uiux-guideline.md` §2.4, §4.4 và §5.6 giới hạn preview ngắm ở hai đoạn. Người dùng đã được nêu xung đột này ở Inception và vẫn chọn phương án đó, lý do: hint **tốn xu và do người chơi chủ động bấm**, nên là đánh đổi có giá chứ không phải thông tin miễn phí ép vào mắt. Luật giữ **nguyên** cho preview ngắm thụ động (US-1 AC-3.4) | Đã chốt ở Inception (`001` § Xung đột thiết kế) |
| D6 | **Gợi ý tính bằng phép quét góc chạy trong Dart tại runtime**, không bake sẵn dữ liệu lời giải. Lý do: AC-2.2 đòi giải **trạng thái sân hiện tại**, còn dữ liệu bake chỉ phủ được sân đầy lúc mở màn — nên nhánh bake không đáp ứng được yêu cầu. `ShotRunner` là Dart thuần và tất định (C6), nên port phép quét là khả thi; `tools/solver/sim.js` vốn là bản port của cùng mô phỏng đó | **Đã chốt** 2026-08-05 |
| D7 | **Mỗi lần bấm gợi ý trừ 50 xu**, không có trần theo lượt vào màn. Sân đổi sau mỗi cú bắn nên mỗi gợi ý là một lời giải khác — tính tiền theo lần là nhất quán với D1 và không cần thêm cơ chế đếm | **Đã chốt** 2026-08-05 |
| D8 | **"Cú giải được" = một cú bắn hợp lệ phá được tối thiểu một mục tiêu còn lại.** Không đảm bảo cú đó nằm trên đường dẫn tới thắng màn — bảo đảm mạnh hơn đòi vét cả cây trạng thái, vượt xa giá 50 xu và vượt xa ngân sách của unit | **Đã chốt** 2026-08-05 |

---

## Requirements

### US-1: Mua gợi ý đường carom bằng xu

**User Story**: As a Người chơi, I want mua một gợi ý chỉ ra đường carom giải được màn
hiện tại, so that tôi không phải bỏ game ở một màn mình không tự nhìn ra hình học

**Priority**: High
**Business Value**: PDR §10 xác định "tắc hẳn" là rủi ro sản phẩm thật của cơ chế dội
tường. Đây cũng là chỗ tiêu xu đầu tiên, biến xu từ số trang trí thành tài nguyên.
**Dependencies**: None

**Acceptance Criteria**:

**1. Mua gợi ý**

1.1 WHEN người chơi đang ở màn chơi và bấm nút gợi ý với số dư ≥ 50 xu THEN system SHALL:
- trừ **50 xu** khỏi số dư
- lưu số dư mới xuống bộ nhớ cục bộ **ngay**, không chờ tới lúc kết màn
- hiện đường carom của một cú giải được trạng thái sân hiện tại

1.2 WHEN xu bị trừ cho bất kỳ giao dịch nào của unit này THEN system SHALL không bao giờ
để số dư xuống dưới **0**, kể cả khi hai giao dịch xảy ra sát nhau.

1.3 WHEN gợi ý được mua THEN system SHALL trừ xu và hiện gợi ý như **một giao dịch**: IF
không tìm được cú giải được (AC-2.3) **hoặc** lần ghi số dư thất bại (ràng buộc C9) THEN
system SHALL không trừ xu.

**2. Nội dung và hiệu năng của gợi ý**

> **"Cú giải được" trong mục này** nghĩa là **một cú bắn hợp lệ phá được tối thiểu một mục
> tiêu còn lại** (D8). Không đảm bảo cú đó dẫn tới thắng màn.

2.1 WHEN gợi ý được hiện THEN system SHALL vẽ **trọn** quỹ đạo của cú giải được đó: từ bệ
phóng, qua từng điểm dội, tới mục tiêu cuối mà cú đó phá được.

2.2 WHEN gợi ý được tính THEN system SHALL tính theo **trạng thái sân hiện tại** — chỉ các
mục tiêu còn lại, không phải sân đầy lúc mở màn (đây là lý do D6 loại nhánh bake sẵn).

2.3 IF không tìm được cú giải được cho trạng thái sân hiện tại THEN system SHALL:
- không trừ xu
- cho người chơi biết gợi ý không dùng được ở trạng thái này
- không rời khỏi màn chơi

2.4 WHEN gợi ý đang được tính THEN system SHALL không làm rơi khung hình (không khung nào
vượt **16ms**) và SHALL không chặn thao tác kéo để ngắm; IF phép quét cần lâu hơn một khung
THEN system SHALL chạy bất đồng bộ kèm phản hồi "đang tính" thay vì để màn hình đứng.

**3. Hiển thị và giới hạn của gợi ý**

3.1 WHILE gợi ý đang hiện THEN system SHALL vẽ đường gợi ý **khác biệt rõ bằng ít
nhất hai kênh** với vệt ma và preview ngắm, ví dụ màu semantic + cadence nét hoặc
marker điểm dội. Requirements SHALL không khoá màu legacy/alpha thô; design chọn
token theo `uiux-guideline.md` §3.1 và kiểm bằng golden.

3.2 WHILE gợi ý đang hiện THEN system SHALL giữ đường gợi ý trên màn hình cho tới khi người
chơi bắn cú tiếp theo.

3.3 WHILE gợi ý đang hiện THEN system SHALL không tự động ngắm hộ và không tự bắn: người
chơi vẫn phải tự kéo và tự thả.

3.4 WHILE gợi ý đang hiện THEN system SHALL giữ nguyên luật preview ngắm hiện tại — preview
thụ động vẫn **chỉ hiện hai đoạn đầu** quỹ đạo và vẫn bị ẩn khi bóng đang bay
(`uiux-guideline.md` §4.4 và §5.6).

3.5 WHILE gợi ý đang hiện THEN system SHALL không che tín hiệu `armed` của mục tiêu: mục
tiêu và biểu cảm SHALL được vẽ **trên** đường gợi ý.

3.6 WHEN người chơi bắn sau khi xem gợi ý THEN system SHALL xoá đường gợi ý và tính điểm,
sao, hệ số BỪA **y như một cú bắn bình thường** — mua gợi ý không hạ điểm và không hạ mốc
sao.

**4. Giá và trạng thái không đủ xu**

4.1 WHEN giá gợi ý được dùng ở bất kỳ đâu THEN system SHALL đọc từ **một hằng số duy nhất**
(giá trị khởi điểm 50), để tune sau playtest không phải sửa nhiều chỗ.

4.2 IF số dư xu < 50 WHEN người chơi ở màn chơi THEN system SHALL hiện nút gợi ý ở trạng
thái vô hiệu **vẫn nhìn thấy được**, kèm giá và số xu còn thiếu — không im lặng bỏ qua.

4.3 IF người chơi bấm nút gợi ý đang vô hiệu THEN system SHALL không trừ xu, không hiện gợi
ý, và không rời khỏi màn chơi.

**5. Phạm vi một lượt vào màn**

5.1 WHEN người chơi đã mua gợi ý cho màn hiện tại và chơi lại cùng màn đó **trong cùng một
lượt vào màn** THEN system SHALL hiện lại gợi ý đã mua mà **không trừ xu lần hai**.

5.2 WHEN người chơi thoát khỏi màn chơi rồi vào lại THEN system SHALL coi gợi ý là chưa mua
cho lượt mới.

5.3 WHEN người chơi bấm nút gợi ý lần thứ hai trở đi **trong cùng một lượt vào màn**, sau khi
đã bắn và trạng thái sân đã đổi THEN system SHALL trừ **50 xu mỗi lần** và SHALL không áp trần
số lần mua trong một lượt (D7).

**6. UI và bản địa hoá**

6.1 WHEN nút gợi ý được đặt lên HUD hoặc footer màn chơi THEN system SHALL giữ vùng chạm tối
thiểu **48dp** và SHALL không che sân đấu ở vùng bóng bay hoặc bệ phóng.

6.2 WHEN nút gợi ý được thêm THEN system SHALL bọc `Semantics` + `ExcludeSemantics` với
`label`, `button`, `enabled` theo `uiux-guideline.md` §8.

6.3 WHEN bất kỳ chuỗi mới nào được thêm cho tính năng này THEN system SHALL có bản dịch ở
**cả** `app_vi.arb` và `app_en.arb`, với VI là mặc định.

6.4 WHEN nút gợi ý trả phí được thêm THEN system SHALL không thay thế hoặc ẩn hint chữ tĩnh
`ArenaSpec.hint` đang có ở footer — hai thứ này là hai tính năng khác nhau.

---

### US-2: Bỏ qua màn đang tắc bằng xu

**User Story**: As a Người chơi, I want bỏ qua một màn tôi không giải được, so that một màn
quá khó không chặn tôi khỏi toàn bộ nội dung còn lại

**Priority**: High
**Business Value**: Luật mở màn hiện tại là tuyến tính (`unlockedMax = completedMax + 1`),
nên một màn bí chặn **toàn bộ** phần còn lại của game. Đây là van an toàn cho rủi ro số một
ở PDR §10.
**Dependencies**: None — nhưng điều kiện xuất hiện ở AC-1.1 đọc **bộ đếm thua theo màn**, là
hạ tầng dùng chung với US-3 (đặc tả ở US-3 mục 1). Làm bộ đếm **một lần**, dùng cho cả hai
story; đừng dựng hai bộ đếm song song.

**Acceptance Criteria**:

**1. Điều kiện xuất hiện**

1.1 WHEN người chơi thua màn hiện tại **3 lần liên tiếp** mà chưa từng hoàn thành màn đó
THEN system SHALL hiện lựa chọn bỏ qua màn trên màn hình kết quả.

1.2 IF người chơi đã **thắng thật (≥1 sao)** hoặc đã **bỏ qua** màn đó trước đây THEN system
SHALL không hiện lựa chọn bỏ qua màn, vì màn sau đã mở — người chơi SHALL không bị tính phí
150 xu hai lần cho cùng một màn.

1.3 WHILE người chơi đang trong một cú bắn THEN system SHALL không hiện lựa chọn bỏ qua màn
— chỉ hiện trên màn hình kết quả.

**2. Trả phí và xác nhận**

2.1 WHEN người chơi chọn bỏ qua màn THEN system SHALL yêu cầu **xác nhận một lần** trước khi
trừ xu, vì đây là hành động tiêu tài nguyên và ghi vào tiến trình.

2.2 WHEN người chơi xác nhận bỏ qua màn và có tối thiểu **150 xu** THEN system SHALL:
- trừ 150 xu
- ghi màn đó là đã bỏ qua
- đặt bộ đếm thua của màn đó về **0**
- mở màn kế tiếp
- lưu mọi thay đổi trên xuống bộ nhớ cục bộ **trong cùng một lần ghi**
- đưa người chơi **về bản đồ chọn màn**, ở vị trí màn vừa mở

> Ràng buộc C8 nghĩa là bullet "cùng một lần ghi" **đã đúng sẵn**: cả `PlayerProgress` được
> serialize thành một chuỗi JSON dưới một khoá `progress_v1`. Đây là chốt chống hồi quy —
> đừng tách xu, dấu bỏ qua và bộ đếm thua ra các khoá riêng.

2.3 IF lần ghi ở AC-2.2 thất bại THEN system SHALL không trừ xu và không ghi dấu bỏ qua —
người chơi SHALL không bao giờ ở trạng thái mất xu mà vẫn tắc.

> Ràng buộc C9: `save()` hiện nuốt mọi exception và trả `Future<void>`, nên **hôm nay tiêu chí
> này không có trigger kiểm được**. Thoả nó đòi hợp đồng ghi báo được thành công/thất bại, tức
> đổi một hợp đồng đã có (`US-017 AC-1.1` của bản trước). **Đổi hợp đồng đó là quyết định của
> Phase 2**, và là quyết định đắt nhất trong unit này.

2.4 IF số dư xu < 150 THEN system SHALL hiện lựa chọn bỏ qua ở trạng thái vô hiệu kèm giá và
số xu còn thiếu, và SHALL không trừ xu.

2.5 WHEN giá bỏ qua màn được dùng ở bất kỳ đâu THEN system SHALL đọc từ **một hằng số duy
nhất** (giá trị khởi điểm 150).

**3. Hiệu lực lên tiến trình**

3.1 WHEN màn được bỏ qua THEN system SHALL ghi màn đó là hoàn thành **0 sao** và:
- không ghi điểm cao cho màn đó
- không thu xu từ màn đó
- vẫn cho phép chơi lại màn đó bất cứ lúc nào để lấy sao thật

3.2 WHEN trạng thái mở màn được suy ra THEN system SHALL coi "đã bỏ qua" là một điều kiện mở
màn **riêng, độc lập với số sao**, sao cho:
- màn bỏ qua mở được màn kế tiếp dù có 0 sao
- màn bỏ qua **không** đóng góp sao nào vào `totalStars`
- "thắng thật" vẫn là một trạng thái phân biệt được với "đã bỏ qua"

> Ràng buộc C1 là lý do AC-3.2 tồn tại: chỉ ghi 0 sao thì AC-3.1 và AC-3.2 không thể cùng
> đúng. Tặng 1 sao giả cho màn bỏ qua **đã được cân và loại** ở Inception — nó làm
> `totalStars` đếm cả sao người chơi chưa lấy, tức phá tiến độ sao theo chương ở Unit 3.

3.3 WHEN người chơi chơi lại và thắng một màn đã bỏ qua THEN system SHALL ghi sao và điểm
cao bình thường, và **bỏ dấu "đã bỏ qua"** của màn đó.

3.4 WHEN màn bỏ qua nằm giữa chuỗi tiến trình THEN system SHALL giữ luật mở màn tuyến tính
đúng như trước: không màn nào mở vượt quá màn kế tiếp của màn xa nhất đã hoàn thành hoặc đã
bỏ qua.

**4. Tương thích schema tiến trình đã lưu**

4.1 WHEN tiến trình được đọc từ một save **được ghi bởi phiên bản trước unit này** THEN
system SHALL đọc thành công, coi mọi màn là **chưa bỏ qua**, và SHALL không mất sao, điểm
cao hay xu đã có.

4.2 WHEN field mới được thêm vào schema tiến trình THEN system SHALL đọc bằng giá trị mặc
định khi field vắng mặt (ràng buộc C2), và SHALL không cần bước migration riêng.

4.3 IF tiến trình đã lưu bị hỏng hoặc không parse được THEN system SHALL rơi về tiến trình
rỗng và SHALL không làm app crash khi mở. (Hành vi này **đã có** ở `load()` — ràng buộc C10;
tiêu chí là chốt chống hồi quy, không phải việc mới.)

**5. Hiển thị trên bản đồ**

5.1 WHEN màn đã bỏ qua được hiện trên bản đồ chọn màn THEN system SHALL phân biệt nó với màn
hoàn thành thật, để người chơi biết mình còn sao chưa lấy ở đó.

5.2 WHEN dấu "đã bỏ qua" được hiện THEN system SHALL không truyền đạt trạng thái đó **chỉ
bằng màu** — SHALL kèm hình dạng, icon hoặc chữ (`uiux-guideline.md` §3.1 và §8).

5.3 WHEN dấu "đã bỏ qua" được hiện THEN system SHALL hiện nó **trên chính item/node màn đó**, sao cho
dấu vẫn đúng chỗ khi bố cục bản đồ đổi sang nhóm theo chương ở Unit 3 (ràng buộc C7).

5.4 WHEN chuỗi cho dấu "đã bỏ qua" và cho luồng bỏ qua màn được thêm THEN system SHALL có
bản dịch ở **cả** `app_vi.arb` và `app_en.arb`.

---

### US-3: Được nhắc rằng có đường ra khi đang tắc

**User Story**: As a Người chơi, I want game cho tôi biết gợi ý và bỏ qua màn đang tồn tại
đúng lúc tôi bí, so that tôi không bỏ game vì tưởng mình hết cách

**Priority**: Medium
**Business Value**: Một van an toàn người chơi không biết là không có van. Chi phí nhỏ,
nhưng nó quyết định US-1 và US-2 có thực sự cứu được người chơi hay không.
**Dependencies**: US-1, US-2 — không có gì để nhắc trước khi hai story đó xong

**Acceptance Criteria**:

**1. Bộ đếm thua theo màn**

1.1 WHEN người chơi thua một màn THEN system SHALL tăng bộ đếm thua **của riêng màn đó** lên 1.

1.2 WHEN người chơi thắng một màn THEN system SHALL đặt bộ đếm thua của màn đó về **0**.

1.3 WHEN người chơi tắt app rồi mở lại THEN system SHALL giữ nguyên bộ đếm thua của từng
màn. Bộ đếm **không** được reset theo phiên chơi.

1.4 WHEN bộ đếm thua được cài THEN system SHALL dùng **một** bộ đếm duy nhất phục vụ cả điều
kiện xuất hiện của US-2 AC-1.1 và các mốc nhắc ở mục 2 dưới đây — SHALL không dựng hai bộ
đếm song song.

1.5 WHEN tiến trình được xoá từ Cài đặt THEN system SHALL đặt lại mọi bộ đếm thua về 0 cùng
với phần tiến trình còn lại.

1.6 WHEN bộ đếm thua được đọc từ save cũ không có field này THEN system SHALL coi mọi màn có
bộ đếm **0** và SHALL không lỗi (ràng buộc C2).

1.7 WHEN "thua một màn" được xác định THEN system SHALL chỉ tính là thua khi lượt chơi kết thúc
ở trạng thái **hết lượt bắn mà còn mục tiêu**; thoát khỏi màn giữa lượt SHALL **không** tăng bộ
đếm. (Bộ đếm này gate một khoản chi 150 xu ở US-2 AC-1.1, nên nó phải có một định nghĩa duy nhất.)

**2. Thời điểm nhắc**

2.1 WHEN người chơi thua cùng một màn **lần thứ 2** THEN system SHALL nhắc trên màn hình kết
quả rằng có thể mua gợi ý, kèm giá.

2.2 WHEN người chơi thua cùng một màn **lần thứ 3** THEN system SHALL nhắc cả gợi ý và bỏ
qua màn, kèm giá của từng lựa chọn.

2.3 IF người chơi đã hoàn thành màn đó trước đây THEN system SHALL không nhắc bỏ qua màn ở
màn đó, khớp với US-2 AC-1.2.

**3. Không gây khó chịu**

3.1 WHILE người chơi đang trong một cú bắn THEN system SHALL không hiện bất kỳ nhắc nhở nào
— chỉ nhắc trên màn hình kết quả.

3.2 WHEN nhắc nhở được hiện THEN system SHALL luôn kèm lựa chọn **tiếp tục thử lại**, và lựa
chọn đó SHALL không kém nổi bật hơn gợi ý/bỏ qua màn.

3.3 IF người chơi bỏ qua nhắc nhở THEN system SHALL không hiện lại cùng nhắc nhở đó cho tới
**lần thua tiếp theo** của cùng màn.

3.4 WHEN chuỗi nhắc nhở được thêm THEN system SHALL có bản dịch ở **cả** `app_vi.arb` và
`app_en.arb`.

---

## Ngoài phạm vi

- **Bất kỳ thay đổi nào lên `lib/sim/` làm đổi luật chơi.** `kMaxBanks`, `kMinAimUp`,
  `kMaxMultiplier`, điểm và mốc sao giữ **nguyên giá trị** (PDR §8.1). Một phép tìm cú giải
  chỉ **đọc** mô phỏng, không đổi tham số của nó.
- **Đổi cách thu xu.** `withResult` vẫn cộng xu theo `score ~/ 10` như hiện tại; unit này chỉ
  thêm đường **trừ**.
- **Nhóm màn theo chương, tiến độ sao theo chương, auto-scroll bản đồ** — thuộc Unit 3
  (`giong-va-cau-truc-ngoai-san-dau`).
- **Hiệu ứng truyện tranh và haptics** — thuộc Unit 2 (`phan-hoi-cu-ban`).
- **Firebase, quảng cáo, IAP** — ngoài phạm vi hiện tại của PDR §9. Xu chỉ kiếm được bằng
  cách chơi.

## Điều kiện tiên quyết

`001_remaining-scope` và PDR §11 đặt mốc **bắt buộc** trước unit này: `flutter create` /
`flutter test` chạy được, và **playtest 20 màn** trả lời câu hỏi số một ở PDR §10. Repo hiện
**chưa từng được biên dịch**. Giá 50/150 xu ở D1 là con số chờ chính lần playtest đó xác nhận.

---

## Next Steps

Once these requirements are approved, proceed to Phase 2: Design Document Creation.

**What to do next:**
1. Use the slash command: `/aidlc.construction.create-design`
2. The agent will automatically read `references/phase-2-design.md` for detailed workflow instructions
3. Foundation docs will be referenced for architecture alignment

This will create `design.md` with comprehensive design based on these requirements.
