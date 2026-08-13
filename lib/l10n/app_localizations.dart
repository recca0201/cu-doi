import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'game bắn dội tường'**
  String get appTitle;

  /// No description provided for @menuTagline.
  ///
  /// In vi, this message translates to:
  /// **'Bắn thẳng không tính. Dội tường mới ăn.'**
  String get menuTagline;

  /// No description provided for @playCta.
  ///
  /// In vi, this message translates to:
  /// **'Chơi'**
  String get playCta;

  /// No description provided for @arenaSelectCta.
  ///
  /// In vi, this message translates to:
  /// **'Chọn màn'**
  String get arenaSelectCta;

  /// No description provided for @settingsCta.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsCta;

  /// No description provided for @howToCta.
  ///
  /// In vi, this message translates to:
  /// **'Luật chơi'**
  String get howToCta;

  /// No description provided for @bestScoreLabel.
  ///
  /// In vi, this message translates to:
  /// **'Điểm cao nhất'**
  String get bestScoreLabel;

  /// No description provided for @coinsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Xu'**
  String get coinsLabel;

  /// No description provided for @floorDangerLabel.
  ///
  /// In vi, this message translates to:
  /// **'RƠI RA LÀ MẤT!'**
  String get floorDangerLabel;

  /// No description provided for @banksLabel.
  ///
  /// In vi, this message translates to:
  /// **'SỐ LẦN DỘI'**
  String get banksLabel;

  /// No description provided for @pauseTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng'**
  String get pauseTitle;

  /// No description provided for @resumeCta.
  ///
  /// In vi, this message translates to:
  /// **'Chơi tiếp'**
  String get resumeCta;

  /// No description provided for @arenaNumberLabel.
  ///
  /// In vi, this message translates to:
  /// **'MÀN {id}'**
  String arenaNumberLabel(int id);

  /// No description provided for @arenaHeading.
  ///
  /// In vi, this message translates to:
  /// **'Màn {id} · {name}'**
  String arenaHeading(int id, String name);

  /// No description provided for @shotsLeft.
  ///
  /// In vi, this message translates to:
  /// **'Còn {count} cú bắn'**
  String shotsLeft(int count);

  /// No description provided for @scoreLabel.
  ///
  /// In vi, this message translates to:
  /// **'điểm'**
  String get scoreLabel;

  /// No description provided for @multiplier.
  ///
  /// In vi, this message translates to:
  /// **'BỪA ×{value}'**
  String multiplier(int value);

  /// No description provided for @stampBank.
  ///
  /// In vi, this message translates to:
  /// **'DỘI!'**
  String get stampBank;

  /// No description provided for @stampBlocked.
  ///
  /// In vi, this message translates to:
  /// **'Bắn thẳng à?'**
  String get stampBlocked;

  /// No description provided for @resultWin.
  ///
  /// In vi, this message translates to:
  /// **'Dọn sạch!'**
  String get resultWin;

  /// No description provided for @resultLose.
  ///
  /// In vi, this message translates to:
  /// **'Hết cú bắn'**
  String get resultLose;

  /// No description provided for @resultScore.
  ///
  /// In vi, this message translates to:
  /// **'{score} điểm'**
  String resultScore(int score);

  /// No description provided for @retryCta.
  ///
  /// In vi, this message translates to:
  /// **'Bắn lại'**
  String get retryCta;

  /// No description provided for @nextArenaCta.
  ///
  /// In vi, this message translates to:
  /// **'Màn sau'**
  String get nextArenaCta;

  /// No description provided for @menuCta.
  ///
  /// In vi, this message translates to:
  /// **'Về menu'**
  String get menuCta;

  /// No description provided for @backCta.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get backCta;

  /// No description provided for @gotItCta.
  ///
  /// In vi, this message translates to:
  /// **'Hiểu rồi, bắn thôi!'**
  String get gotItCta;

  /// No description provided for @arenaSelectTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn màn'**
  String get arenaSelectTitle;

  /// No description provided for @arenaLocked.
  ///
  /// In vi, this message translates to:
  /// **'Chưa mở'**
  String get arenaLocked;

  /// No description provided for @arenaStars.
  ///
  /// In vi, this message translates to:
  /// **'{earned}/{total} sao'**
  String arenaStars(int earned, int total);

  /// No description provided for @arenaLockedHint.
  ///
  /// In vi, this message translates to:
  /// **'Xong màn trước đã rồi mới tới màn này nha!'**
  String get arenaLockedHint;

  /// No description provided for @arenaTargetsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu'**
  String get arenaTargetsLabel;

  /// No description provided for @arenaBankRequirementsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu dội'**
  String get arenaBankRequirementsLabel;

  /// No description provided for @arenaShotsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Lượt'**
  String get arenaShotsLabel;

  /// No description provided for @arenaStarThresholdsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mốc sao'**
  String get arenaStarThresholdsLabel;

  /// No description provided for @howToTitle.
  ///
  /// In vi, this message translates to:
  /// **'Luật chơi'**
  String get howToTitle;

  /// No description provided for @howToAimTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ngắm và bắn'**
  String get howToAimTitle;

  /// No description provided for @howToAimBody.
  ///
  /// In vi, this message translates to:
  /// **'Kéo để ngắm, thả tay để bắn.'**
  String get howToAimBody;

  /// No description provided for @howToBounceTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tích lần dội'**
  String get howToBounceTitle;

  /// No description provided for @howToBounceBody.
  ///
  /// In vi, this message translates to:
  /// **'Bi dội tường, khối chắn và vật cản chéo.'**
  String get howToBounceBody;

  /// No description provided for @howToDirectTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bắn thẳng không tính'**
  String get howToDirectTitle;

  /// No description provided for @howToDirectBody.
  ///
  /// In vi, this message translates to:
  /// **'Mục tiêu chỉ vỡ khi bi đã dội đủ số lần yêu cầu.'**
  String get howToDirectBody;

  /// No description provided for @howToScoreTitle.
  ///
  /// In vi, this message translates to:
  /// **'Dội nhiều, điểm cao'**
  String get howToScoreTitle;

  /// No description provided for @howToScoreBody.
  ///
  /// In vi, this message translates to:
  /// **'Điểm nhận = 100 × (1 + số lần dội).'**
  String get howToScoreBody;

  /// No description provided for @howToFloorTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đáy sân mở'**
  String get howToFloorTitle;

  /// No description provided for @howToFloorBody.
  ///
  /// In vi, this message translates to:
  /// **'Đáy sân không có tường. Bi rơi xuống là mất lượt.'**
  String get howToFloorBody;

  /// No description provided for @howToTargetNote.
  ///
  /// In vi, this message translates to:
  /// **'Số trên mục tiêu là số lần dội tối thiểu cần đạt.'**
  String get howToTargetNote;

  /// No description provided for @dontShowAgainCta.
  ///
  /// In vi, this message translates to:
  /// **'Không hiện lại'**
  String get dontShowAgainCta;

  /// No description provided for @howToRule1.
  ///
  /// In vi, this message translates to:
  /// **'Bắn trúng trực tiếp thì KHÔNG phá được gì. Con số trên mỗi mục tiêu là số lần bi phải dội tường trước đã.'**
  String get howToRule1;

  /// No description provided for @howToRule2.
  ///
  /// In vi, this message translates to:
  /// **'Bi không dừng khi va chạm — nó dội tiếp. Một cú có thể ăn nhiều mục tiêu.'**
  String get howToRule2;

  /// No description provided for @howToRule3.
  ///
  /// In vi, this message translates to:
  /// **'Càng dội càng nhân điểm. Nhưng đáy sân không có tường: bi rơi xuống là mất.'**
  String get howToRule3;

  /// No description provided for @howToRule4.
  ///
  /// In vi, this message translates to:
  /// **'Khi bi đang bay, mục tiêu nào sáng lên là mục tiêu đã phá được.'**
  String get howToRule4;

  /// No description provided for @settingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsTitle;

  /// No description provided for @soundLabel.
  ///
  /// In vi, this message translates to:
  /// **'Âm thanh'**
  String get soundLabel;

  /// No description provided for @musicLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nhạc nền'**
  String get musicLabel;

  /// No description provided for @hapticsLabel.
  ///
  /// In vi, this message translates to:
  /// **'Rung'**
  String get hapticsLabel;

  /// No description provided for @languageLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get languageLabel;

  /// No description provided for @resetProgressCta.
  ///
  /// In vi, this message translates to:
  /// **'Xoá tiến trình'**
  String get resetProgressCta;

  /// No description provided for @resetProgressDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá tiến trình.'**
  String get resetProgressDone;

  /// No description provided for @hintButtonLabel.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý đường dội'**
  String get hintButtonLabel;

  /// No description provided for @hintCostBadge.
  ///
  /// In vi, this message translates to:
  /// **'{cost} xu'**
  String hintCostBadge(int cost);

  /// No description provided for @hintInsufficientCoins.
  ///
  /// In vi, this message translates to:
  /// **'Thiếu {missing} xu'**
  String hintInsufficientCoins(int missing);

  /// No description provided for @hintUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tìm được đường gợi ý cho sân lúc này.'**
  String get hintUnavailable;

  /// No description provided for @hintComputing.
  ///
  /// In vi, this message translates to:
  /// **'Đang tính đường dội…'**
  String get hintComputing;

  /// No description provided for @hintFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tính hoặc lưu gợi ý. Xu của bạn vẫn còn nguyên.'**
  String get hintFailed;

  /// No description provided for @hintShownAnnouncement.
  ///
  /// In vi, this message translates to:
  /// **'Đã hiện đường gợi ý phá được {count} mục tiêu.'**
  String hintShownAnnouncement(int count);

  /// No description provided for @rewardedAdCta.
  ///
  /// In vi, this message translates to:
  /// **'Xem quảng cáo · +{reward} xu'**
  String rewardedAdCta(int reward);

  /// No description provided for @rewardedAdLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải quảng cáo…'**
  String get rewardedAdLoading;

  /// No description provided for @rewardedAdEarned.
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận {reward} xu để dùng cho gợi ý.'**
  String rewardedAdEarned(int reward);

  /// No description provided for @rewardedAdDismissed.
  ///
  /// In vi, this message translates to:
  /// **'Xem hết quảng cáo để nhận xu.'**
  String get rewardedAdDismissed;

  /// No description provided for @rewardedAdUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có quảng cáo. Hãy thử lại sau.'**
  String get rewardedAdUnavailable;

  /// No description provided for @rewardedAdSaveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không lưu được xu thưởng. Hãy thử lại.'**
  String get rewardedAdSaveFailed;

  /// No description provided for @skipArenaLabel.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua màn'**
  String get skipArenaLabel;

  /// No description provided for @skipArenaCostBadge.
  ///
  /// In vi, this message translates to:
  /// **'{cost} xu'**
  String skipArenaCostBadge(int cost);

  /// No description provided for @skipArenaInsufficientCoins.
  ///
  /// In vi, this message translates to:
  /// **'Còn thiếu {missing} xu để bỏ qua'**
  String skipArenaInsufficientCoins(int missing);

  /// No description provided for @skipArenaConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua màn này?'**
  String get skipArenaConfirmTitle;

  /// No description provided for @skipArenaConfirmBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ dùng 150 xu để mở màn kế tiếp. Màn này vẫn có thể chơi lại để lấy sao.'**
  String get skipArenaConfirmBody;

  /// No description provided for @skipArenaConfirmCta.
  ///
  /// In vi, this message translates to:
  /// **'Dùng xu và bỏ qua'**
  String get skipArenaConfirmCta;

  /// No description provided for @skipArenaWriteFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không lưu được tiến trình. Xu chưa bị trừ.'**
  String get skipArenaWriteFailed;

  /// No description provided for @arenaSkippedBadge.
  ///
  /// In vi, this message translates to:
  /// **'Đã bỏ qua'**
  String get arenaSkippedBadge;

  /// No description provided for @stuckReminderHint.
  ///
  /// In vi, this message translates to:
  /// **'Đang bí? Thử xem đường gợi ý với {cost} xu.'**
  String stuckReminderHint(int cost);

  /// No description provided for @stuckReminderHintAndSkip.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể xem gợi ý ({hintCost} xu) hoặc bỏ qua màn ({skipCost} xu).'**
  String stuckReminderHintAndSkip(int hintCost, int skipCost);

  /// No description provided for @stuckReminderRetryCta.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get stuckReminderRetryCta;

  /// No description provided for @characterName.
  ///
  /// In vi, this message translates to:
  /// **'Dội'**
  String get characterName;

  /// No description provided for @chapter1Title.
  ///
  /// In vi, this message translates to:
  /// **'Chương 1 · Học luật dội'**
  String get chapter1Title;

  /// No description provided for @chapter2Title.
  ///
  /// In vi, this message translates to:
  /// **'Chương 2 · Kệ và hốc'**
  String get chapter2Title;

  /// No description provided for @chapter3Title.
  ///
  /// In vi, this message translates to:
  /// **'Chương 3 · Zig-zag'**
  String get chapter3Title;

  /// No description provided for @chapter4Title.
  ///
  /// In vi, this message translates to:
  /// **'Chương 4 · Vật cản chéo'**
  String get chapter4Title;

  /// No description provided for @chapterOtherTitle.
  ///
  /// In vi, this message translates to:
  /// **'Màn khác'**
  String get chapterOtherTitle;

  /// No description provided for @chapterProgressLabel.
  ///
  /// In vi, this message translates to:
  /// **'{earned}/{max} sao'**
  String chapterProgressLabel(int earned, int max);

  /// No description provided for @currentLevelBadge.
  ///
  /// In vi, this message translates to:
  /// **'Đang chơi'**
  String get currentLevelBadge;

  /// No description provided for @dialogueIntro.
  ///
  /// In vi, this message translates to:
  /// **'Tôi là Dội. Bắn thẳng chỉ làm chúng bật cười — hãy cho viên bi chạm tường đủ số lần rồi quay lại!'**
  String get dialogueIntro;

  /// No description provided for @dialogueWin.
  ///
  /// In vi, this message translates to:
  /// **'Đường dội đẹp đấy! Cứ giữ nhịp này nhé.'**
  String get dialogueWin;

  /// No description provided for @dialogueLose.
  ///
  /// In vi, this message translates to:
  /// **'Chưa trúng đường thôi. Nhìn lại vệt bi, đổi một góc nhỏ rồi thử tiếp nhé.'**
  String get dialogueLose;

  /// No description provided for @dialogueLoseShort.
  ///
  /// In vi, this message translates to:
  /// **'Lệch một góc thôi — thử lại nhé!'**
  String get dialogueLoseShort;

  /// No description provided for @dialogueFinalVictory.
  ///
  /// In vi, this message translates to:
  /// **'Hai mươi sân đã chịu thua. Giờ thì danh hiệu cao thủ dội tường là của bạn!'**
  String get dialogueFinalVictory;

  /// No description provided for @profileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ người chơi'**
  String get profileTitle;

  /// No description provided for @defaultPlayerName.
  ///
  /// In vi, this message translates to:
  /// **'Người chơi'**
  String get defaultPlayerName;

  /// No description provided for @changeAvatarCta.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ảnh đại diện'**
  String get changeAvatarCta;

  /// No description provided for @editNameCta.
  ///
  /// In vi, this message translates to:
  /// **'Sửa tên'**
  String get editNameCta;

  /// No description provided for @saveCta.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get saveCta;

  /// No description provided for @cancelCta.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancelCta;

  /// No description provided for @invalidNameError.
  ///
  /// In vi, this message translates to:
  /// **'Tên phải có từ 1 đến 20 ký tự nhìn thấy.'**
  String get invalidNameError;

  /// No description provided for @guestStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đang chơi với tư cách khách'**
  String get guestStatus;

  /// No description provided for @profileStars.
  ///
  /// In vi, this message translates to:
  /// **'sao'**
  String get profileStars;

  /// No description provided for @profileCompleted.
  ///
  /// In vi, this message translates to:
  /// **'đã hoàn thành'**
  String get profileCompleted;

  /// No description provided for @profileEncouragement.
  ///
  /// In vi, this message translates to:
  /// **'Cú dội hay đầu tiên đang chờ bạn.'**
  String get profileEncouragement;

  /// No description provided for @profileChapter.
  ///
  /// In vi, this message translates to:
  /// **'Chương {number}'**
  String profileChapter(int number);

  /// No description provided for @accountTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bảo vệ tiến trình'**
  String get accountTitle;

  /// No description provided for @guestAccountBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể đăng nhập để đồng bộ hồ sơ giữa các thiết bị.'**
  String get guestAccountBody;

  /// No description provided for @signInGoogleCta.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với Google'**
  String get signInGoogleCta;

  /// No description provided for @signInAppleCta.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với Apple'**
  String get signInAppleCta;

  /// No description provided for @signInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đang mở cửa sổ đăng nhập…'**
  String get signInProgress;

  /// No description provided for @signInFailedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Không đăng nhập được. Hãy kiểm tra tài khoản Google trên thiết bị rồi thử lại.'**
  String get signInFailedMessage;

  /// No description provided for @providerConfigRequired.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập sẽ khả dụng sau khi cấu hình provider phát hành.'**
  String get providerConfigRequired;

  /// No description provided for @avatarPresetsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh dựng sẵn'**
  String get avatarPresetsTitle;

  /// No description provided for @devicePhotoCta.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh từ thiết bị'**
  String get devicePhotoCta;

  /// No description provided for @avatarPrivacyCopy.
  ///
  /// In vi, this message translates to:
  /// **'Bộ chọn hệ thống chỉ mở khi bạn chọn và đồng bộ avatar.'**
  String get avatarPrivacyCopy;

  /// No description provided for @avatarInvalidError.
  ///
  /// In vi, this message translates to:
  /// **'Không dùng được ảnh này. Hãy chọn ảnh khác.'**
  String get avatarInvalidError;

  /// No description provided for @openProfileCta.
  ///
  /// In vi, this message translates to:
  /// **'Mở hồ sơ người chơi'**
  String get openProfileCta;

  /// No description provided for @badgesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Huy hiệu'**
  String get badgesTitle;

  /// No description provided for @badgeUnlocked.
  ///
  /// In vi, this message translates to:
  /// **'Đã mở'**
  String get badgeUnlocked;

  /// No description provided for @badgeLocked.
  ///
  /// In vi, this message translates to:
  /// **'Đang tiến hành'**
  String get badgeLocked;

  /// No description provided for @signOutCta.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get signOutCta;

  /// No description provided for @deleteAccountCta.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản'**
  String get deleteAccountCta;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa tài khoản này?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu đám mây và quyền đăng nhập sẽ bị xóa. Một bản tiến trình khách vẫn được giữ trên thiết bị.'**
  String get deleteAccountBody;

  /// No description provided for @confirmDeleteCta.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận xóa'**
  String get confirmDeleteCta;

  /// No description provided for @accountPending.
  ///
  /// In vi, this message translates to:
  /// **'Đang xử lý xóa tài khoản'**
  String get accountPending;

  /// No description provided for @accountRecovery.
  ///
  /// In vi, this message translates to:
  /// **'Cần xác nhận lại nhà cung cấp để tiếp tục xóa'**
  String get accountRecovery;

  /// No description provided for @accountDeleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa tài khoản'**
  String get accountDeleted;

  /// No description provided for @syncPending.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ đồng bộ'**
  String get syncPending;

  /// No description provided for @signedInStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng nhập'**
  String get signedInStatus;

  /// No description provided for @signedInResetGuard.
  ///
  /// In vi, this message translates to:
  /// **'Hãy đăng xuất trước khi xóa tiến trình cục bộ để dữ liệu đám mây không khôi phục lại.'**
  String get signedInResetGuard;

  /// No description provided for @signInReminderBody.
  ///
  /// In vi, this message translates to:
  /// **'Bảo vệ tiến trình này và khôi phục trên thiết bị khác.'**
  String get signInReminderBody;

  /// No description provided for @signInReminderCta.
  ///
  /// In vi, this message translates to:
  /// **'Mở tùy chọn đăng nhập'**
  String get signInReminderCta;

  /// No description provided for @leaderboardEntryCta.
  ///
  /// In vi, this message translates to:
  /// **'Xếp hạng'**
  String get leaderboardEntryCta;

  /// No description provided for @leaderboardEntrySemantic.
  ///
  /// In vi, this message translates to:
  /// **'Xem bảng xếp hạng Màn {arenaId}'**
  String leaderboardEntrySemantic(int arenaId);

  /// No description provided for @leaderboardWinEntrySemantic.
  ///
  /// In vi, this message translates to:
  /// **'Xem bảng xếp hạng của Màn {arenaId} vừa hoàn thành'**
  String leaderboardWinEntrySemantic(int arenaId);

  /// No description provided for @leaderboardTitle.
  ///
  /// In vi, this message translates to:
  /// **'BẢNG XẾP HẠNG'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardLevel.
  ///
  /// In vi, this message translates to:
  /// **'Màn {arenaId} · {arenaName}'**
  String leaderboardLevel(int arenaId, String arenaName);

  /// No description provided for @leaderboardGlobal.
  ///
  /// In vi, this message translates to:
  /// **'Toàn cầu'**
  String get leaderboardGlobal;

  /// No description provided for @leaderboardFriends.
  ///
  /// In vi, this message translates to:
  /// **'Bạn bè'**
  String get leaderboardFriends;

  /// No description provided for @leaderboardAllTime.
  ///
  /// In vi, this message translates to:
  /// **'Mọi thời đại'**
  String get leaderboardAllTime;

  /// No description provided for @leaderboardYou.
  ///
  /// In vi, this message translates to:
  /// **'Bạn'**
  String get leaderboardYou;

  /// No description provided for @leaderboardOutsideTop100.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang ngoài top 100'**
  String get leaderboardOutsideTop100;

  /// No description provided for @leaderboardSelected.
  ///
  /// In vi, this message translates to:
  /// **'đã chọn'**
  String get leaderboardSelected;

  /// No description provided for @leaderboardNotSelected.
  ///
  /// In vi, this message translates to:
  /// **'chưa chọn'**
  String get leaderboardNotSelected;

  /// No description provided for @leaderboardScopeAnnouncement.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn bảng {scope}'**
  String leaderboardScopeAnnouncement(String scope);

  /// No description provided for @leaderboardLoadedAnnouncement.
  ///
  /// In vi, this message translates to:
  /// **'Đã tải bảng {scope} cho Màn {arenaId}'**
  String leaderboardLoadedAnnouncement(String scope, int arenaId);

  /// No description provided for @leaderboardTopThreeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ba người dẫn đầu'**
  String get leaderboardTopThreeLabel;

  /// No description provided for @leaderboardListFromRankLabel.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách xếp hạng từ hạng {rank}'**
  String leaderboardListFromRankLabel(int rank);

  /// No description provided for @leaderboardRowSemantics.
  ///
  /// In vi, this message translates to:
  /// **'Hạng {rank}, {playerName}, {score} điểm'**
  String leaderboardRowSemantics(int rank, String playerName, String score);

  /// No description provided for @leaderboardCurrentPlayerSuffix.
  ///
  /// In vi, this message translates to:
  /// **'người chơi hiện tại'**
  String get leaderboardCurrentPlayerSuffix;

  /// No description provided for @leaderboardLoadingAnnouncement.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải bảng xếp hạng Màn {arenaId}'**
  String leaderboardLoadingAnnouncement(int arenaId);

  /// No description provided for @leaderboardLoadingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải bảng xếp hạng…'**
  String get leaderboardLoadingTitle;

  /// No description provided for @leaderboardLoadingBadge.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải'**
  String get leaderboardLoadingBadge;

  /// No description provided for @leaderboardEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có điểm cho Màn {arenaId}'**
  String leaderboardEmptyTitle(int arenaId);

  /// No description provided for @leaderboardEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Hãy là người đầu tiên ghi tên vào bảng {scope}.'**
  String leaderboardEmptyMessage(String scope);

  /// No description provided for @leaderboardServiceErrorTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được bảng xếp hạng'**
  String get leaderboardServiceErrorTitle;

  /// No description provided for @leaderboardServiceErrorMessage.
  ///
  /// In vi, this message translates to:
  /// **'Game Center/Google Play Games tạm thời không phản hồi.'**
  String get leaderboardServiceErrorMessage;

  /// No description provided for @leaderboardServiceErrorBadge.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi dịch vụ'**
  String get leaderboardServiceErrorBadge;

  /// No description provided for @leaderboardRetryCta.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get leaderboardRetryCta;

  /// No description provided for @leaderboardStaleTitle.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu có thể đã cũ'**
  String get leaderboardStaleTitle;

  /// No description provided for @leaderboardStaleMessage.
  ///
  /// In vi, this message translates to:
  /// **'Đang hiển thị bản {scope} của Màn {arenaId} được lưu gần nhất.'**
  String leaderboardStaleMessage(String scope, int arenaId);

  /// No description provided for @leaderboardOfflineBadge.
  ///
  /// In vi, this message translates to:
  /// **'Offline'**
  String get leaderboardOfflineBadge;

  /// No description provided for @leaderboardOfflineQueueMessage.
  ///
  /// In vi, this message translates to:
  /// **'Không có kết nối · Điểm đang chờ sẽ được giữ trên thiết bị'**
  String get leaderboardOfflineQueueMessage;

  /// No description provided for @leaderboardOfflineEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không có dữ liệu offline'**
  String get leaderboardOfflineEmptyTitle;

  /// No description provided for @leaderboardOfflineEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có bản lưu phù hợp cho Màn {arenaId} · {scope}.'**
  String leaderboardOfflineEmptyMessage(int arenaId, String scope);

  /// No description provided for @leaderboardFriendsUnavailableTitle.
  ///
  /// In vi, this message translates to:
  /// **'Không thể hiển thị bảng Bạn bè'**
  String get leaderboardFriendsUnavailableTitle;

  /// No description provided for @leaderboardFriendsUnavailableMessage.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách bạn bè hiện không khả dụng do quyền riêng tư, hạn chế tài khoản hoặc cài đặt nền tảng.'**
  String get leaderboardFriendsUnavailableMessage;

  /// No description provided for @leaderboardViewGlobalCta.
  ///
  /// In vi, this message translates to:
  /// **'Xem Toàn cầu'**
  String get leaderboardViewGlobalCta;

  /// No description provided for @leaderboardAuthTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối bảng xếp hạng?'**
  String get leaderboardAuthTitle;

  /// No description provided for @leaderboardAuthDescription.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối Game Center hoặc Google Play Games để xem bảng và gửi kỷ lục. Bạn vẫn có thể chơi hoàn toàn offline.'**
  String get leaderboardAuthDescription;

  /// No description provided for @leaderboardAuthConnectCta.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối'**
  String get leaderboardAuthConnectCta;

  /// No description provided for @leaderboardAuthLaterCta.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get leaderboardAuthLaterCta;

  /// No description provided for @leaderboardAuthPromptMessage.
  ///
  /// In vi, this message translates to:
  /// **'Điểm, sao, xu và tiến trình cục bộ vẫn được giữ nguyên nếu bạn kết nối sau.'**
  String get leaderboardAuthPromptMessage;

  /// No description provided for @leaderboardSubmissionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái gửi điểm'**
  String get leaderboardSubmissionTitle;

  /// No description provided for @leaderboardSubmissionSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi'**
  String get leaderboardSubmissionSent;

  /// No description provided for @leaderboardSubmissionSentMessage.
  ///
  /// In vi, this message translates to:
  /// **'Nền tảng đã xác nhận kỷ lục này.'**
  String get leaderboardSubmissionSentMessage;

  /// No description provided for @leaderboardSubmissionPending.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ'**
  String get leaderboardSubmissionPending;

  /// No description provided for @leaderboardSubmissionPendingMessage.
  ///
  /// In vi, this message translates to:
  /// **'Sẽ tự gửi khi có mạng và đúng danh tính nền tảng.'**
  String get leaderboardSubmissionPendingMessage;

  /// No description provided for @leaderboardSubmissionFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không gửi được'**
  String get leaderboardSubmissionFailed;

  /// No description provided for @leaderboardSubmissionNotQueued.
  ///
  /// In vi, this message translates to:
  /// **'Chưa gửi'**
  String get leaderboardSubmissionNotQueued;

  /// No description provided for @leaderboardSubmissionNotQueuedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Kết quả này không phải kỷ lục mới đã lưu nên không được gửi.'**
  String get leaderboardSubmissionNotQueuedMessage;

  /// No description provided for @leaderboardSubmissionPersistFailedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Không thể lưu kết quả hoặc hàng đợi trên thiết bị, nên nền tảng chưa chấp nhận điểm này.'**
  String get leaderboardSubmissionPersistFailedMessage;

  /// No description provided for @leaderboardSubmissionDisconnected.
  ///
  /// In vi, this message translates to:
  /// **'Chưa kết nối'**
  String get leaderboardSubmissionDisconnected;

  /// No description provided for @leaderboardSubmissionDisconnectedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Cần kết nối rõ ràng trước khi điểm này có thể được gửi.'**
  String get leaderboardSubmissionDisconnectedMessage;

  /// No description provided for @leaderboardSubmitScoreCta.
  ///
  /// In vi, this message translates to:
  /// **'Gửi điểm'**
  String get leaderboardSubmitScoreCta;

  /// No description provided for @leaderboardReconnectCta.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối lại'**
  String get leaderboardReconnectCta;

  /// No description provided for @leaderboardRetrySubmissionCta.
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại'**
  String get leaderboardRetrySubmissionCta;

  /// No description provided for @leaderboardReasonUnsupported.
  ///
  /// In vi, this message translates to:
  /// **'Nền tảng này không hỗ trợ gửi điểm.'**
  String get leaderboardReasonUnsupported;

  /// No description provided for @leaderboardReasonRestricted.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản nền tảng đang bị hạn chế gửi điểm.'**
  String get leaderboardReasonRestricted;

  /// No description provided for @leaderboardReasonRejected.
  ///
  /// In vi, this message translates to:
  /// **'Nền tảng không chấp nhận điểm này.'**
  String get leaderboardReasonRejected;

  /// No description provided for @leaderboardReasonUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Nền tảng chưa thể nhận điểm này. Kỷ lục cục bộ vẫn an toàn.'**
  String get leaderboardReasonUnknown;

  /// No description provided for @leaderboardAchievedScore.
  ///
  /// In vi, this message translates to:
  /// **'Điểm vừa đạt: {score}'**
  String leaderboardAchievedScore(String score);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
