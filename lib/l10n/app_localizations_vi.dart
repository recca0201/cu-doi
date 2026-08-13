// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'game bắn dội tường';

  @override
  String get menuTagline => 'Bắn thẳng không tính. Dội tường mới ăn.';

  @override
  String get playCta => 'Chơi';

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
  String rewardedAdCta(int reward) {
    return 'Xem quảng cáo · +$reward xu';
  }

  @override
  String get rewardedAdLoading => 'Đang tải quảng cáo…';

  @override
  String rewardedAdEarned(int reward) {
    return 'Đã nhận $reward xu để dùng cho gợi ý.';
  }

  @override
  String get rewardedAdDismissed => 'Xem hết quảng cáo để nhận xu.';

  @override
  String get rewardedAdUnavailable => 'Chưa có quảng cáo. Hãy thử lại sau.';

  @override
  String get rewardedAdSaveFailed => 'Không lưu được xu thưởng. Hãy thử lại.';

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

  @override
  String get profileTitle => 'Hồ sơ người chơi';

  @override
  String get defaultPlayerName => 'Người chơi';

  @override
  String get changeAvatarCta => 'Đổi ảnh đại diện';

  @override
  String get editNameCta => 'Sửa tên';

  @override
  String get saveCta => 'Lưu';

  @override
  String get cancelCta => 'Hủy';

  @override
  String get invalidNameError => 'Tên phải có từ 1 đến 20 ký tự nhìn thấy.';

  @override
  String get guestStatus => 'Đang chơi với tư cách khách';

  @override
  String get profileStars => 'sao';

  @override
  String get profileCompleted => 'đã hoàn thành';

  @override
  String get profileEncouragement => 'Cú dội hay đầu tiên đang chờ bạn.';

  @override
  String profileChapter(int number) {
    return 'Chương $number';
  }

  @override
  String get accountTitle => 'Bảo vệ tiến trình';

  @override
  String get guestAccountBody =>
      'Bạn có thể đăng nhập để đồng bộ hồ sơ giữa các thiết bị.';

  @override
  String get signInGoogleCta => 'Tiếp tục với Google';

  @override
  String get signInAppleCta => 'Tiếp tục với Apple';

  @override
  String get signInProgress => 'Đang mở cửa sổ đăng nhập…';

  @override
  String get signInFailedMessage =>
      'Không đăng nhập được. Hãy kiểm tra tài khoản Google trên thiết bị rồi thử lại.';

  @override
  String get choosePlayerNameTitle => 'Tên trong game';

  @override
  String choosePlayerNameBody(String name) {
    return 'Bạn muốn dùng “$name” từ tài khoản Google hay đặt một tên khác?';
  }

  @override
  String get choosePlayerNameUseCta => 'Dùng tên Google';

  @override
  String get choosePlayerNameCustomCta => 'Đặt tên khác';

  @override
  String get providerConfigRequired =>
      'Đăng nhập sẽ khả dụng sau khi cấu hình provider phát hành.';

  @override
  String get avatarPresetsTitle => 'Chọn ảnh dựng sẵn';

  @override
  String get devicePhotoCta => 'Ảnh từ thiết bị';

  @override
  String get avatarPrivacyCopy =>
      'Bộ chọn hệ thống chỉ mở khi bạn chọn và đồng bộ avatar.';

  @override
  String get avatarInvalidError =>
      'Không dùng được ảnh này. Hãy chọn ảnh khác.';

  @override
  String get openProfileCta => 'Mở hồ sơ người chơi';

  @override
  String get badgesTitle => 'Huy hiệu';

  @override
  String get badgeUnlocked => 'Đã mở';

  @override
  String get badgeLocked => 'Đang tiến hành';

  @override
  String get signOutCta => 'Đăng xuất';

  @override
  String get deleteAccountCta => 'Xóa tài khoản';

  @override
  String get deleteAccountTitle => 'Xóa tài khoản này?';

  @override
  String get deleteAccountBody =>
      'Dữ liệu đám mây và quyền đăng nhập sẽ bị xóa. Một bản tiến trình khách vẫn được giữ trên thiết bị.';

  @override
  String get confirmDeleteCta => 'Xác nhận xóa';

  @override
  String get accountPending => 'Đang xử lý xóa tài khoản';

  @override
  String get accountRecovery => 'Cần xác nhận lại nhà cung cấp để tiếp tục xóa';

  @override
  String get accountDeleted => 'Đã xóa tài khoản';

  @override
  String get syncPending => 'Đang chờ đồng bộ';

  @override
  String get signedInStatus => 'Đã đăng nhập';

  @override
  String get signedInResetGuard =>
      'Hãy đăng xuất trước khi xóa tiến trình cục bộ để dữ liệu đám mây không khôi phục lại.';

  @override
  String get signInReminderBody =>
      'Bảo vệ tiến trình này và khôi phục trên thiết bị khác.';

  @override
  String get signInReminderCta => 'Mở tùy chọn đăng nhập';

  @override
  String get leaderboardEntryCta => 'Xếp hạng';

  @override
  String leaderboardEntrySemantic(int arenaId) {
    return 'Xem bảng xếp hạng Màn $arenaId';
  }

  @override
  String leaderboardWinEntrySemantic(int arenaId) {
    return 'Xem bảng xếp hạng của Màn $arenaId vừa hoàn thành';
  }

  @override
  String get leaderboardTitle => 'BẢNG XẾP HẠNG';

  @override
  String leaderboardLevel(int arenaId, String arenaName) {
    return 'Màn $arenaId · $arenaName';
  }

  @override
  String get leaderboardGlobal => 'Toàn cầu';

  @override
  String get leaderboardFriends => 'Bạn bè';

  @override
  String get leaderboardAllTime => 'Mọi thời đại';

  @override
  String get leaderboardYou => 'Bạn';

  @override
  String get leaderboardOutsideTop100 => 'Bạn đang ngoài top 100';

  @override
  String get leaderboardSelected => 'đã chọn';

  @override
  String get leaderboardNotSelected => 'chưa chọn';

  @override
  String leaderboardScopeAnnouncement(String scope) {
    return 'Đã chọn bảng $scope';
  }

  @override
  String leaderboardLoadedAnnouncement(String scope, int arenaId) {
    return 'Đã tải bảng $scope cho Màn $arenaId';
  }

  @override
  String get leaderboardTopThreeLabel => 'Ba người dẫn đầu';

  @override
  String leaderboardListFromRankLabel(int rank) {
    return 'Danh sách xếp hạng từ hạng $rank';
  }

  @override
  String leaderboardRowSemantics(int rank, String playerName, String score) {
    return 'Hạng $rank, $playerName, $score điểm';
  }

  @override
  String get leaderboardCurrentPlayerSuffix => 'người chơi hiện tại';

  @override
  String leaderboardLoadingAnnouncement(int arenaId) {
    return 'Đang tải bảng xếp hạng Màn $arenaId';
  }

  @override
  String get leaderboardLoadingTitle => 'Đang tải bảng xếp hạng…';

  @override
  String get leaderboardLoadingBadge => 'Đang tải';

  @override
  String leaderboardEmptyTitle(int arenaId) {
    return 'Chưa có điểm cho Màn $arenaId';
  }

  @override
  String leaderboardEmptyMessage(String scope) {
    return 'Hãy là người đầu tiên ghi tên vào bảng $scope.';
  }

  @override
  String get leaderboardServiceErrorTitle => 'Không tải được bảng xếp hạng';

  @override
  String get leaderboardServiceErrorMessage =>
      'Game Center/Google Play Games tạm thời không phản hồi.';

  @override
  String get leaderboardServiceErrorBadge => 'Lỗi dịch vụ';

  @override
  String get leaderboardRetryCta => 'Thử lại';

  @override
  String get leaderboardStaleTitle => 'Dữ liệu có thể đã cũ';

  @override
  String leaderboardStaleMessage(String scope, int arenaId) {
    return 'Đang hiển thị bản $scope của Màn $arenaId được lưu gần nhất.';
  }

  @override
  String get leaderboardOfflineBadge => 'Offline';

  @override
  String get leaderboardOfflineQueueMessage =>
      'Không có kết nối · Điểm đang chờ sẽ được giữ trên thiết bị';

  @override
  String get leaderboardOfflineEmptyTitle => 'Không có dữ liệu offline';

  @override
  String leaderboardOfflineEmptyMessage(int arenaId, String scope) {
    return 'Chưa có bản lưu phù hợp cho Màn $arenaId · $scope.';
  }

  @override
  String get leaderboardFriendsUnavailableTitle =>
      'Không thể hiển thị bảng Bạn bè';

  @override
  String get leaderboardFriendsUnavailableMessage =>
      'Danh sách bạn bè hiện không khả dụng do quyền riêng tư, hạn chế tài khoản hoặc cài đặt nền tảng.';

  @override
  String get leaderboardViewGlobalCta => 'Xem Toàn cầu';

  @override
  String get leaderboardAuthTitle => 'Kết nối bảng xếp hạng?';

  @override
  String get leaderboardAuthDescription =>
      'Kết nối Game Center hoặc Google Play Games để xem bảng và gửi kỷ lục. Bạn vẫn có thể chơi hoàn toàn offline.';

  @override
  String get leaderboardAuthConnectCta => 'Kết nối';

  @override
  String get leaderboardAuthLaterCta => 'Để sau';

  @override
  String get leaderboardAuthPromptMessage =>
      'Điểm, sao, xu và tiến trình cục bộ vẫn được giữ nguyên nếu bạn kết nối sau.';

  @override
  String get leaderboardSubmissionTitle => 'Trạng thái gửi điểm';

  @override
  String get leaderboardSubmissionSent => 'Đã gửi';

  @override
  String get leaderboardSubmissionSentMessage =>
      'Nền tảng đã xác nhận kỷ lục này.';

  @override
  String get leaderboardSubmissionPending => 'Đang chờ';

  @override
  String get leaderboardSubmissionPendingMessage =>
      'Sẽ tự gửi khi có mạng và đúng danh tính nền tảng.';

  @override
  String get leaderboardSubmissionFailed => 'Không gửi được';

  @override
  String get leaderboardSubmissionNotQueued => 'Chưa gửi';

  @override
  String get leaderboardSubmissionNotQueuedMessage =>
      'Kết quả này không phải kỷ lục mới đã lưu nên không được gửi.';

  @override
  String get leaderboardSubmissionPersistFailedMessage =>
      'Không thể lưu kết quả hoặc hàng đợi trên thiết bị, nên nền tảng chưa chấp nhận điểm này.';

  @override
  String get leaderboardSubmissionDisconnected => 'Chưa kết nối';

  @override
  String get leaderboardSubmissionDisconnectedMessage =>
      'Cần kết nối rõ ràng trước khi điểm này có thể được gửi.';

  @override
  String get leaderboardSubmitScoreCta => 'Gửi điểm';

  @override
  String get leaderboardReconnectCta => 'Kết nối lại';

  @override
  String get leaderboardRetrySubmissionCta => 'Gửi lại';

  @override
  String get leaderboardReasonUnsupported =>
      'Nền tảng này không hỗ trợ gửi điểm.';

  @override
  String get leaderboardReasonRestricted =>
      'Tài khoản nền tảng đang bị hạn chế gửi điểm.';

  @override
  String get leaderboardReasonRejected => 'Nền tảng không chấp nhận điểm này.';

  @override
  String get leaderboardReasonUnknown =>
      'Nền tảng chưa thể nhận điểm này. Kỷ lục cục bộ vẫn an toàn.';

  @override
  String leaderboardAchievedScore(String score) {
    return 'Điểm vừa đạt: $score';
  }
}
