# Bắn Bừa — Cú Dội (`ban_bua_tuong`)

Game bắn dội tường. **Bắn trúng trực tiếp không phá được gì** — mỗi mục tiêu có
một con số là số lần bi phải dội tường trước đã. Bi không dừng khi va chạm, nó
dội tiếp, nên một cú có thể ăn nhiều mục tiêu. Càng dội càng nhân điểm, nhưng
đáy sân không có tường: bi rơi xuống là mất.

Đây là bản dựng lại sau khi `ban_bua` bị App Store từ chối theo Guideline
4.3(a). Lý do và các phương án đã cân nằm ở
`../ban_bua/aidlc-docs/brainstorming/0003-ricochet-core-loop-reconcept.md`.

## Chạy

```bash
flutter pub get
flutter gen-l10n                            # sinh lib/l10n/app_localizations.dart
flutter test
flutter run
```

### Platform scaffolding

`android/` và `ios/` đã được sinh và có native bridge cho Play Games/Game Center.
Không chạy lại `flutter create` nếu không chủ đích review phần native bị ghi đè.
Bundle ID đã là `com.tungbogin.cudoi`. Bản phát hành đầu chỉ còn cần cấu hình
signing; leaderboard được giữ sau feature flag cho một bản cập nhật sau.

### Trạng thái toolchain

Repo đã qua `flutter analyze`, widget/unit tests và Android debug build. Release
build cố ý fail-closed cho đến khi chủ tài khoản điền đúng ID/certificate thật.

## Cái gì lấy lại từ `ban_bua`, cái gì không

**Copy nguyên trạng — không sửa một dòng:**

| Đường dẫn | Vì sao dùng lại được |
|---|---|
| `lib/core/bb_tokens.dart`, `bb_theme.dart`, `bb_icons.dart` | design token + type; chỉ phụ thuộc Flutter |
| `lib/core/game_audio_service.dart` | quản lý pool 3 player, cooldown, scope. Đã có sẵn `wallImpact`, `blockedGap`, `comicImpact`, `politeClap` — đúng bộ âm cho game dội tường |
| `lib/data/settings_repository.dart`, `progress_repository.dart` | không dính gì tới bong bóng |
| `lib/domain/player_progress.dart` | hoàn toàn tổng quát: `levelId -> {stars, highScore}`. Arena id dùng lại đúng keyspace đó, không phải sửa gì |
| `lib/ui/widgets/bb_widgets.dart`, `bb_backdrop.dart`, `bb_transitions.dart` | BbButton/BbCard/BbBadge/BbToggle + sunburst/dot pattern |
| `assets/audio/`, `assets/fonts/`, `assets/icon/`, `assets/images/mascot/ban_bua_mascot_v2.png` | nguyên vẹn |
| `analysis_options.yaml`, `.gitignore`, `l10n.yaml` | nguyên vẹn |

**Cố tình KHÔNG mang sang:**

| Đường dẫn | Vì sao |
|---|---|
| `lib/game/bubble_game.dart` (88KB) | chính là engine ghép-3 bị từ chối |
| `lib/domain/bubble_grid.dart`, `bubble.dart`, `bubble_color.dart`, `bubble_face.dart`, `grid_math.dart` | lưới hex + flood fill ghép màu |
| `lib/domain/wild_resolution_planner.dart` | nút BẮN BỪA cũ chọn mục tiêu ngẫu nhiên, không có quyết định nào cho người chơi |
| `assets/levels/levels.json`, `lib/domain/level.dart` | 29/41 màn sinh từ dãy seed cấp số cộng; sân đấu dội tường phải thiết kế tay |
| `lib/game/comic_effect_controller.dart` (1070 dòng) | code trình diễn rất tốt nhưng gắn chặt vào khái niệm `popped`/`isCrit`/`isRage`/`isWild`. Cần **thiết kế lại quanh số lần dội**, không phải copy. Đây là việc đáng làm sớm |
| `lib/game/shot_trajectory.dart`, `aim_forecast.dart` | `lib/sim/shot_runner.dart` đã có hệ va chạm riêng, đơn giản hơn và đã có test. Hai hệ va chạm song song là nợ kỹ thuật |
| `lib/core/bb_chapter_theme.dart`, `ui/widgets/bb_game_widgets.dart` | import `domain/level.dart` và `bubble_painter.dart` |
| Firebase, AdMob | xem ghi chú trong `pubspec.yaml` |
| `app_store/` | toàn bộ ảnh marketing và listing mô tả game cũ |

## Hướng thiết kế: hybrid

Vỏ ngoài (menu, chọn màn, cài đặt) **giữ nguyên ngôn ngữ thương hiệu**: nền
cream/sky, sunburst, viền mực dày, bóng đổ cứng, chữ Baloo 2. Chỉ **sân đấu** đổi
sang nền đêm indigo.

Bốn màu mục tiêu, màu khung hổ phách, màu mực và màu cream trong `ArenaInk` là
**đúng các hue của `BbTokens`** — nhìn vẫn ra Bắn Bừa, nhưng bố cục và nền thì
không thể nhầm với game bắn bong bóng. Xem `lib/core/arena_ink.dart`, trong đó có
ghi lý do vì sao màu được lưu dạng int `0xRRGGBB` thay vì `Color`.

## Campaign: 20 màn, đã được solver kiểm chứng

`lib/sim/arenas.dart` là **file được sinh ra**. Hình học (vị trí mục tiêu, khối
chắn, vật cản chéo) là hand-authored trong `tools/solver/campaign.js`. Mọi **con
số** ảnh hưởng độ khó thì không: `requiredBanks`, `shots` và `starThresholds` đều
do chạy mô phỏng thật trên 721 góc bắn cho từng trạng thái bàn mà ra.

Pipeline đảm bảo cho **từng** màn:

- mọi mục tiêu đều phá được từ bàn đầy — không có mục tiêu bất khả thi;
- **không màn nào dọn sạch được bằng 1 cú**. Màn 2 và màn 7 ban đầu bị như vậy và
  đã được tự động nâng `requiredBanks` cho tới khi hết — đó chính là chiến thuật
  suy biến "phun ngang cho vật lý làm hộ" mà cả cơ chế này phải phòng;
- `shots` = một đường dọn sạch greedy thật cộng một cú dự phòng, nên ngân sách là
  khả thi chứ không phải đoán;
- mốc sao = 50% / 72% / 90% của điểm mà đúng đường đó thật sự ăn được.

| Màn | Tên | Mục tiêu | req | Cú bắn | Mốc sao |
|---|---|---|---|---|---|
| 1 | Bắn thẳng không tính | 3 | 1/1/1 | 3 | 750/1100/1350 |
| 2 | Ba đứa trên cao | 3 | 3/3/4 | 3 | 750/1100/1350 |
| 3 | Sát tường | 3 | 2/2/1 | 3 | 650/950/1150 |
| 4 | Hình thoi | 4 | 1/2/2/1 | 3 | 950/1350/1700 |
| 5 | Sau cây cột | 3 | 3/3/2 | 3 | 650/950/1150 |
| 6 | Ngóc ngách | 4 | 1/2/2/3 | 3 | 900/1300/1600 |
| 7 | Mái che | 3 | 2/2/2 | 3 | 750/1100/1350 |
| 8 | Bậc thang | 3 | 2/3/2 | 3 | 700/1000/1250 |
| 9 | Hai cái hốc | 4 | 2/2/2/1 | 3 | 900/1300/1600 |
| 10 | Kẹp giữa | 3 | 3/2/2 | 4 | 750/1100/1350 |
| 11 | Chuỗi dội | 4 | 1/2/3/4 | 3 | 800/1150/1450 |
| 12 | Leo thang | 5 | 1/2/3/4/1 | 3 | 1150/1650/2050 |
| 13 | Hành lang | 4 | 3/2/1/1 | 4 | 900/1300/1600 |
| 14 | Dán tường | 4 | 2/3/2/3 | 3 | 900/1300/1600 |
| 15 | Chữ thập | 4 | 2/2/2/2 | 3 | 900/1300/1600 |
| 16 | Chéo giữa sân | 3 | 2/2/1 | 3 | 750/1100/1350 |
| 17 | Cái phễu | 3 | 3/3/2 | 3 | 750/1100/1350 |
| 18 | Nóc nhà | 4 | 3/2/2/1 | 4 | 1000/1450/1800 |
| 19 | Hai lưỡi dao | 4 | 3/2/2/2 | 4 | 850/1200/1550 |
| 20 | Bừa hết cỡ | 6 | 4/3/3/2/2/1 | 4 | 1300/1850/2350 |

Chương: 1–5 học luật dội · 6–10 kệ và hốc · 11–15 zig-zag · 16–20 vật cản chéo.

Sửa gì cũng sửa trong `tools/solver/campaign.js` rồi chạy lại — **đừng sửa tay các
con số đã tune**, chúng sẽ sai:

```bash
cd tools/solver
node campaign.js   # author + tự tune + kiểm suy biến, ghi campaign.json
node verify.js     # 74 assertion cơ chế + kiểm khả năng giải
node tune.js       # dò tham số toàn cục
node sheet.js      # render cả 20 màn ra ảnh (cần: npm i playwright)
```

Cấu hình toàn cục: `kMaxBanks = 5`, `kMinAimUp = 0.6`, `kMaxMultiplier = 6`.
**Đổi bất kỳ giá trị nào trong ba giá trị đó là toàn bộ cân bằng vô hiệu** — bản
tham số đầu tiên cho phép dọn sạch mọi màn bằng 1 cú bắn gần nằm ngang. Chi tiết
trong `tools/solver/README.md`.

Lưu ý: `requiredBanks` không thể bằng `kMaxBanks`. Bi chết ngay ở substep mà số
lần dội đạt trần, nên req tối đa dùng được là **4**.

## Ảnh render toàn bộ campaign

`docs/levels/01..20.png` và `docs/campaign-contact-sheet.png` được render bằng
chính renderer của `arena_painter.dart` (port sang canvas), ở 390×844. Đây là
cách duy nhất hiện có để xem toàn bộ level mà không build được app.

## Release configuration

Đây là app record mới, khác biệt với Bắn Bừa trước đó. Bundle/application ID đã
chốt cho cả Android và iOS là `com.tungbogin.cudoi`.

Firebase production dùng project `cu-doi-game`. Privacy Policy song ngữ được
deploy từ `hosting/privacy.html` tới https://cudoi.web.app/privacy; URL gốc
https://cudoi.web.app chuyển hướng tới trang này.

Bản phát hành đầu tiên không bật bảng xếp hạng. UI và lifecycle đã được khóa bởi
`kLeaderboardsEnabled = false`; Play Games/Game Center capability không được
khai báo trong binary. Code và catalog được giữ lại để bật ở bản cập nhật sau.

Các input do chủ tài khoản/CI phải cung cấp, không được bịa trong source:

- Android release keystore/signing config. Firebase app registration và
  `android/app/google-services.json` đã được tạo cho package production.
- Khi bật leaderboard trong bản cập nhật: Play Games project ID và 20
  leaderboard ID trong `android/app/src/main/res/values/leaderboards.xml`.
- iOS development team/provisioning. Firebase app registration và
  `ios/Runner/GoogleService-Info.plist` đã được tạo cho bundle production.
- Khi bật leaderboard trong bản cập nhật: 20 Game Center leaderboard ID trong
  `ios/Runner/LeaderboardCatalog.plist` và bật lại Game Center capability.

Gradle/Xcode có guard để release dừng ngay nếu các placeholder này còn tồn tại.

## Còn cần xác nhận ngoài code

1. **Playtest.** Solver nói được "giải được", không nói được "vui". Câu hỏi số
   một vẫn là: khoảnh khắc cú bắn thẳng đầu tiên bị nảy ra gây tò mò hay gây khó
   hiểu?
2. Điền credential/ID production ở mục trên và chạy release build trên máy có
   keystore + Xcode signing hợp lệ.
3. Test audio focus/interruption thật trên Android và iOS (cuộc gọi, tai nghe,
   background/resume), ngoài các test lifecycle tự động trong repo.
