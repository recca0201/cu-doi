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
  /// **'Bắn Bừa'**
  String get appTitle;

  /// No description provided for @menuTagline.
  ///
  /// In vi, this message translates to:
  /// **'Bắn thẳng không tính. Dội tường mới ăn.'**
  String get menuTagline;

  /// No description provided for @playCta.
  ///
  /// In vi, this message translates to:
  /// **'Chơi ngay'**
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

  /// No description provided for @howToTitle.
  ///
  /// In vi, this message translates to:
  /// **'Luật chơi'**
  String get howToTitle;

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
