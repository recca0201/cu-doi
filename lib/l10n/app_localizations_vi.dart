// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Bắn Bừa';

  @override
  String get menuTagline => 'Bắn thẳng không tính. Dội tường mới ăn.';

  @override
  String get playCta => 'Chơi ngay';

  @override
  String get arenaSelectCta => 'Chọn màn';

  @override
  String get settingsCta => 'Cài đặt';

  @override
  String get howToCta => 'Luật chơi';

  @override
  String get bestScoreLabel => 'Điểm cao nhất';

  @override
  String get coinsLabel => 'Xu';

  @override
  String arenaHeading(int id, String name) {
    return 'Màn $id · $name';
  }

  @override
  String shotsLeft(int count) {
    return 'Còn $count cú bắn';
  }

  @override
  String get scoreLabel => 'điểm';

  @override
  String multiplier(int value) {
    return 'BỪA ×$value';
  }

  @override
  String get stampBank => 'DỘI!';

  @override
  String get stampBlocked => 'Bắn thẳng à?';

  @override
  String get resultWin => 'Dọn sạch!';

  @override
  String get resultLose => 'Hết cú bắn';

  @override
  String resultScore(int score) {
    return '$score điểm';
  }

  @override
  String get retryCta => 'Bắn lại';

  @override
  String get nextArenaCta => 'Màn sau';

  @override
  String get menuCta => 'Về menu';

  @override
  String get backCta => 'Quay lại';

  @override
  String get gotItCta => 'Hiểu rồi, bắn thôi!';

  @override
  String get arenaSelectTitle => 'Chọn màn';

  @override
  String get arenaLocked => 'Chưa mở';

  @override
  String arenaStars(int earned, int total) {
    return '$earned/$total sao';
  }

  @override
  String get arenaLockedHint => 'Xong màn trước đã rồi mới tới màn này nha!';

  @override
  String get howToTitle => 'Luật chơi';

  @override
  String get howToRule1 =>
      'Bắn trúng trực tiếp thì KHÔNG phá được gì. Con số trên mỗi mục tiêu là số lần bi phải dội tường trước đã.';

  @override
  String get howToRule2 =>
      'Bi không dừng khi va chạm — nó dội tiếp. Một cú có thể ăn nhiều mục tiêu.';

  @override
  String get howToRule3 =>
      'Càng dội càng nhân điểm. Nhưng đáy sân không có tường: bi rơi xuống là mất.';

  @override
  String get howToRule4 =>
      'Khi bi đang bay, mục tiêu nào sáng lên là mục tiêu đã phá được.';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get soundLabel => 'Âm thanh';

  @override
  String get musicLabel => 'Nhạc nền';

  @override
  String get languageLabel => 'Ngôn ngữ';

  @override
  String get resetProgressCta => 'Xoá tiến trình';

  @override
  String get resetProgressDone => 'Đã xoá tiến trình.';
}
