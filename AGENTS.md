# Hướng dẫn cho AI agent làm việc trong repo này

Đọc `aidlc-docs/foundation/project-overview-pdr.md` trước khi sửa gì. Dưới đây là
bản rút gọn những thứ dễ phá nhất.

## Game này là gì, trong một câu

Bắn dội tường: **trúng trực tiếp không phá được gì**. Mỗi mục tiêu có một con số =
số lần bi phải dội tường trước khi nó có thể vỡ. Luật nằm trong
`lib/sim/shot_runner.dart` → `_resolveTargets()`. Đọc hàm đó trước.

## Bảy bất biến — đừng phá

1. **`lib/sim/` KHÔNG được import Flutter.** Đó là thứ cho phép test luật chơi
   không cần thiết bị và port sang JS để vét cạn.
2. **`kMaxBanks` (5), `kMinAimUp` (0.6), `kMaxMultiplier` (6)** là cân bằng toàn
   cục. Đổi một trong ba là 20 màn vô hiệu → phải chạy lại
   `cd tools/solver && node campaign.js`.
3. **`requiredBanks` chỉ dùng được 1..4.** Bằng `kMaxBanks` là không thể phá — bi
   chết ngay ở substep số dội đạt trần.
4. **Dội vào mục tiêu KHÔNG tính công dội.** Chỉ tường / khối chắn / vật cản chéo.
   Bỏ điều này là người chơi farm hệ số bằng cách nảy qua lại giữa hai mục tiêu.
5. **Phá mục tiêu thì bi xuyên qua, giữ nguyên vận tốc.** Đó là toàn bộ phần thưởng
   của cơ chế.
6. **Đáy sân không có tường.** Bi rơi ra là mất. Đừng thêm tường đáy.
7. **Mục tiêu phát sáng + đổi biểu cảm khi số dội hiện tại đã đủ phá nó**
   (`currentBanks >= requiredBanks` trong `arena_painter.dart`). Đây là cách luật
   tự dạy chính nó. Đừng bỏ khi refactor.

## `lib/sim/arenas.dart` là file được SINH RA

Đừng sửa tay. Hình học hand-authored trong `tools/solver/campaign.js`; còn
`requiredBanks`, `shots`, `starThresholds` do solver tính từ mô phỏng thật. Sửa
campaign.js rồi chạy lại; các con số tune bằng tay sẽ sai.

## Cơ chế này có một chiến thuật suy biến

Bắn gần nằm ngang cho bi ping-pong quét cả sân. Bản tham số đầu tiên cho phép dọn
sạch **mọi** màn bằng 1 cú và ăn 3/3 sao. Mỗi sân đấu mới, mỗi lần đổi tham số:
`node tune.js` để kiểm lại. Đừng tin trực giác ở điểm này.

## Lệnh

```bash
flutter create --platforms=android,ios .   # lần đầu: repo chưa có android/ ios/
flutter pub get && flutter gen-l10n
flutter test                               # luôn chạy trước khi kết luận là xong
flutter analyze

cd tools/solver
node campaign.js   # author + tune + kiểm suy biến
node verify.js     # assertion cơ chế + khả năng giải
node sheet.js      # render 20 màn ra ảnh (npm i playwright)
```

## Bối cảnh: đừng đề xuất quay lại ghép màu

Repo này tồn tại vì game tiền nhiệm (`../ban_bua`) bị App Store từ chối theo
Guideline 4.3(a) — trùng concept với game của developer khác. Mọi đề xuất kiểu
"thêm ghép màu cho dễ hiểu", "thêm trần lưới hạ dần", "thêm power-up như bubble
shooter" đều đi ngược lý do repo này ra đời. Nếu thấy một cơ chế nên vay từ thể
loại bắn bong bóng, hãy nói rõ vì sao nó không làm game quay về chỗ bị từ chối.

## Chưa có dòng nào được biên dịch

Toàn bộ code được viết trong môi trường không có Flutter toolchain. `flutter test`
lần đầu là kiểm tra thật. Lỗi biên dịch, nếu có, gần như chắc ở `lib/ui/` —
`lib/sim/` đã được kiểm chứng bằng solver.
