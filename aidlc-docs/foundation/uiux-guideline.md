---
artifact_type: foundation
document: uiux-guideline
project: ban_bua_tuong
status: approved-current
created: 2026-08-05
updated: 2026-08-11
source_artifacts:
  - Cu_Doi_UI_UX_Design_Spec.docx
  - project-overview-pdr.md
  - test/ui/goldens/arena_map_390x844.png
  - assets/images/backgrounds/vietnam_karst_canyon_v2.png
  - assets/images/ui/karst/
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

**Thiết kế đích**: Vietnamese karst adventure arcade · approved 2026-08-11

**Khổ tham chiếu**: mobile portrait 390 × 844

**Trạng thái**: đã chốt làm nguồn thiết kế cho các thay đổi UI tiếp theo

> Ngôn ngữ hiện hành là **karst adventure arcade**: backdrop núi đá vôi Việt Nam
> sáng và có sương, panel sơn mài xanh ngọc/teal, khung đồng-vàng chạm khắc,
> Baloo 2 + Nunito, viền comic và bóng sticker cứng. Vùng gameplay/HUD có thể tối
> để giữ tương phản; shell toàn app không dùng nền galaxy/indigo/navy làm mặc định.
>
> Quyết định này thay art direction trong UI/UX Design Spec 1.0 ngày 09/08/2026.
> File Word và asset `ui/galaxy/` chỉ còn là nguồn lịch sử hoặc tham khảo cấu trúc.

## 1. Thứ tự ưu tiên khi tài liệu xung đột

1. Luật chơi và bảy bất biến trong
   [`project-overview-pdr.md`](./project-overview-pdr.md) luôn thắng mọi mockup.
2. Golden đang pass, đặc biệt `test/ui/goldens/arena_map_390x844.png`, là bằng
   chứng trực quan cao nhất cho shell, mật độ, vật liệu và hierarchy đã triển khai.
3. Asset `assets/images/ui/karst/`, backdrop karst và code đang render quyết định
   vật liệu, palette và hình dạng component. Không suy art direction từ tên token
   legacy nếu output thực tế khác.
4. Tài liệu này chuẩn hoá các nguồn đang chạy thành quy tắc cho màn mới. Mockup
   feature đã được người dùng duyệt đứng sau foundation và phải ghi rõ nguồn ảnh.
5. File Word `Cu_Doi_UI_UX_Design_Spec.docx`, asset `ui/galaxy/` và spec/task cũ
   mô tả shell indigo/navy chỉ là lịch sử. Có thể dùng chúng để hiểu flow, không
   dùng làm visual target.

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
3. **Karst adventure arcade, không trở lại bubble shooter.** Không dùng lưới bong bóng, ghép
   màu, trần hạ dần hoặc power-up theo khuôn bubble shooter. Bốn màu mục tiêu là
   phân nhóm thị giác, không phải luật ghép màu.
4. **Kỹ năng vẫn thuộc về người chơi.** Preview chỉ có hai đoạn đầu; không hiển
   thị toàn bộ đáp án carom.
5. **Phản hồi mạnh nhưng không che sân.** Glow, spark, score pop và comic burst
   phải ngắn, có z-order rõ, không che mục tiêu còn sống hay đường bay tiếp theo.
6. **Một ngón tay, dọc màn hình.** Điều khiển chính nằm trong tầm ngón cái; chrome
   ở top safe area; mọi hit target tối thiểu 44 × 44 pt, mục tiêu triển khai 48dp.

## 3. Design system đích

### 3.1. Bảng màu ngữ nghĩa [Approved]

| Token / màu chuẩn | Giá trị | Vai trò |
|---|---:|---|
| `karstDeep` | `#042D31` | Scrim sâu, nền gameplay và lớp đáy của panel |
| `karstTeal` | `#07504A` | Surface chính, panel sơn mài và chrome ngoài sân |
| `karstBronze` | `#D99A38` | Khung chạm khắc, divider và ornament |
| `primaryGold` | `#FFC21C` | CTA chính, sao, selected/current và điểm nổi bật |
| `cream` | `#FFF3D7` | Chữ chính trên surface xanh và inner highlight |
| `secondaryBlue` | `#1976D2` | CTA phụ khi component hiện hành dùng blue |
| `trajectoryCyan` | `#54D9FF` | Bi, trail, điểm va chạm; không dùng làm màu shell |
| `successGreen` | `#7ED321` | Đủ điều kiện, kỷ lục mới, xác nhận tích cực |
| `dangerRed` | `#F04444` | Đáy mở, thất bại và lỗi cần chú ý |
| `outlineDark` | `#3D210E` theo vật liệu karst | Bóng sticker cứng và viền sâu trên asset/component karst |
| `nightIndigo` / `panelNavy` | legacy/scoped | Chỉ cho arena/HUD tối hoặc màn cũ có lý do tương phản; không dùng làm shell mặc định |

**Quy tắc**:

- Ưu tiên token. Một số asset/painter karst hiện vẫn dùng màu vật liệu trực tiếp;
  khi chạm vào chúng, gom về token thay vì nhân thêm hex mới.
- `primaryGold` là CTA chính xuyên suốt: **Chơi, Tiếp theo, Thử lại**.
- CTA phụ dùng component hiện hành (blue hoặc teal) nhưng phải giữ hierarchy thấp
  hơn gold và cùng khung/bóng karst.
- Purple/galaxy không thay cho surface hay CTA chính của shell karst.
- Trạng thái không bao giờ chỉ dựa vào màu; luôn có thêm hình dạng, outline,
  biểu cảm, icon hoặc chữ.

### 3.2. Trạng thái code và quy tắc tiếp tục

| Đang dùng | Quy tắc cho thay đổi mới |
|---|---|
| `BbCanyonBackdrop` + `vietnam_karst_canyon_v2.png` | Dùng cho shell adventure; giữ scrim vừa đủ để chữ/panel đọc được |
| Asset `assets/images/ui/karst/` | Nguồn chuẩn cho khung, nút Back, title, level card và detail panel |
| `karstDeep` / `karstTeal` / `karstBronze` | Surface và vật liệu chính ngoài sân đấu |
| `primaryGold` | CTA chính, selected/current và điểm nhấn |
| `nightIndigo` / `panelNavy` | Không mở rộng ra toàn app; chỉ giữ nơi gameplay/HUD tối cần tương phản |
| Asset `assets/images/ui/galaxy/` | Legacy hoặc feature-specific; không dùng để suy shell mới |
| `bbCoral`, card trắng, nền sky/cream phẳng | Legacy; không tạo màn mới theo hệ này |

Tên API cũ có thể tồn tại vì compatibility. Visual review và test mới phải gọi
theo **vai trò ngữ nghĩa** và đối chiếu golden, không suy màu chỉ từ tên API.

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
- Viền ngoài 2–3dp nâu/teal sâu; khung trang trí dùng bronze/gold; inner highlight
  1dp cream ở 20–30% opacity.
- Bóng cứng 0/4dp, blur thấp hoặc bằng 0; không dùng elevation Material mặc định.
- Glow chỉ dành cho quỹ đạo, mục tiêu `armed`, sao và khoảnh khắc thắng. CTA/shell
  karst ưu tiên highlight vật liệu và bóng sticker hơn neon glow.

## 4. Component library

### 4.1. Button hierarchy

| Loại | Màu | Cao | Ứng dụng | Trạng thái |
|---|---|---:|---|---|
| Primary | gold gradient | 58–64 | Chơi, Tiếp theo, Thử lại | default/pressed/disabled |
| Secondary | teal hoặc blue hiện hành, khung bronze/dark | 52–58 | Chọn màn, Về menu | default/pressed/disabled |
| Tertiary | teal/dark ghost | 48–54 | Hành động cấp ba có thật | default/pressed/disabled |
| Icon | jade/teal, khung gold/bronze | 44–48 | Back, pause, settings, close | default/pressed/disabled |
| Bottom utility | panel sơn mài karst | 56–64 | Tiện ích đã triển khai | selected/unselected |

Nút có outer stroke tối, inner highlight sáng và shadow cứng. Khi nhấn: dịch xuống
2dp, shadow ngắn lại, brightness giảm 8–12%. Disabled: saturation giảm khoảng 70%,
opacity 55%, không glow. Icon hành động đặt trái; chevron tiến tới đặt phải.

### 4.2. Panel, dialog và HUD

- Panel ngoài sân dùng `karstTeal`/`karstDeep`, viền `karstBronze` hoặc asset
  `ui/karst/`, inner highlight cream mảnh và bóng sticker nâu cứng.
- Dialog dùng scrim đen 70–80%; primary action ở trên secondary action.
- Top HUD tối giản: pause trái, tên màn giữa, lượt còn lại phải.
- Không dùng card trắng lớn hoặc panel neon navy/purple như một hệ độc lập.
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
- Mỗi màn là card preview karst bo tròn như golden hiện hành, có số màn và 0–3
  sao; current dùng gold outline + nền sáng hơn; locked dùng teal sâu/gray + lock.
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

### 10.2. Chưa khớp hoàn toàn [Observed]

- Token semantic và một số widget còn giữ tên/màu legacy dù màn chính đã render
  theo karst; khi sửa phải gom dần về vai trò karst, không đổi output về galaxy.
- Một số popup/dialog hoặc màn phụ chưa dùng cùng khung jade/bronze.
- Asset `ui/galaxy/` còn tồn tại cho compatibility và preset cụ thể; sự tồn tại
  của chúng không làm galaxy trở lại art direction toàn app.
- Một số feature trong hình cũ (shop/event/mission, end-shot card) chưa phải chức
  năng chắc chắn; không triển khai chỉ để giống mockup.

### 10.3. Trình tự migration đề xuất

1. Bổ sung/chuẩn hoá token `karstDeep`, `karstTeal`, `karstBronze` và shadow nâu;
   giữ adapter cho API legacy trong một nhịp.
2. Chuẩn hoá button/panel/icon/dialog theo asset `ui/karst/` và component đang chạy.
3. Đưa các màn phụ còn lệch về cùng backdrop/khung karst; không đổi Menu, Settings,
   Help hay Level Select sang nền galaxy/navy.
4. Giữ ArenaInk tối, trail cyan, multiplier và feedback `armed` vì đây là vùng
   gameplay cần tương phản, không phải art direction của shell.
5. Dựng result/lose/end-shot states; sau cùng thêm polish motion và sound.
6. Chạy golden test ở 390 × 844, màn nhỏ, tablet và text scale lớn. Mọi thay đổi
   shell phải đối chiếu `arena_map_390x844.png` hoặc golden mới đã được duyệt.

## 11. Checklist nghiệm thu

- [ ] Người mới phân biệt được target cần 1/2/3/4 dội.
- [ ] Khi bank count đạt threshold, target đổi state đủ mạnh **trước** va chạm.
- [ ] Vạch đỏ nét đứt đọc ra là đáy mở, không phải tường.
- [ ] Preview dừng ở hai đoạn, không lộ lời giải.
- [ ] Shell dùng backdrop karst + panel jade/teal + khung bronze/gold; không trôi
  về galaxy/indigo/navy.
- [ ] Primary gold và CTA phụ teal/blue giữ hierarchy nhất quán.
- [ ] Nút có default/pressed/disabled và hitbox đủ lớn.
- [ ] Level select phản ánh đúng 20 màn/4 chương và không dùng nhãn chapter sai từ hình.
- [ ] Màn thua nói đúng “hết lượt còn mục tiêu”; bi rơi chỉ kết thúc cú bắn.
- [ ] Màn thắng dùng đúng star thresholds/high score từ dữ liệu.
- [ ] Không có placeholder chức năng chết.
- [ ] Không có component/wording làm game quay lại ghép màu.
- [ ] Reduced motion, contrast, text scale và semantics đã được kiểm trên thiết bị.

---

**Cập nhật lần cuối**: 2026-08-11

**Nguồn thiết kế đã duyệt**: `test/ui/goldens/arena_map_390x844.png`,
`assets/images/backgrounds/vietnam_karst_canyon_v2.png`, `assets/images/ui/karst/`

**Nguồn lịch sử, không còn quyết art direction**: `Cu_Doi_UI_UX_Design_Spec.docx`,
hình tổng hợp 10 trạng thái và `assets/images/ui/galaxy/`.
