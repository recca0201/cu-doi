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
  String get floorDangerLabel => 'RƠI RA LÀ MẤT!';

  @override
  String get banksLabel => 'SỐ LẦN DỘI';

  @override
  String get pauseTitle => 'Tạm dừng';

  @override
  String get resumeCta => 'Chơi tiếp';

  @override
  String arenaNumberLabel(int id) {
    return 'MÀN $id';
  }

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
  String get arenaTargetsLabel => 'Mục tiêu';

  @override
  String get arenaBankRequirementsLabel => 'Yêu cầu dội';

  @override
  String get arenaShotsLabel => 'Lượt';

  @override
  String get arenaStarThresholdsLabel => 'Mốc sao';

  @override
  String get howToTitle => 'Luật chơi';

  @override
  String get howToAimTitle => 'Ngắm và bắn';

  @override
  String get howToAimBody => 'Kéo để ngắm, thả tay để bắn.';

  @override
  String get howToBounceTitle => 'Tích lần dội';

  @override
  String get howToBounceBody => 'Bi dội tường, khối chắn và vật cản chéo.';

  @override
  String get howToDirectTitle => 'Bắn thẳng không tính';

  @override
  String get howToDirectBody =>
      'Mục tiêu chỉ vỡ khi bi đã dội đủ số lần yêu cầu.';

  @override
  String get howToScoreTitle => 'Dội nhiều, điểm cao';

  @override
  String get howToScoreBody => 'Điểm nhận = 100 × (1 + số lần dội).';

  @override
  String get howToFloorTitle => 'Đáy sân mở';

  @override
  String get howToFloorBody =>
      'Đáy sân không có tường. Bi rơi xuống là mất lượt.';

  @override
  String get howToTargetNote =>
      'Số trên mục tiêu là số lần dội tối thiểu cần đạt.';

  @override
  String get dontShowAgainCta => 'Không hiện lại';

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
  String get hapticsLabel => 'Rung';

  @override
  String get languageLabel => 'Ngôn ngữ';

  @override
  String get resetProgressCta => 'Xoá tiến trình';

  @override
  String get resetProgressDone => 'Đã xoá tiến trình.';

  @override
  String get hintButtonLabel => 'Gợi ý đường dội';

  @override
  String hintCostBadge(int cost) {
    return '$cost xu';
  }

  @override
  String hintInsufficientCoins(int missing) {
    return 'Thiếu $missing xu';
  }

  @override
  String get hintUnavailable => 'Chưa tìm được đường gợi ý cho sân lúc này.';

  @override
  String get hintComputing => 'Đang tính đường dội…';

  @override
  String get hintFailed =>
      'Không thể tính hoặc lưu gợi ý. Xu của bạn vẫn còn nguyên.';

  @override
  String hintShownAnnouncement(int count) {
    return 'Đã hiện đường gợi ý phá được $count mục tiêu.';
  }

  @override
  String get skipArenaLabel => 'Bỏ qua màn';

  @override
  String skipArenaCostBadge(int cost) {
    return '$cost xu';
  }

  @override
  String skipArenaInsufficientCoins(int missing) {
    return 'Còn thiếu $missing xu để bỏ qua';
  }

  @override
  String get skipArenaConfirmTitle => 'Bỏ qua màn này?';

  @override
  String get skipArenaConfirmBody =>
      'Bạn sẽ dùng 150 xu để mở màn kế tiếp. Màn này vẫn có thể chơi lại để lấy sao.';

  @override
  String get skipArenaConfirmCta => 'Dùng xu và bỏ qua';

  @override
  String get skipArenaWriteFailed =>
      'Không lưu được tiến trình. Xu chưa bị trừ.';

  @override
  String get arenaSkippedBadge => 'Đã bỏ qua';

  @override
  String stuckReminderHint(int cost) {
    return 'Đang bí? Thử xem đường gợi ý với $cost xu.';
  }

  @override
  String stuckReminderHintAndSkip(int hintCost, int skipCost) {
    return 'Bạn có thể xem gợi ý ($hintCost xu) hoặc bỏ qua màn ($skipCost xu).';
  }

  @override
  String get stuckReminderRetryCta => 'Thử lại';

  @override
  String get characterName => 'Dội';

  @override
  String get chapter1Title => 'Chương 1 · Học luật dội';

  @override
  String get chapter2Title => 'Chương 2 · Kệ và hốc';

  @override
  String get chapter3Title => 'Chương 3 · Zig-zag';

  @override
  String get chapter4Title => 'Chương 4 · Vật cản chéo';

  @override
  String get chapterOtherTitle => 'Màn khác';

  @override
  String chapterProgressLabel(int earned, int max) {
    return '$earned/$max sao';
  }

  @override
  String get currentLevelBadge => 'Đang chơi';

  @override
  String get dialogueIntro =>
      'Tôi là Dội. Bắn thẳng chỉ làm chúng bật cười — hãy cho viên bi chạm tường đủ số lần rồi quay lại!';

  @override
  String get dialogueWin => 'Đường dội đẹp đấy! Cứ giữ nhịp này nhé.';

  @override
  String get dialogueLose =>
      'Chưa trúng đường thôi. Nhìn lại vệt bi, đổi một góc nhỏ rồi thử tiếp nhé.';

  @override
  String get dialogueLoseShort => 'Lệch một góc thôi — thử lại nhé!';

  @override
  String get dialogueFinalVictory =>
      'Hai mươi sân đã chịu thua. Giờ thì danh hiệu cao thủ dội tường là của bạn!';
}
