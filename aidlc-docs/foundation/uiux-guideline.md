---
artifact_type: foundation
document: uiux-guideline
project: ban_bua_tuong
status: approved-target
created: 2026-08-05
updated: 2026-08-09
source_artifacts:
  - ../../Cu_Doi_UI_UX_Design_Spec.docx
  - Cu_Doi_UI_UX_Design_Spec.docx#Hình-tham-chiếu-thiết-kế-tổng-thể-các-màn-hình
  - project-overview-pdr.md
  - lib/core/bb_tokens.dart
  - lib/core/bb_theme.dart
  - lib/core/arena_ink.dart
  - lib/ui/arena_painter.dart
  - lib/ui/screens/menu_screen.dart
  - lib/ui/screens/arena_map_screen.dart
  - lib/ui/screens/game_screen.dart
  - lib/ui/screens/settings_screen.dart
---

# Cú Dội · Hướng dẫn UI/UX

**Thiết kế đích**: UI/UX Design Spec 1.0  
**Khổ tham chiếu**: mobile portrait 390 × 844  
**Trạng thái**: đã chốt làm nguồn thiết kế cho các thay đổi UI tiếp theo

> Tài liệu này thay thế định hướng “vỏ sáng sky/cream, sân đấu tối” trước đây.
> Toàn bộ sản phẩm nay dùng cùng một ngôn ngữ **arcade đêm**: nền indigo/navy,
> panel tối, CTA vàng, CTA phụ xanh, viền dày và glow có kiểm soát.
>
> Các nhãn **[Target]** mô tả giao diện cần đạt. Các nhãn **[Observed]** mô tả
> code hiện tại. Không được đọc một mục [Target] như thể nó đã được triển khai.

## 1. Thứ tự ưu tiên khi tài liệu xung đột

1. Luật chơi và bảy bất biến trong
   [`project-overview-pdr.md`](./project-overview-pdr.md) luôn thắng mọi mockup.
2. File Word `Cu_Doi_UI_UX_Design_Spec.docx` và hình tổng hợp 10 trạng thái trong
   file đó là nguồn cho art direction, bố cục và hierarchy.
3. Tài liệu này chuẩn hoá hai nguồn trên thành quy tắc triển khai.
4. Các spec cấp unit dùng tài liệu này; nếu còn mô tả giao diện sky/cream,
   đường mòn uốn lượn hoặc CTA coral thì phần đó đã lỗi thời.

### 1.1. Sai khác có chủ đích so với hình tham chiếu

- Hình chọn màn đặt cả 20 màn dưới nhãn “Chương 1”. Campaign thật có **4 chương,
  mỗi chương 5 màn**; UI phải giữ cấu trúc thật, không sao chép nhãn sai.
- Cửa hàng, Sự kiện, Nhiệm vụ và nút “+” cạnh xu chỉ xuất hiện khi có luồng chức
  năng thật. Không đưa placeholder chết vào production.
- Màn “Kết thúc lượt” là pattern tuỳ chọn. Ở màn 1–3 có thể dùng card đầy đủ để
  dạy scoring; các màn sau ưu tiên micro-summary để không cắt nhịp.
- Hình là visual target, không phải đặc tả hình học sân. Vị trí mục tiêu, vật cản,
  `requiredBanks`, lượt bắn và mốc sao vẫn lấy từ model/solver.

## 2. Nguyên tắc thiết kế

1. **Luật tự dạy bằng hình ảnh.** Người chơi phải hiểu “bắn thẳng không phá được”
   trong 1–2 lượt, nhờ phản hồi ngay tại mục tiêu thay vì tutorial dài.
2. **Số lần dội là thông tin số một.** Số `requiredBanks`, số dội hiện tại và hệ
   số phải đọc được trong lúc mắt đang bám viên bi.
3. **Arcade đêm, không trở lại bubble shooter.** Không dùng lưới bong bóng, ghép
   màu, trần hạ dần hoặc power-up theo khuôn bubble shooter. Bốn màu mục tiêu là
   phân nhóm thị giác, không phải luật ghép màu.
4. **Kỹ năng vẫn thuộc về người chơi.** Preview chỉ có hai đoạn đầu; không hiển
   thị toàn bộ đáp án carom.
5. **Phản hồi mạnh nhưng không che sân.** Glow, spark, score pop và comic burst
   phải ngắn, có z-order rõ, không che mục tiêu còn sống hay đường bay tiếp theo.
6. **Một ngón tay, dọc màn hình.** Điều khiển chính nằm trong tầm ngón cái; chrome
   ở top safe area; mọi hit target tối thiểu 44 × 44 pt, mục tiêu triển khai 48dp.

## 3. Design system đích

### 3.1. Bảng màu ngữ nghĩa [Target]

| Token đích | Giá trị | Vai trò |
|---|---:|---|
| `nightIndigo` | `#090D2A` | Nền app và nền sân; tạo tương phản với cyan |
| `panelNavy` | `#151B3E` | Card, HUD, dialog, capsule |
| `primaryGold` | `#FFC21C` | CTA chính, sao, điểm nổi bật |
| `secondaryBlue` | `#1976D2` | CTA phụ, điều hướng |
| `tertiaryPurple` | `#7E32C8` | Hành động cấp ba, shop/event nếu có |
| `dangerRed` | `#F04444` | Đáy mở, thất bại, cảnh báo |
| `trajectoryCyan` | `#54D9FF` | Bi, trail, điểm va chạm, minh hoạ quỹ đạo |
| `successGreen` | `#7ED321` | Đủ điều kiện, kỷ lục mới, xác nhận tích cực |
| `cream` | `#FFF3D7` | Chữ/surface sáng dùng tiết chế |
| `textPrimary` | `#FFFFFF` | Tiêu đề và nội dung chính trên nền tối |
| `textMuted` | `#AAB2D5` | Chú thích, metadata, trạng thái phụ |
| `outlineDark` | `#080B1B` | Viền ngoài và bóng cứng |

**Quy tắc**:

- Không dùng hex thô trong widget. Các giá trị trên phải đi qua token; nếu code
  cũ chưa có token tương ứng thì thêm/chuyển token trước khi dựng màn.
- `primaryGold` là CTA chính xuyên suốt: **Chơi, Tiếp theo, Thử lại**.
- `secondaryBlue` là CTA phụ: **Chọn màn, Về menu**.
- Purple không thay cho CTA chính.
- Trạng thái không bao giờ chỉ dựa vào màu; luôn có thêm hình dạng, outline,
  biểu cảm, icon hoặc chữ.

### 3.2. Chuyển đổi từ code hiện tại [Observed → Target]

| Hiện tại | Thiết kế đích | Ghi chú migration |
|---|---|---|
| `sky`/`cream` làm nền màn ngoài sân | `nightIndigo` + texture sao/chấm rất nhẹ | Bỏ mô hình hybrid sáng/tối |
| `bbCoral` primary | `primaryGold` | Không đổi nhãn variant mà giữ màu cũ một cách âm thầm |
| `bbTeal` secondary | `secondaryBlue` | Teal có thể giữ cho trạng thái riêng, không làm CTA phụ |
| `bbGrape` | `tertiaryPurple` | Dành cho cấp ba/shop/event có thật |
| `ArenaInk.cream` cho trail | `trajectoryCyan` | Chữ HUD vẫn dùng white/cream |
| Sunburst sáng toàn màn | Star field/ray tối, chỉ tăng cường ở màn thắng | Giảm nhiễu ở menu và map |
| Card trắng | Panel navy gradient/solid | Chữ đổi sang trắng/muted |

Tên API cũ có thể giữ tạm trong lúc migration, nhưng mọi tài liệu và test mới
phải gọi theo **vai trò ngữ nghĩa**, không gọi theo màu cũ.

### 3.3. Typography [Target]

- Display/logo: font tròn, nặng, chất comic; ưu tiên Baloo 2 hoặc font thương hiệu
  hiện có. Logo được phép outline/shadow nhiều lớp.
- UI/body: sans-serif dễ đọc; dùng Nunito hiện có nếu render tiếng Việt ổn.
- Không quá hai họ font trên một màn.
- Mọi con số gameplay dùng display face đậm, có outline/shadow khi nằm trên sân.

| Vai trò | Cỡ tham chiếu 390pt | Weight | Dùng cho |
|---|---:|---:|---|
| Logo | 56–72 | 800 | `CÚ DỘI` ở menu |
| Hero result | 40–52 | 800 | `THẮNG!`, `HẾT LƯỢT!` |
| Screen title | 20–24 | 700–800 | Chọn màn, Hướng dẫn, Màn N |
| Primary button | 18–22 | 800 | CTA |
| Target number | ≥ 18 | 800 | `requiredBanks` 1–4 |
| Body | 14–16 | 600 | Mô tả, hướng dẫn |
| Caption | 12–13 | 600–700 | Nhãn HUD, metadata |

### 3.4. Khoảng cách, bán kính và độ nổi

- Dùng lưới 4dp; gutter chuẩn 16–20dp.
- Bo nút 14–18dp; panel lớn 18–24dp; icon button hình tròn.
- Viền ngoài 2–3dp `outlineDark`; inner highlight 1dp trắng ở 20–30% opacity.
- Bóng cứng 0/4dp, blur thấp hoặc bằng 0; không dùng elevation Material mặc định.
- Glow chỉ dành cho CTA chính, quỹ đạo, mục tiêu `armed`, sao và khoảnh khắc thắng.

## 4. Component library

### 4.1. Button hierarchy

| Loại | Màu | Cao | Ứng dụng | Trạng thái |
|---|---|---:|---|---|
| Primary | gold gradient | 58–64 | Chơi, Tiếp theo, Thử lại | default/pressed/disabled |
| Secondary | blue gradient | 52–58 | Chọn màn, Về menu | default/pressed/disabled |
| Tertiary | purple gradient | 48–54 | Cửa hàng/sự kiện có thật | default/pressed/disabled |
| Icon | dark circular | 44–48 | Back, pause, settings, close | default/pressed/disabled |
| Bottom utility | dark capsule | 56–64 | Sự kiện, nhiệm vụ, cài đặt | selected/unselected |

Nút có outer stroke tối, inner highlight sáng và shadow cứng. Khi nhấn: dịch xuống
2dp, shadow ngắn lại, brightness giảm 8–12%. Disabled: saturation giảm khoảng 70%,
opacity 55%, không glow. Icon hành động đặt trái; chevron tiến tới đặt phải.

### 4.2. Panel, dialog và HUD

- Panel nền `panelNavy`, viền xám-xanh sáng vừa đủ, inner highlight mảnh.
- Dialog dùng scrim đen 70–80%; primary action ở trên secondary action.
- Top HUD tối giản: pause trái, tên màn giữa, lượt còn lại phải.
- Không dùng card trắng lớn trong hệ đích.
- Safe area không được làm lệch tâm arena; HUD và shooter nằm ngoài vùng che của
  notch/home indicator.

### 4.3. Target token

- Đường kính nhìn 46–58px ở khổ 390pt; stroke đôi; số 1–4 ở giữa.
- Màu target có thể là purple/red/blue/green/gold theo palette, nhưng **không mang
  luật ghép màu**.
- `unarmed`: màu bình thường hoặc tối nhẹ; nét mặt tự tin/trêu.
- `armed`: outer glow, outline mạnh hơn, số punch một lần, nét mặt hoảng.
- Target vỡ: crack → burst; bi xuyên qua, không đổi vận tốc.

### 4.4. Shooter, trajectory và multiplier

- Shooter là bệ tròn ở đáy, core xanh/cyan phát glow nhẹ.
- Khi ngắm: dotted guide, tối đa hai đoạn; đoạn sau phản xạ nhạt hơn đoạn đầu.
- Khi bay: core sáng, trail cyan 2–3px, điểm va chạm là spark/ring ngắn.
- Vạch đáy đỏ nét đứt luôn nhìn thấy; không được vẽ thành tường kín.
- Multiplier là capsule dọc bên phải: `×1…×6`, số là thông tin chính; punch
  120–200ms khi tăng. Ở trạng thái nghỉ có thể hiện `×1` để người mới hiểu hệ số.

## 5. Hợp đồng sân đấu bắt buộc

Các điều dưới đây là luật, không phải lựa chọn thẩm mỹ:

1. `requiredBanks` chỉ hiển thị 1–4. Giá trị 5 là không thể phá vì bi chết khi đạt
   `kMaxBanks = 5`.
2. Target `armed` ngay khi `currentBanks >= requiredBanks`; glow và đổi biểu cảm
   xảy ra lập tức, không chờ animation khác.
3. Dội target không tăng bank count. Chỉ tường, blocker và vật cản chéo tăng.
4. Target bị phá thì bi xuyên qua và giữ nguyên vận tốc.
5. Đáy sân mở; bi rơi xuống kết thúc **cú bắn**, không mặc định kết thúc màn.
6. Aim preview chỉ có hai đoạn đầu.
7. Hiệu ứng không được che target còn sống, chip số dội, đường bay hoặc vạch đáy.
8. Mọi hình học sân scale từ hệ logic 100 × 160; không hard-code vị trí pixel.

### 5.1. Z-order đích

`nền → khung/vật cản → vệt ma → trail → hiệu ứng va chạm → target → tín hiệu armed → aim preview → shooter → bi → HUD sân/multiplier → stamp`

Tín hiệu `armed` và target còn sống phải nằm trên particle/comic effect. Vệt ma
của cú trước vẫn được giữ để người chơi học đường carom.

## 6. Mười màn hình/trạng thái chuẩn

### 6.1. Màn hình chính

**Mục tiêu**: vào game trong một chạm, nhận diện “Cú Dội” ngay lần mở đầu.

- Top: Settings bên trái; số xu bên phải. Dấu `+` chỉ có khi tồn tại luồng kiếm/mua.
- Hero: logo chiếm khoảng 30% chiều cao đầu; subtitle “Game bắn dội tường”.
- CTA dọc: Chơi (gold, lớn nhất), Chọn màn (blue), action cấp ba nếu có thật.
- Utility đáy chỉ hiện feature đã triển khai. Không dựng shop/event/mission chết.
- `Chơi` mở màn chưa hoàn thành gần nhất; người mới vào Màn 1.

### 6.2. Chọn màn

**Mục tiêu**: đọc được 20 màn, 4 chương, sao và trạng thái khoá/mở.

- Header: Back, “CHỌN MÀN”, tổng sao.
- Nội dung: **grid 4 cột** trên điện thoại; mỗi chapter là một section 5 màn hoặc
  carousel theo chapter. Không dùng đường mòn uốn lượn.
- Level node tròn/bo tròn, có số màn và 0–3 sao; current dùng gold outline + glow;
  locked dùng navy/gray + lock.
- Tên chapter và tiến độ `n/15` luôn hiện. Luật mở màn vẫn tuyến tính, không thêm
  cổng khoá chapter.
- Chạm màn khoá: shake ngắn + tooltip/snackbar “Hoàn thành màn trước để mở”.
- Khi quay lại sau thắng/bỏ qua, đưa chapter và node đích vào viewport mà không
  tạo cú cuộn hoạt ảnh bắt buộc.

### 6.3. Gameplay — đang ngắm

- HUD: Pause / Màn N / Lượt còn lại.
- Arena chiếm gần toàn phần thân; shooter nằm trên vạch đáy mở.
- Drag để ngắm, release để bắn; aim clamp tự nhiên trong `kMinAimUp` hiện có.
- Dotted trajectory tối đa hai đoạn; multiplier bắt đầu `×1`.
- Tutorial lần đầu: “Kéo để ngắm · Thả tay để bắn”.
- Cần thiết kế đủ các state: valid, clamped, pause, first-run hint.

### 6.4. Gameplay — bi đang bay

- Aim guide biến mất; trail cyan và impact point trở thành tiêu điểm.
- Mỗi bank hợp lệ tăng multiplier lên `×(1+n)`, tối đa `×6`.
- Mục tiêu đủ điều kiện đổi state ngay trong lúc bi bay.
- Bi rơi qua đáy: trail fade nhanh + miss sound; không phát hiệu ứng phá.

### 6.5. Mục tiêu chưa đủ dội

- Phản hồi tại target, không bật modal.
- Squash/stretch hoặc nảy nhẹ 200–300ms; nét mặt trêu/chống đối.
- Speech bubble “Bắn thẳng à?” ở lần đầu hoặc theo cooldown; không che quỹ đạo.
- Bi vẫn tiếp tục bay; không tăng bank count vì va target.

### 6.6. Phá mục tiêu

- Crack → burst, score pop 400–600ms; bi xuyên qua.
- Hiển thị `+100 × hệ số` hoặc điểm đã nhân, nhưng không đồng thời cả hai nếu gây
  khó đọc.
- Phá nhiều target: cadence liên tiếp, không xoá effect trước.
- Target cuối: hit-stop 40–70ms, không freeze quá 100ms mỗi target.

### 6.7. Kết thúc lượt

- Màn 1–3: compact card/bottom sheet có target đã phá, điểm, hệ số cao nhất,
  số lần dội và CTA Tiếp tục.
- Màn sau: ưu tiên micro-summary tự thu gọn sau 1–1.5s.
- Không xuất hiện nếu playtest cho thấy làm đứt nhịp.

### 6.8. Hết lượt — thua

- Full-screen overlay hoặc modal trung tâm; arena dim 70–80%.
- Headline đỏ/cam “HẾT LƯỢT!”, lý do “Bạn chưa phá hết các mục tiêu”.
- Primary “THỬ LẠI”; secondary “VỀ MENU” hoặc “CHỌN MÀN”.
- Có thể hiện số target còn lại. Sau nhiều lần thua mới hiện Gợi ý/Bỏ qua màn.

### 6.9. Thắng màn

- Headline “THẮNG!” + ray/spark; 3 sao ở trung tâm.
- Sao fill tuần tự cách nhau 180–250ms theo `starThresholds` thật.
- Điểm cuối; `Kỷ lục mới!` dùng green khi vượt high score.
- Primary “TIẾP THEO”; secondary “CHỌN MÀN”. Màn 20 đổi CTA thành Hoàn thành hoặc
  Chơi lại.

### 6.10. Hướng dẫn

- Page/modal full-height, header có Close rõ.
- 4 card trực quan: kéo/thả; dội và đáy mở; target cần N dội; hệ số = 1 + số dội.
- Minh hoạ dùng component gameplay thật, không vẽ một bộ ký hiệu khác.
- “Không hiển thị nữa” chỉ tắt popup lần đầu; Help trong Settings luôn còn.

## 7. Motion, audio và haptic

| Sự kiện | Visual | Motion | Audio/Haptic |
|---|---|---|---|
| Bắt đầu ngắm | shooter glow + dotted guide | scale 1.03 | haptic nhẹ nếu requirements cho phép |
| Dội tường/vật cản | cyan spark + flash | ring 100–150ms | wall impact; haptic nhẹ |
| Tăng hệ số | badge vàng rõ hơn | punch 120–200ms | pitch tăng dần |
| Chưa đủ dội | mặt trêu + bubble | squash/bounce 200–300ms | blocked sound |
| Đủ điều kiện | outer glow + mặt hoảng | pulse một lần | chime rất ngắn |
| Phá target | burst + score pop | hit-stop 40–70ms | comic impact; haptic mạnh hơn |
| Rơi đáy | trail fade | fade khoảng 150ms | miss/down tone |
| Thắng | sao + burst | stagger 180–250ms | victory sting |
| Thua | dim + headline đỏ | modal pop | failure sting |

Reduced motion: tắt camera shake, giảm particle, thay pulse/scale bằng đổi opacity.
Audio và haptic có toggle riêng. Haptic “bắt đầu ngắm” trong file Word xung đột với
requirements Unit 2 hiện tại (“không rung khi đang kéo”); coi đây là đề xuất mở,
không triển khai cho đến khi requirements được sửa có chủ đích.

## 8. Responsive và accessibility

- Reference 390 × 844; phone portrait là form factor chính.
- Nội dung ngoài sân có `maxWidth` 440dp; tablet có thể tăng panel nhưng giữ tỷ lệ
  và hierarchy, không kéo nút hết chiều ngang màn lớn.
- Arena letterbox từ hệ logic; shooter/HUD nằm trong safe area.
- Body contrast ≥ 4.5:1; chữ lớn và control boundary ≥ 3:1.
- Target number không nhỏ hơn khoảng 18px ở khổ tham chiếu.
- `armed` dùng glow + outline + đổi biểu cảm, không chỉ đổi hue.
- Icon-only control có semantic label; control ≥ 48dp.
- Arena có semantics tổng quan và live announcement cho bank/mục tiêu phá nếu
  screen reader bật.
- Text widget tôn trọng system text scale; chữ vẽ canvas nhận text-scale riêng mà
  không làm đổi hình học mô phỏng.

## 9. Mapping sang sản phẩm

| Khu vực | Trách nhiệm UI đích |
|---|---|
| Menu | logo, Chơi, Chọn màn, Settings, xu/high score; feature phụ có điều kiện |
| Arena map | 20 level, 4 chapter, stars, current/locked/skipped state |
| Game | HUD, arena, shooter, aim, trail, multiplier, pause/help |
| Result | win/lose, score, stars, retry/next/map, hint/skip theo điều kiện |
| Settings/help | sound, music, haptics, language, replay tutorial |

## 10. Trạng thái triển khai và migration

### 10.1. Đã có, phải giữ [Observed]

- `lib/sim/` tách khỏi Flutter; `ArenaFit` dùng hệ logic 100 × 160.
- Target có `armed` state; preview hai đoạn; đáy mở; vệt ma; bi xuyên target.
- Local progress, stars, coins, unlock, VI/EN và audio đã có ở mức code.

### 10.2. Chưa khớp thiết kế đích [Observed]

- Token và màn ngoài sân vẫn theo hệ sáng/coral/teal cũ.
- Chọn màn hiện là danh sách/card hoặc các spec cũ mô tả đường mòn; target là grid
  dark arcade.
- Variant button đang gắn tên `primary` với coral thay vì vai trò gold.
- Popup/dialog chưa đồng nhất.
- Một số feature trong hình (shop/event/mission, end-shot card) chưa phải chức năng
  chắc chắn; không triển khai chỉ để giống mockup.

### 10.3. Trình tự migration đề xuất

1. Thêm token ngữ nghĩa mới và theme tối; giữ adapter cho API cũ trong một nhịp.
2. Chuẩn hoá button/panel/icon/dialog states.
3. Đổi Menu, Settings, Help và Level Select sang nền tối.
4. Đồng bộ ArenaInk: trail cyan, panel multiplier, feedback `armed`.
5. Dựng result/lose/end-shot states; sau cùng thêm polish motion và sound.
6. Chạy golden test ở 390 × 844, màn nhỏ, tablet và text scale lớn.

## 11. Checklist nghiệm thu

- [ ] Người mới phân biệt được target cần 1/2/3/4 dội.
- [ ] Khi bank count đạt threshold, target đổi state đủ mạnh **trước** va chạm.
- [ ] Vạch đỏ nét đứt đọc ra là đáy mở, không phải tường.
- [ ] Preview dừng ở hai đoạn, không lộ lời giải.
- [ ] Primary gold / secondary blue / tertiary purple nhất quán.
- [ ] Nút có default/pressed/disabled và hitbox đủ lớn.
- [ ] Level select phản ánh đúng 20 màn/4 chương và không dùng nhãn chapter sai từ hình.
- [ ] Màn thua nói đúng “hết lượt còn mục tiêu”; bi rơi chỉ kết thúc cú bắn.
- [ ] Màn thắng dùng đúng star thresholds/high score từ dữ liệu.
- [ ] Không có placeholder chức năng chết.
- [ ] Không có component/wording làm game quay lại ghép màu.
- [ ] Reduced motion, contrast, text scale và semantics đã được kiểm trên thiết bị.

---

**Cập nhật lần cuối**: 2026-08-09  
**Nguồn thiết kế**: `Cu_Doi_UI_UX_Design_Spec.docx`, hình tổng hợp 10 trạng thái
