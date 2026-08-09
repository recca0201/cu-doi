---
artifact_type: requirements
phase: construction
status: draft
created: 2026-08-05
updated: 2026-08-09
unit: phan-hoi-cu-ban
source_artifacts:
  - aidlc-docs/requirements/001_remaining-scope_units_decomposition.md
  - aidlc-docs/story-artifacts/002_comic-effects-by-bank-count_user_stories.md
  - aidlc-docs/story-artifacts/004_haptics-and-characters_user_stories.md
  - aidlc-docs/foundation/project-overview-pdr.md
  - aidlc-docs/foundation/system-architecture.md
  - aidlc-docs/foundation/uiux-guideline.md
  - lib/sim/shot_runner.dart
  - lib/ui/arena_painter.dart
  - lib/ui/screens/game_screen.dart
  - lib/ui/screens/settings_screen.dart
  - lib/core/game_audio_service.dart
  - lib/data/settings_repository.dart
---

# Requirements: phan-hoi-cu-ban

**Unit**: Unit 2 — Phản hồi cú bắn
**Feature**: Tầng hiệu ứng leo thang theo số lần dội, phản hồi phá mục tiêu theo hệ số BỪA, và rung tay trên cùng dòng sự kiện — không làm mờ tín hiệu `armed`
**Created**: 2026-08-05
**User Stories**: US-1, US-2, US-3, US-4, US-5
**Estimation (BCP)**: Not yet estimated

**Truy vết ngược Inception**:

| Story ở đây | Story gốc | Tiêu đề gốc |
|---|---|---|
| US-1 | `002/US-001` | Hiệu ứng leo thang theo từng lần dội |
| US-2 | `002/US-002` | Khoảnh khắc phá mục tiêu ở hệ số cao được tôn lên |
| US-3 | `002/US-003` | Hiệu ứng không được làm mờ luật chơi |
| US-4 | `004/US-001` | Cảm được cú dội qua rung tay |
| US-5 | `004/US-002` | Tắt rung được |

---

## Introduction

Cú bắn hiện **đúng luật nhưng không có sức nặng**: hệ số BỪA chỉ là chữ `BỪA ×N` mờ alpha
`0x59`, và một cú ×2 tầm thường ăn cùng một cú rung màn với cú ×6 khó nhất game. Unit này
làm cú bắn *cảm* được — mỗi lần dội và mỗi mục tiêu vỡ có sức nặng tương xứng với độ khó của
nó — qua **hai kênh xuất của cùng một dòng sự kiện**: hình ảnh và rung tay.

Hai artifact Inception được gộp vào một unit vì cả hai kích hoạt tại **đúng những mốc giống
nhau** trong `ShotRunner` (dội tường / phá mục tiêu / bắn thẳng bị chặn / kết màn), cần cùng
một cơ chế cooldown, và chịu **cùng một bất biến**: không được làm mờ tín hiệu `armed`. Chia
ra hai unit khiến bất biến đó bị kiểm hai lần độc lập thay vì một lần trọn vẹn.

Đây là unit về **cảm giác, không phải luật chơi**. Không story nào ở đây được đổi điểm, sao,
hay ba con số cân bằng toàn cục.

---

## Ràng buộc từ code hiện tại

| # | Ràng buộc | Nguồn |
|---|---|---|
| C1 | `comic_effect_controller.dart` của `ban_bua` (1.070 dòng) **chưa có trong repo này**. Nó gắn vào `popped`/`isCrit`/`isRage`/`isWild` — ba khái niệm của game ghép-3 đã bị App Store từ chối. PDR §11 yêu cầu **thiết kế lại quanh số lần dội trước**, rồi mới port | PDR §11, `uiux-guideline.md` §2.3 và §10.3 |
| C2 | Sân đấu được **vẽ** bằng `CustomPainter` + `Ticker`, không phải ghép widget. Code hiện tại có z-order riêng; implementation mới phải đạt hợp đồng đích ở `uiux-guideline.md` §5.1, trong đó effect không che target/armed/HUD | `arena_painter.dart`, `uiux-guideline.md` §5.1 |
| C3 | Rung màn hiện có: giảm dần `dt × 4.5` từ 1.0, dịch canvas theo `sin(shake × 47)`/`cos(shake × 61)` — **tất định, không dùng `Random` trong pass vẽ** | `arena_painter.dart` § Rung màn |
| C4 | `game_audio_service.dart` đã có 9 `GameSound` (gồm `wallImpact`, `blockedGap`, `comicImpact`, `politeClap`) và **cơ chế cooldown theo từng sound** với `DateTime Function() now` **tiêm được** — nên cooldown là thứ test được, không phải thứ chỉ cầm máy mới biết | `game_audio_service.dart:48,87,158` |
| C5 | `AppSettings` đọc bằng `_prefs.getBool('x') ?? true` — thêm `hapticsOn` là **tương thích ngược sẵn**, không cần migration | `settings_repository.dart` |
| C6 | `BbToggle` (64×38, `bbTeal` khi bật / `ink300` khi tắt, phát `Semantics.toggled`) đã tồn tại và đang được `settings_screen` dùng cho Âm thanh / Nhạc nền | `bb_widgets.dart`, `settings_screen.dart` |
| C7 | Rung màn **chưa được gate bởi reduced-motion** — `_shake` chạy vô điều kiện. Target mới yêu cầu tắt camera shake và giảm particle khi reduced motion bật | `arena_painter.dart`, `uiux-guideline.md` §7 |
| C8 | Chữ trong sân đấu hiện chưa theo `MediaQuery.textScaler`, và hệ số `BỪA ×N` ở alpha `0x59` chỉ đạt khoảng **2.45:1**. Target mới yêu cầu chữ gameplay nhận text scale riêng và chữ lớn đạt ít nhất 3:1 | `arena_painter.dart`, `uiux-guideline.md` §8 |
| C9 | Chưa có dependency haptics nào trong `pubspec.yaml`. `HapticFeedback` của `flutter/services.dart` là API **built-in**, không cần thêm package | `pubspec.yaml` |

## Quyết định và giả định

| # | Nội dung | Trạng thái |
|---|---|---|
| D1 | Hiệu ứng **tái dùng** âm thanh sẵn có và tem chữ sẵn có; **không thêm asset ảnh hay âm thanh mới** | Đã chốt ở Inception (A4a) |
| D2 | Tầng hiệu ứng vẽ trong `CustomPainter` + `Ticker` hiện tại; **không đưa Flame game loop vào** | Đã chốt ở Inception (A4b) |
| D3 | Haptics có **toggle riêng** trong Cài đặt, mặc định **bật**, theo đúng pattern `soundOn`/`musicOn` | Đã chốt ở Inception (A6) |
| D4 | Cooldown rung **60ms** — con số **khởi điểm để tune khi cầm máy thật**, không phải giá trị đã đo | Giả định Inception (A6b), giữ nguyên |
| D5 | Mọi chuỗi mới có ở **cả** `app_vi.arb` và `app_en.arb`, VI mặc định | Đã chốt ở Inception (A8) |
| D6 | Hình thức thị giác là **chùm vạch va đập** tại điểm chạm, dùng `trajectoryCyan`; multiplier/score emphasis dùng `primaryGold`. Không dùng vòng tròn đồng tâm có thể lẫn với quầng `armed` | Đã chốt ở Phase 2 và đồng bộ với `uiux-guideline.md` §3.1, §4.4 |

---

## Requirements

### US-1: Hiệu ứng leo thang theo từng lần dội

**User Story**: As a Người chơi, I want mỗi lần bi dội tường cho tôi một phản hồi mạnh dần,
so that tôi *cảm* được hệ số đang lớn lên thay vì chỉ đọc con số

**Priority**: Medium
**Business Value**: PDR §5 đặt trải nghiệm đích là "kỹ năng và sự thuần thục" — khoái cảm đến
từ việc thực hiện một cú khó. Hệ số BỪA hiện chỉ nói cho người chơi biết, không khiến họ thấy
sướng.
**Dependencies**: None

**Acceptance Criteria**:

**1. Leo thang theo số lần dội**

1.1 WHEN bi dội tường, khối chắn, hoặc vật cản chéo THEN system SHALL phát hiệu ứng tại
**đúng điểm va chạm**, với cường độ tăng theo số lần dội đã tích luỹ của cú bắn đang bay.

1.2 WHEN số lần dội tăng THEN system SHALL làm rõ dần hệ số BỪA đang lên, ít nhất qua kích cỡ
hoặc độ đậm của chỉ số hệ số sống.

1.3 WHEN cú bắn đạt số lần dội **cao nhất có thể dùng (`kMaxBanks - 1`, hiện là 4)** THEN system
SHALL cho một phản hồi rõ rệt hơn hẳn các lần dội trước, vì đây là ngưỡng mà mọi mục tiêu trong
game đều đã phá được.

1.4 WHEN thang cường độ được cài THEN system SHALL suy ra ngưỡng cao nhất dùng được bằng
**`kMaxBanks - 1`** thay vì viết cứng số 4, để đổi hằng số không làm thang sai lệch âm thầm.

> **Vì sao `- 1`**: PDR §8.3 — bi chết ngay ở substep mà số lần dội đạt trần, nên mục tiêu đòi
> đúng `kMaxBanks` lần dội là không thể phá. Keying bậc cao nhất vào chính `kMaxBanks` khiến
> AC-1.3 **không bao giờ chạy**.

1.5 WHEN thang cường độ được định nghĩa THEN system SHALL có đúng một bậc cho mỗi giá trị số lần
dội từ **0 tới `kMaxBanks`**, **đơn điệu tăng qua `0..kMaxBanks - 1`**, và mỗi bậc SHALL khác bậc
liền trước ở ít nhất một tham số **đo được** — chọn hình thức thị giác cụ thể vẫn là việc của
Phase 2 (A-open).

> **Vì sao miền tới `kMaxBanks` chứ không dừng ở `kMaxBanks - 1`** (sửa 2026-08-05): `_resolveSegments`
> emit `ShotEvent(bank, bankCount: banks)` ở `shot_runner.dart:170` **trước** khi `_advance` giết bi
> ở `:140`, và `_drain` chạy trong **cùng** tick — nên một sự kiện với `bankCount == kMaxBanks` **có**
> tới tầng hiệu ứng, ở **mọi** cú bắn hết ngân sách dội. Bậc đỉnh vẫn ở `kMaxBanks - 1` (AC-1.3) vì
> đó là ngưỡng mọi mục tiêu đều phá được; bậc `kMaxBanks` chỉ là lần dội cuối trùng lúc cú bắn kết
> thúc, nên nó **dùng lại** bậc đỉnh chứ không leo thêm. PDR §8.3 bó `requiredBanks`, không bó dòng
> sự kiện.

**2. Chỉ tính công dội đúng luật**

2.1 WHEN bi dội vào **mục tiêu** mà chưa đủ số lần dội THEN system SHALL không tăng cường độ
hiệu ứng leo thang, vì dội vào mục tiêu **không tính công dội** (PDR §8.4).

2.2 IF cú bắn chưa dội lần nào THEN system SHALL vẫn hiện capsule hệ số ở `×1`,
nhưng SHALL không phát punch, spark hay hiệu ứng ăn mừng. Capsule là thông tin HUD
thường trực theo `uiux-guideline.md` §4.4; effect level 0 vẫn rỗng.

2.3 WHEN bi rơi ra khỏi đáy sân THEN system SHALL kết thúc tầng hiệu ứng của cú đó và **không**
phát hiệu ứng ăn mừng, vì cú đó đã mất.

**3. Âm thanh và asset**

3.1 WHEN hiệu ứng dội được phát THEN system SHALL dùng các `GameSound` sẵn có trong
`game_audio_service.dart` (`wallImpact`, `comicImpact`) và SHALL **không** yêu cầu asset âm
thanh hay ảnh mới.

3.2 WHEN hiệu ứng phát âm thanh THEN system SHALL đi qua cơ chế cooldown sẵn có của
`game_audio_service` thay vì dựng đường phát âm riêng.

---

### US-2: Khoảnh khắc phá mục tiêu ở hệ số cao được tôn lên

**User Story**: As a Người chơi, I want một cú carom phá nhiều mục tiêu ở hệ số cao trông xứng
đáng với độ khó của nó, so that phần thưởng cho cú bắn giỏi là cảm giác, không chỉ là điểm

**Priority**: Medium
**Business Value**: PDR §8.5 gọi "bi xuyên qua sau khi phá mục tiêu" là **toàn bộ phần thưởng
của cơ chế**. Hiện phần thưởng đó chỉ là tem `+điểm` và một cú rung màn — cùng một cường độ
cho cú ×2 tầm thường và cú ×6 khó nhất game.
**Dependencies**: US-1 — cường độ hiệu ứng phá mục tiêu bám theo thang leo của US-1

**Acceptance Criteria**:

**1. Cường độ theo hệ số**

1.1 WHEN một mục tiêu bị phá THEN system SHALL đặt cường độ hiệu ứng theo **hệ số BỪA tại thời
điểm phá**, sao cho cú ở hệ số cao trông mạnh hơn rõ rệt cú ở hệ số thấp.

1.2 WHEN một cú bắn phá **nhiều mục tiêu liên tiếp** THEN system SHALL cộng dồn cảm giác thay
vì phát lại y nguyên cùng một hiệu ứng, và SHALL không để hiệu ứng của mục tiêu sau xoá hiệu
ứng của mục tiêu trước.

1.3 WHEN cú bắn cuối dọn sạch mục tiêu cuối của màn THEN system SHALL phát một hiệu ứng kết màn
khác biệt với hiệu ứng phá mục tiêu thường.

**2. Giữ nguyên luật hiện có**

2.1 WHEN mục tiêu bị phá THEN system SHALL giữ nguyên rung màn tất định hiện tại (giảm dần
`dt × 4.5`, dịch canvas theo `sin`/`cos`) và SHALL **không** dùng `Random` trong pass vẽ.

2.2 WHEN cú bắn thẳng bị chặn THEN system SHALL giữ tem `Bắn thẳng à?` dùng
`dangerRed` và SHALL **không** làm dịu nó thành phản hồi trung tính
(`uiux-guideline.md` §3.1 và §6.5).

2.3 WHEN vệt ma của cú bắn trước đang trên màn hình THEN system SHALL giữ nó lại sau khi hiệu
ứng kết thúc (`uiux-guideline.md` §5.1 và §10.1).

2.5 WHEN hiệu ứng va chạm và multiplier được vẽ THEN system SHALL dùng
`trajectoryCyan` cho chùm vạch/spark và `primaryGold` cho multiplier/score; SHALL
không dùng tên màu legacy hoặc hex thô trong painter/widget mới.

2.4 WHEN hiệu ứng phá mục tiêu được phát THEN system SHALL dùng âm thanh sẵn có và SHALL không
yêu cầu asset mới.

---

### US-3: Hiệu ứng không được làm mờ luật chơi

**User Story**: As a Người chơi, I want hiệu ứng không che mất tín hiệu cho tôi biết mục tiêu
nào đã phá được, so that tầng ăn mừng không lấy đi thứ đang dạy tôi chơi

**Priority**: High
**Business Value**: PDR §5 và `uiux-guideline.md` §4.3, §5.2 cùng xác định quầng sáng +
đổi biểu cảm khi mục tiêu `armed` là **tính năng dễ đọc quan trọng nhất trong game**, và bất
kỳ thay đổi làm mờ hoặc trễ nó là **hồi quy sản phẩm**. Tầng hiệu ứng là thứ có nguy cơ cao
nhất phá luật này.
**Dependencies**: US-1, US-2

**Acceptance Criteria**:

**1. Tín hiệu `armed` luôn thắng**

1.1 WHILE bi đang bay THEN system SHALL giữ quầng sáng, vòng viền, chip số dội và biểu cảm
hoảng của mục tiêu `armed` **nhìn thấy rõ**, kể cả khi hiệu ứng đang phát ở cùng vùng màn hình.

1.2 WHEN số lần dội của cú đang bay đạt `requiredBanks` của một mục tiêu THEN system SHALL bật
tín hiệu `armed` của mục tiêu đó **ngay tại khoảnh khắc đó**, không trễ vì đang chờ một hiệu
ứng khác chạy xong.

1.3 IF một hiệu ứng phủ lên vùng có mục tiêu chưa bị phá THEN system SHALL vẽ mục tiêu và biểu
cảm của nó **trên** hiệu ứng đó.

1.4 WHEN tầng hiệu ứng được chèn vào `paint()` THEN system SHALL giữ nguyên hợp đồng z-order
hiện tại (ràng buộc C2), và mọi lớp hiệu ứng **phủ vùng sân** SHALL nằm **dưới** lớp mục tiêu.
Các lớp chữ sẵn có (hệ số, tem) SHALL giữ đúng vị trí hiện tại trong hợp đồng — chúng vốn nằm
**trên** mục tiêu, và US-1 AC-1.2 cần chúng ở đó.

**2. Không cản đường chơi**

2.1 WHILE hiệu ứng đang phát THEN system SHALL không chặn thao tác kéo để ngắm và thả để bắn.

2.2 WHEN người chơi bắn cú tiếp theo trong khi hiệu ứng của cú trước còn dở THEN system SHALL
kết thúc hoặc nhường hiệu ứng cũ, và SHALL không hoãn cú bắn mới.

**3. Hiệu năng và ranh giới kiến trúc**

3.1 WHEN tầng hiệu ứng chạy ở cú bắn nặng nhất của game (màn 20: 6 mục tiêu, 5 cú bắn, hệ số
tới ×6) **trên thiết bị tầm thấp** THEN system SHALL giữ **60fps** — không khung nào vượt
**16ms** đo bằng Flutter DevTools timeline — và SHALL không làm chậm bước mô phỏng cố định
1/480s. Thiết bị tham chiếu cụ thể SHALL được ghi vào `design.md` trước khi đo.

3.2 WHEN tầng hiệu ứng được thêm vào THEN system SHALL không thay đổi `lib/sim/`: `kMaxBanks`,
`kMinAimUp`, `kMaxMultiplier`, điểm và mốc sao giữ **nguyên giá trị** (PDR §8.1).

3.3 WHEN tầng hiệu ứng được thêm vào THEN system SHALL vẽ trong `CustomPainter` + `Ticker`
hiện tại và SHALL **không** đưa Flame game loop vào dự án.

3.4 WHEN `lib/sim/` được kiểm tra sau thay đổi THEN system SHALL không có import Flutter nào
trong thư mục đó (PDR §8.7).

3.5 WHEN số lượng phần tử hiệu ứng sống cùng lúc tăng THEN system SHALL áp một **trần trên** cho
số phần tử đó, để một cú carom dài không sinh hiệu ứng không giới hạn. Giá trị trần SHALL được
chốt ở Phase 2 cùng với hình thức thị giác (A-open) — Phase 1 chỉ đòi trần phải tồn tại.

**4. Accessibility — không làm tệ hơn khoảng trống đã biết**

4.1 WHEN hoạt ảnh mới nào được thêm THEN system SHALL gate bằng
`MediaQuery.disableAnimationsOf(context)` theo `uiux-guideline.md` §7.

4.2 WHEN multiplier mới được dựng THEN system SHALL đạt tương phản tối thiểu
**3:1** như chữ gameplay lớn, dùng `primaryGold` trên capsule `panelNavy` và
outline/shadow khi cần; kết quả đo SHALL được ghi vào `design.md`.

4.3 WHEN cường độ hiệu ứng được dùng làm tín hiệu THEN system SHALL không để nó là **kênh duy
nhất** truyền đạt trạng thái `armed` — quầng, biểu cảm và chip số dội vẫn là nguồn chính thức.

4.4 WHEN người chơi bật reduced-motion THEN system SHALL vẫn truyền đạt số lần dội và hệ số hiện
tại qua kênh **tĩnh** (chip số dội trên mục tiêu và chỉ số trên HUD), để tắt hoạt ảnh không làm
mất thông tin luật.

---

### US-4: Cảm được cú dội qua rung tay

**User Story**: As a Người chơi, I want cảm được từng cú dội và từng mục tiêu vỡ qua rung tay,
so that cú bắn có sức nặng vật lý chứ không chỉ là hình ảnh trên kính

**Priority**: Low
**Business Value**: Game chơi dọc một ngón tay, mắt dán vào đường carom. Rung là kênh phản hồi
duy nhất **không** cạnh tranh với thứ mắt đang phải theo — và tầng hình ảnh đã khá đông.
**Dependencies**: None — rung móc trực tiếp vào các mốc sự kiện của `ShotRunner`, không cần tầng
hiệu ứng của US-1/US-2 tồn tại trước (xem AC-4.1)

**Acceptance Criteria**:

**1. Sự kiện có rung**

1.1 WHEN bi dội tường, khối chắn, hoặc vật cản chéo THEN system SHALL phát một rung **nhẹ,
ngắn**.

1.2 WHEN một mục tiêu bị phá THEN system SHALL phát một rung **mạnh hơn** rung dội, khớp với
cú rung màn hiện có.

1.3 WHEN cú bắn thẳng bị chặn (chưa đủ số lần dội) THEN system SHALL phát một **pattern rung khác**
với pattern dùng cho phá mục tiêu, vì đây là tín hiệu *sai ý tưởng*, không phải tín hiệu thành công.

1.4 WHEN màn kết thúc thắng hoặc thua THEN system SHALL phát một rung kết màn.

**2. Không rung quá dày**

2.1 WHEN nhiều va chạm xảy ra sát nhau trong một cú bắn THEN system SHALL giữ tối thiểu **60ms**
giữa hai lần rung, bỏ qua rung của va chạm nằm trong khoảng đó.

2.2 WHEN cooldown rung được cài THEN system SHALL dùng **cùng nguyên tắc** cooldown mà
`game_audio_service.dart` đã dùng cho âm thanh, và SHALL cho **tiêm nguồn thời gian** để
cooldown test được không cần thiết bị (ràng buộc C4).

2.3 WHEN giá trị cooldown được dùng THEN system SHALL đọc từ một hằng số duy nhất, vì 60ms là
con số khởi điểm chờ tune trên máy thật (D4).

2.4 WHEN bi rơi ra khỏi đáy sân THEN system SHALL không phát rung phá mục tiêu, vì cú đó đã mất.

2.5 WHILE người chơi đang kéo để ngắm THEN system SHALL không phát rung, để thao tác ngắm không
bị nhiễu.

**3. Thiết bị và cài đặt**

3.1 IF thiết bị không có bộ rung hoặc không cho phép rung THEN system SHALL bỏ qua rung **im
lặng**: không hiện lỗi, không chặn gameplay.

3.2 IF người chơi đã tắt rung trong Cài đặt THEN system SHALL không phát rung nào.

**4. Ranh giới kiến trúc**

4.1 WHEN rung được móc vào các mốc sự kiện THEN system SHALL dùng **cùng bộ mốc sự kiện của
`ShotRunner`** mà tầng hiệu ứng của US-1/US-2 dùng (dội tường / phá mục tiêu / bắn thẳng bị chặn
/ kết màn), và SHALL không dựng một đường phát hiện va chạm thứ hai.

4.2 WHEN rung được thêm THEN system SHALL không thay đổi `lib/sim/` và SHALL không thêm import
Flutter vào thư mục đó — rung là kênh xuất ở tầng UI (PDR §8.7).

4.3 WHEN rung được cài THEN system SHALL không thêm dependency mới nếu API rung built-in của
Flutter đủ cho AC-1.1..1.4 (ràng buộc C9).

> Nếu buộc phải thêm package, Phase 2 phải nêu lý do trong `design.md`. Đó là nghĩa vụ của Phase 2,
> không phải hành vi hệ thống — nên nó nằm ở ghi chú, không phải một `SHALL`.

---

### US-5: Tắt rung được

**User Story**: As a Người chơi, I want tắt rung, so that tôi chơi được ở chỗ cần yên tĩnh hoặc
khi rung làm tôi thấy khó chịu

**Priority**: Low
**Business Value**: Rung là thứ chia đôi người dùng — nhóm thấy sướng và nhóm thấy phiền. Không
có công tắc thì US-4 tự biến thành một lý do gỡ game.
**Dependencies**: US-4 — không có gì để tắt trước khi rung tồn tại

**Acceptance Criteria**:

**1. Công tắc trong Cài đặt**

1.1 WHEN người chơi mở màn hình Cài đặt THEN system SHALL hiện một công tắc rung đặt **cùng
nhóm** với công tắc Âm thanh và Nhạc nền, dùng cùng component `BbToggle`.

1.2 WHEN người chơi mới mở app lần đầu THEN system SHALL đặt rung **bật** làm mặc định.

1.3 WHEN người chơi bật hoặc tắt công tắc rung THEN system SHALL:
- áp dụng **ngay**, không cần khởi động lại app
- lưu lựa chọn xuống bộ nhớ cục bộ

1.4 WHEN người chơi mở lại app THEN system SHALL khôi phục đúng lựa chọn rung đã lưu.

1.5 IF không đọc được lựa chọn đã lưu THEN system SHALL dùng mặc định **bật** và SHALL không
làm màn hình Cài đặt hỏng.

**2. Schema cài đặt và bản địa hoá**

2.1 WHEN cài đặt được đọc từ một save **được ghi bởi phiên bản trước unit này** THEN system
SHALL đọc thành công và coi rung là **bật**, giữ nguyên `soundOn`, `musicOn`, `localeCode`
(ràng buộc C5).

2.2 WHEN công tắc rung được thêm THEN system SHALL phát `Semantics.toggled` và có
`semanticLabel`, theo đúng hợp đồng `BbToggle` hiện tại.

2.3 WHEN nhãn công tắc rung được thêm THEN system SHALL có bản dịch ở **cả** `app_vi.arb` và
`app_en.arb`.

---

## Ngoài phạm vi

- **Mọi thay đổi lên điểm, sao, hoặc ba hằng số cân bằng** (`kMaxBanks`, `kMinAimUp`,
  `kMaxMultiplier`). Đổi một trong ba là toàn bộ 20 màn vô hiệu, phải chạy lại `node campaign.js`.
- **Asset ảnh hoặc âm thanh mới** (D1).
- **Flame game loop** (D2).
- **Sửa mọi khoảng trống accessibility ngoài phần bị unit này chạm tới.** Unit này
  phải đạt target mới cho multiplier, reduced motion và semantics liên quan; các
  màn/component không liên quan vẫn ngoài phạm vi.
- **Nhân vật có tên và thoại** (`004/US-003`) — thuộc Unit 3 (`giong-va-cau-truc-ngoai-san-dau`).
- **Gợi ý, bỏ qua màn, xu** — thuộc Unit 1 (`duong-ra-khoi-man-bi`).

## Điều kiện tiên quyết

PDR §11 đặt `flutter test` chạy được và **playtest 20 màn** trước mọi việc thêm; repo hiện
**chưa từng được biên dịch**. Riêng với unit này, playtest còn là điều kiện *thực dụng*: AC-3.1
đòi đo 60fps ở màn 20 và D4 đòi tune cooldown rung trên máy thật — cả hai không kiểm được trong
môi trường không có thiết bị.

---

## Next Steps

Once these requirements are approved, proceed to Phase 2: Design Document Creation.

**What to do next:**
1. Use the slash command: `/aidlc.construction.create-design`
2. The agent will automatically read `references/phase-2-design.md` for detailed workflow instructions
3. Foundation docs will be referenced for architecture alignment

This will create `design.md` with comprehensive design based on these requirements.
