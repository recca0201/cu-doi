# Solver — kiểm chứng cơ chế và cân bằng mà không cần Flutter

Bản port JavaScript của `lib/sim/*.dart`. Tồn tại vì prototype được viết trong môi
trường không có Dart/Flutter toolchain và không tải được SDK, nên đây là cách duy
nhất để kiểm chứng cơ chế và cân bằng màn chơi trước khi ai đó cài đặt gì.

Chỉ cần Node. Không cần Flutter.

```bash
node verify.js    # 74 assertion (khớp shot_runner_test.dart) + khả năng giải 3 màn
node tune.js      # dò 48 cấu hình tham số, đánh dấu cấu hình suy biến
node final.js     # BFS đầy đủ: số cú tối thiểu, trần điểm, đề xuất mốc sao
node shoot.js     # render ảnh chụp gameplay vào /tmp/shots (cần: npm i playwright)
```

## Quan trọng: đây là bản sao, không phải nguồn

`sim.js` là bản dịch tay từ Dart. **Nguồn sự thật là `lib/sim/*.dart`.** Nếu bạn
sửa vật lý hoặc hằng số trong Dart, phải sửa `sim.js` tương ứng, nếu không kết
quả solver sẽ nói về một game khác với game bạn đang chạy. Các hằng số cần khớp:

| Dart | JS |
|---|---|
| `arena.dart: kMaxBanks` | `sim.js: kMaxBanks` |
| `arena.dart: kMaxMultiplier` | `sim.js: kMaxMultiplier` |
| `shot_runner.dart: kMinAimUp` | `sim.js: clampAim` |
| `arenas.dart: kArenas` | `sim.js: kArenas` |

## Vì sao bộ này đáng giữ lại

Với tham số đầu tiên (`kMaxBanks = 14`, góc bắn tới ~78°), solver phát hiện cả 3
màn dọn sạch được bằng 1 cú duy nhất và ăn 3/3 sao — bắn gần nằm ngang cho bi
ping-pong quét sạch sân. Đó là lỗi thiết kế giết chết cả cơ chế, và playtest bằng
tay rất dễ bỏ sót vì người chơi bình thường không nghĩ tới việc bắn sát sàn.

Cơ chế dội tường có một chiến thuật suy biến tự nhiên: phun ngang, để vật lý làm
hộ. **Mỗi sân đấu mới và mỗi lần đổi tham số đều phải kiểm lại bằng `tune.js`.**

## Giới hạn

Solver kiểm được: mục tiêu có phá được không, màn có giải được không, giải cần bao
nhiêu cú, trần điểm là bao nhiêu, cấu hình có suy biến không.

Solver **không** kiểm được: Dart có biên dịch được không, game có vui không, và
liệu một con người có tìm ra được những cú mà máy vét cạn 721 góc tìm ra.
