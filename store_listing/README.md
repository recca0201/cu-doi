# Cú Dội — store listing assets

Chạy lại toàn bộ bộ ảnh và video:

```powershell
flutter test --update-goldens test/store_listing_capture_test.dart
flutter test --update-goldens test/store_listing_video_capture_test.dart
python tools/build_store_listing.py
python tools/build_store_video.py
```

## Thư mục xuất bản

- `final/google_play/feature_graphic_1024x500.png`: feature graphic.
- `final/google_play/listing_icon_512x512.png`: icon listing.
- `final/google_play/phone_1080x1920/`: 7 ảnh marketing dọc.
- `final/google_play/tablet_7in_1080x1920/`: 7 ảnh marketing từ capture tablet 7 inch thật.
- `final/google_play/tablet_1440x2560/`: 7 ảnh marketing từ capture tablet 10 inch thật.
- `final/app_store/iphone_6_9_1320x2868/`: 7 ảnh marketing iPhone.
- `final/app_store/ipad_13_2064x2752/`: 7 ảnh marketing iPad 13 inch.
- `final/video/cu_doi_level_clear_vertical_1080x1920.mp4`: clip gameplay dọc 13,7 giây, H.264/AAC.
- `final/video/cu_doi_level_clear_poster_1080x1920.png`: poster của video.

Mỗi bộ 7 ảnh xen kẽ đúng thứ tự 4 ảnh tiếng Việt và 3 ảnh tiếng Anh. UI bên
trong ảnh cũng được render đúng locale tương ứng. Capture tablet/iPad được Flutter
render trực tiếp ở viewport tương ứng, không kéo giãn từ ảnh phone.

## Title được tạo bằng ImageGen

Bảy title raster nằm trong `source/titles/`:

1. DỘI TƯỜNG MỚI ĂN
2. AIM · BANK · BREAK
3. 20 MÀN · 4 CHƯƠNG
4. BANK SHOTS WIN
5. CANH GÓC · TÍNH DỘI
6. 20 LEVELS · 4 CHAPTERS
7. PHÁ TAN · GIỮ NGUYÊN ĐÀ

Các title dùng chữ 3D vàng, viền sơn mài xanh ngọc, cạnh đồng chạm khắc và điểm
nhấn quỹ đạo dội màu cyan. File chroma gốc nằm trong `source/titles_chroma/`;
bản đã tách nền trong suốt nằm trong `source/titles/`.

## Nguồn key art AI

Key art được tạo bằng built-in ImageGen từ ba tham chiếu của repo: backdrop karst,
mascot tê tê và gameplay golden. Prompt đầy đủ nằm ở
`source/key_art_prompt.txt`; file được chọn là
`source/karst_pangolin_key_art.png`.

Video dùng gameplay thật của màn 1: hai cú bắn theo nghiệm mô phỏng, kết thúc ở
bảng thắng “DỌN SẠCH!”, 1.400 điểm. Âm thanh lấy từ asset game hiện có.
