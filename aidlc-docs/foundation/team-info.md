# Team Information

## Team Size
**Developers in the team**: 1

## Unit Sizing Guidance
- **Fewer developers (2-3)**: Fewer units, prioritize sequential execution
- **More developers (4-5)**: Can handle parallel execution across more units
- **Large teams (6+)**: Can manage many units simultaneously

## Ghi chú riêng của dự án này

Một người làm, và repo đang ở trạng thái **chưa từng được biên dịch** — toàn bộ code
được viết trong môi trường không có Dart/Flutter toolchain (xem `README.md`). Hệ quả
cho việc chia unit:

- Xếp **tuần tự**, không tính chuyện song song. Không có nhánh nào để chạy song song.
- Gộp mạnh: mỗi unit nên là một thứ demo được, không phải một tầng kỹ thuật.
- PDR §11 đặt `flutter test` chạy được và **playtest 20 màn** trước mọi việc thêm.
  Mọi unit ở đây nằm sau mốc đó.
