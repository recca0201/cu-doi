---
artifact_type: foundation
document: project-overview-pdr
project: ban_bua_tuong
status: draft
created: 2026-08-04
updated: 2026-08-11
source_artifacts:
  - ../../../ban_bua/aidlc-docs/brainstorming/0003-ricochet-core-loop-reconcept.md
  - lib/sim/shot_runner.dart
  - lib/sim/arenas.dart
  - tools/solver/campaign.js
  - Cu_Doi_UI_UX_Design_Spec.docx
  - test/ui/goldens/arena_map_390x844.png
  - assets/images/backgrounds/vietnam_karst_canyon_v2.png
  - assets/images/ui/karst/
---

# Bắn Bừa — Cú Dội · Mô tả sản phẩm

## 1. Một câu

Game bắn dội tường trên điện thoại, chơi dọc một ngón tay: **bắn trúng trực tiếp
thì không phá được gì** — mỗi mục tiêu chỉ vỡ sau khi cú bắn đã dội tường đủ số
lần mà nó đòi.

## 2. Vì sao game này tồn tại

Đây không phải một ý tưởng mới nảy ra. `ban_bua` — game bắn bong bóng ghép màu —
bị App Store từ chối theo **Guideline 4.3(a) (Spam)** ngày 03/08/2026, với câu
nặng nhất trong bộ khung: *"review the app concept and submit a unique app with
distinct content and functionality."* Apple chỉ vào **chức năng**, không phải
metadata.

Kiểm tra code cho thấy họ có lý: vòng chơi cũ là Puzzle Bobble đúng nghĩa (lưới
hex, flood fill ghép 3), và còn ít hơn chuẩn thể loại — trần lưới không bao giờ
hạ, không có hàng nào được thêm vào, nên fail state duy nhất là hết lượt bắn. Bốn
"điểm đặc biệt" quảng cáo trên store (HYPE, BẮN BỪA, CRIT, ghép biểu cảm) hầu hết
chỉ tác động tới **điểm và hiệu ứng**, không tác động tới quyết định mỗi lượt.
Khoảng 100 dòng trên tổng ~5.300 dòng là cơ chế thật sự không generic.

Hệ quả cho thiết kế: **quyết định mỗi lượt phải thôi là "bắn vào cụm màu nào"**.
Ở đây nó là một bài toán hình học. Người duyệt nhận ra khác biệt ngay từ cú bắn
đầu tiên, vì cú bắn thẳng hiển nhiên không có tác dụng.

Lý do đầy đủ và các phương án đã cân: `0003-ricochet-core-loop-reconcept.md` trong
repo `ban_bua`.

## 3. Vòng chơi

1. Người chơi kéo để ngắm từ bệ phóng ở đáy sân, thả tay để bắn. Tương tác vật lý
   giữ đúng như game cũ — cái thay đổi là **cú bắn có nghĩa gì**.
2. Bi bay và **không dừng lại khi va chạm**. Nó dội tường, dội khối chắn, dội vật
   cản chéo, và tiếp tục cho tới khi hết ngân sách dội hoặc rơi ra khỏi đáy sân.
3. Mỗi mục tiêu hiển thị một con số: **số lần dội tối thiểu** mà cú bắn phải tích
   luỹ được **trước khi** nó có thể phá mục tiêu đó.
   - Chưa đủ: bi nảy ra, mục tiêu nhếch mép, hiện chữ "Bắn thẳng à?". Cú bắn chưa
     mất — bi vẫn còn bay, vẫn có thể dội thêm rồi quay lại.
   - Đủ rồi: mục tiêu vỡ và **bi xuyên qua, giữ nguyên hướng** — nên một đường
     carom có thể quét cả một hàng.
4. Mỗi lần dội nâng hệ số **BỪA**. Phá mục tiêu ở lượt dội thứ n ăn ×(1+n) điểm.
5. Đáy sân **không có tường** (vẽ bằng vạch gạch đỏ). Bi rơi xuống là mất luôn cú
   đó. Đây là cái giá khiến "cố dội thêm để ăn hệ số" là một quyết định thật chứ
   không phải điểm miễn phí.
6. Thắng khi sạch mục tiêu. Thua khi hết lượt bắn mà còn mục tiêu.

## 4. Hằng số luật chơi

| Hằng số | Giá trị | Nơi định nghĩa | Ghi chú |
|---|---|---|---|
| Sân đấu | 100 × 160 đơn vị logic | `lib/sim/arena.dart` | Mô phỏng không bao giờ thấy pixel, nên hành vi giống nhau trên mọi máy |
| Bán kính bi | 2.2 | `arena.dart` | |
| Bán kính mục tiêu | 4.6 | `arena.dart` | |
| Tốc độ bi | 132 đv/giây | `arena.dart` | Đủ chậm để đọc đường carom |
| Ngân sách dội | **5** | `arena.dart` `kMaxBanks` | Đọc mục 8 trước khi đổi |
| Hệ số BỪA tối đa | **×6** | `arena.dart` `kMaxMultiplier` | Khớp với ngân sách dội |
| Điểm mỗi mục tiêu | 100 × hệ số | `arena.dart` | |
| Góc bắn tối đa | ~59° so với thẳng đứng | `shot_runner.dart` `kMinAimUp = 0.6` | Đọc mục 8 trước khi đổi |
| `requiredBanks` dùng được | **1..4** | — | Không thể bằng 5, xem mục 8 |
| Bệ phóng | (50, 150) | `arena.dart` `kShooterOrigin` | |

Va chạm: tích phân substep cố định 1/480s, không phải swept-analytic. Ở tốc độ
132 thì mỗi substep bi đi 0.275 đơn vị so với bán kính 2.2 — không thể xuyên
tường, dư an toàn 8 lần. Cách này thô nhưng hiển nhiên đúng, và đó là lựa chọn có
chủ ý cho một cơ chế mà độ chính xác hình học là toàn bộ trò chơi.

Chi tiết luật nằm trong `ShotRunner._resolveTargets()` — đọc hàm đó trước tiên nếu
muốn hiểu game.

## 5. Cảm giác cần đạt, và cách đọc luật

Trải nghiệm đích là **kỹ năng và sự thuần thục**: khoái cảm đến từ việc thực hiện
một cú khó. Tên game trở thành cách chơi chữ có ý: cú bắn *trông như* bừa bãi lại
chính là cú đã tính toán.

Ba thứ làm luật tự dạy chính nó, không cần tutorial dài:

- **Mục tiêu phát sáng khi đã phá được.** Khi bi đang bay và số lần dội tăng lên,
  từng tầng mục tiêu sáng lên và đổi biểu cảm từ tự đắc sang hoảng, đúng lúc chúng
  trở nên phá được. Người chơi không cần đọc số cũng hiểu. **Đây là tính năng dễ
  đọc quan trọng nhất trong game — đừng bỏ nó khi refactor.**
- **Cú bắn thẳng bị nảy ra kèm chữ.** Nó không phải "gần trúng", nó là **sai ý
  tưởng**, và mục tiêu nói thẳng như vậy. Màn 1 được thiết kế chỉ để dàn dựng đúng
  khoảnh khắc này: mục tiêu đầu tiên nằm trên đường thẳng rõ ràng từ bệ phóng.
- **Vệt bi mờ của cú vừa rồi được giữ lại.** Học một đường carom dễ hơn nhiều khi
  đường vừa đi vẫn còn trên màn hình.

Ngắm chỉ hiện **hai đoạn đầu** của đường bay. Game cũ tô sáng mọi bong bóng sẽ nổ,
tức là lấy luôn phần kỹ năng của người chơi — ở đây chỉ cho đủ để học phản xạ của
tường, không cho đáp án.

### Hướng hình ảnh đã chốt

Ngày 11/08/2026, art direction đang render trong app được duyệt làm nguồn chuẩn:
**Vietnamese karst adventure arcade** — phong cảnh núi đá vôi sáng và sương xanh,
panel sơn mài xanh ngọc/teal, khung đồng-vàng chạm khắc, chữ Baloo 2/Nunito, viền
dày và bóng sticker cứng. CTA chính vẫn là vàng; cyan chỉ là accent cho quỹ đạo,
va chạm và thông tin cần nổi bật. Vùng gameplay/HUD được phép tối để giữ tương
phản, nhưng không biến shell toàn app thành nền indigo/navy/galaxy.

Nguồn hình ảnh ưu tiên là golden đang pass, asset `assets/images/ui/karst/`,
backdrop `vietnam_karst_canyon_v2.png` và code đang render. UI/UX Design Spec 1.0
ngày 09/08/2026 cùng asset `ui/galaxy/` chỉ còn giá trị lịch sử/tham khảo cấu
trúc; chúng không được dùng để ghi đè style karst hiện hành. Chi tiết và quy tắc
xử lý xung đột nằm ở [`uiux-guideline.md`](./uiux-guideline.md).

Hình tham chiếu chỉ quyết art direction và hierarchy. Mọi con số màn, vị trí hình
học, luật dội, mở màn và mốc sao vẫn lấy từ model/solver; các nút shop/event/mission
trong hình không được đưa vào production nếu chưa có luồng chức năng thật.

## 6. Nội dung: 20 màn, 4 chương

| Màn | Tên | Mục tiêu | requiredBanks | Cú bắn | Mốc sao |
|---|---|---|---|---|---|
| **Chương 1 — Học luật dội** | | | | | |
| 1 | Bắn thẳng không tính | 3 | 1/1/1 | 3 | 750/1100/1350 |
| 2 | Ba đứa trên cao | 3 | 3/3/4 | 3 | 750/1100/1350 |
| 3 | Sát tường | 3 | 2/2/1 | 3 | 650/950/1150 |
| 4 | Hình thoi | 4 | 1/2/2/1 | 3 | 950/1350/1700 |
| 5 | Sau cây cột | 3 | 3/3/2 | 3 | 650/950/1150 |
| **Chương 2 — Kệ và hốc** | | | | | |
| 6 | Ngóc ngách | 4 | 1/2/2/3 | 3 | 900/1300/1600 |
| 7 | Mái che | 3 | 2/2/2 | 3 | 750/1100/1350 |
| 8 | Bậc thang | 3 | 2/3/2 | 3 | 700/1000/1250 |
| 9 | Hai cái hốc | 4 | 2/2/2/1 | 3 | 900/1300/1600 |
| 10 | Kẹp giữa | 3 | 3/2/2 | 4 | 750/1100/1350 |
| **Chương 3 — Zig-zag** | | | | | |
| 11 | Chuỗi dội | 4 | 1/2/3/4 | 3 | 800/1150/1450 |
| 12 | Leo thang | 5 | 1/2/3/4/1 | 3 | 1150/1650/2050 |
| 13 | Hành lang | 4 | 3/2/1/1 | 4 | 900/1300/1600 |
| 14 | Dán tường | 4 | 2/3/2/3 | 3 | 900/1300/1600 |
| 15 | Chữ thập | 4 | 2/2/2/2 | 3 | 900/1300/1600 |
| **Chương 4 — Vật cản chéo** | | | | | |
| 16 | Chéo giữa sân | 3 | 2/2/1 | 3 | 750/1100/1350 |
| 17 | Cái phễu | 3 | 3/3/2 | 3 | 750/1100/1350 |
| 18 | Nóc nhà | 4 | 3/2/2/1 | 4 | 1000/1450/1800 |
| 19 | Hai lưỡi dao | 4 | 3/2/2/2 | 4 | 850/1200/1550 |
| 20 | Bừa hết cỡ | 6 | 4/3/3/2/2/1 | 4 | 1300/1850/2350 |

Tổng: 74 mục tiêu, 65 lượt bắn. `lib/sim/arenas.dart` là **file được sinh ra** —
hình học hand-authored trong `tools/solver/campaign.js`, còn mọi con số độ khó do
solver chạy mô phỏng thật sinh ra. Đừng sửa tay các con số đã tune.

## 7. Kiến trúc

```
lib/sim/         Dart THUẦN — không import Flutter. Test được không cần thiết bị.
  geometry.dart    V2, va chạm điểm–đoạn thẳng
  arena.dart       hằng số + model sân đấu
  shot_runner.dart LUẬT CHƠI
  arenas.dart      20 sân đấu (generated)
lib/core/        token, theme, palette sân đấu, audio service
lib/data/        settings + progress (SharedPreferences)
lib/domain/      player_progress (sao, điểm cao, xu, mở màn)
lib/state/       providers Riverpod
lib/ui/          fit, arena_painter (CustomPainter), 4 screen
tools/solver/    bản port JS + solver vét cạn (Node, không cần Flutter)
```

Nguyên tắc kiến trúc quan trọng nhất: **`lib/sim/` không được import Flutter.** Đó
là thứ cho phép kiểm chứng luật chơi bằng `flutter test` không cần thiết bị, và
cho phép port sang JS để vét cạn. Giữ ranh giới này.

Render là `CustomPainter` + `Ticker`, **không dùng Flame game loop** (chỉ dùng
`flame_audio` để tái sử dụng `game_audio_service.dart` nguyên trạng).

## 8. Bất biến không được phá

1. **`kMaxBanks`, `kMinAimUp`, `kMaxMultiplier` là ba con số cân bằng toàn cục.**
   Đổi bất kỳ giá trị nào là toàn bộ 20 màn vô hiệu — phải chạy lại
   `node campaign.js`.
2. **Cơ chế này có một chiến thuật suy biến tự nhiên: bắn gần nằm ngang cho bi
   ping-pong quét cả sân.** Bản tham số đầu tiên (`kMaxBanks = 14`, góc tới ~78°)
   cho phép dọn sạch mọi màn bằng **1 cú** và ăn luôn 3/3 sao. Đòn bẩy chặn nó là
   **giới hạn góc bắn**, không phải giảm số lần dội. Mỗi sân đấu mới và mỗi lần đổi
   tham số đều phải kiểm lại bằng `tune.js`.
3. **`requiredBanks` không bao giờ được bằng `kMaxBanks`.** Bi chết ngay ở substep
   mà số lần dội đạt trần, nên mục tiêu đòi 5 lần dội là không thể phá. Trần dùng
   được là 4.
4. **Dội vào mục tiêu không tính công dội.** Chỉ tường, khối chắn và vật cản chéo
   mới tính. Nếu đổi điều này, người chơi sẽ farm hệ số bằng cách nảy qua lại giữa
   hai mục tiêu.
5. **Phá mục tiêu thì bi xuyên qua, giữ nguyên vận tốc.** Đây là toàn bộ phần
   "thưởng" của cơ chế. Nếu bi dừng lại, một cú carom lớn chỉ ăn được một mục tiêu.
6. **Đáy sân không có tường.** Đừng thêm.
7. **`lib/sim/` không import Flutter.**

## 9. Phạm vi

**Trong phạm vi, đã làm:** vòng chơi lõi; 20 màn 4 chương; sao và điểm cao; xu tích
luỹ; mở màn tuyến tính; menu, chọn màn, cài đặt; song ngữ VI/EN với VI là mặc định;
âm thanh; lưu tiến trình cục bộ.

**Trong phạm vi, chưa làm:** tầng hiệu ứng truyện tranh thiết kế lại quanh số lần
dội; gợi ý và bỏ qua màn; nhóm màn theo chương trên bản đồ; haptics; nhân vật có
tên và thoại.

**Ngoài phạm vi hiện tại:** Firebase (đồng bộ tiến trình), quảng cáo, IAP, chơi
mạng, bảng xếp hạng, editor màn trong app.

## 10. Rủi ro đã biết

- **Vui hay không thì chưa ai biết.** Solver chứng minh được "giải được", không
  chứng minh được "vui". Câu hỏi số một: khoảnh khắc cú bắn thẳng đầu tiên bị nảy
  ra gây tò mò hay gây khó hiểu? Nếu là khó hiểu thì cả hướng này sai.
- **Máy tìm được cú bắn sau 721 góc không có nghĩa người tìm được.** Cần playtest
  để biết độ khó thật.
- **Puzzle dội tường có thể làm người chơi tắc hẳn**, khác với ghép-3 nơi luôn còn
  một nước đi hợp lệ. Gợi ý/bỏ qua màn là bắt buộc, không phải tuỳ chọn.
- **Góc bắn bị bó còn ~59°** là cần thiết về cân bằng nhưng có thể gây cảm giác
  ngột. Nếu đúng vậy thì phải tìm cách chống suy biến khác.
- **Chưa có dòng code nào được biên dịch.** Xem README.

## 11. Việc tiếp theo, theo thứ tự

1. `flutter create --platforms=android,ios .` rồi `flutter pub get && flutter
   gen-l10n && flutter test`. Sửa lỗi biên dịch — nếu có, gần như chắc ở `lib/ui/`.
2. Playtest 20 màn. Trả lời câu hỏi ở mục 10 trước khi làm thêm bất cứ thứ gì.
3. Gợi ý / bỏ qua màn.
4. Thiết kế lại hiệu ứng truyện tranh quanh số lần dội, rồi port
   `comic_effect_controller.dart` từ `ban_bua` (1070 dòng code tốt, nhưng đang gắn
   vào `popped`/`isCrit`/`isRage`).
5. Nhóm màn theo chương trên `arena_map_screen`.
6. Quyết định bundle ID (README có phân tích) rồi mới tính chuyện submit.
