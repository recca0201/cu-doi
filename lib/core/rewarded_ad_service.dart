import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum RewardedAdOutcome { earned, dismissed, unavailable }

abstract interface class RewardedAdService {
  Future<RewardedAdOutcome> show();
}

/// Owns one full-screen rewarded-ad operation at a time.
///
/// Development builds use Google's dedicated test units. Production units are
/// supplied with dart defines; missing production configuration fails closed.
final class GoogleRewardedAdService implements RewardedAdService {
  static const String _environment = String.fromEnvironment(
    'ADMOB_ENVIRONMENT',
    defaultValue: 'qa',
  );
  static const String _androidProductionUnit = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_AD_UNIT_ID',
  );
  static const String _iosProductionUnit = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_AD_UNIT_ID',
  );
  static const String _androidTestUnit =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosTestUnit = 'ca-app-pub-3940256099942544/1712485313';

  Future<InitializationStatus>? _initialization;
  bool _busy = false;

  @override
  Future<RewardedAdOutcome> show() async {
    if (_busy) return RewardedAdOutcome.unavailable;
    final String? unitId = _unitId;
    if (unitId == null) return RewardedAdOutcome.unavailable;
    _busy = true;
    try {
      _initialization ??= MobileAds.instance.initialize();
      await _initialization;
      return await _loadAndShow(unitId);
    } on Object {
      return RewardedAdOutcome.unavailable;
    } finally {
      _busy = false;
    }
  }

  String? get _unitId {
    final bool production = _environment.toLowerCase() == 'production';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        production
            ? _validProductionUnit(_androidProductionUnit)
            : _androidTestUnit,
      TargetPlatform.iOS =>
        production ? _validProductionUnit(_iosProductionUnit) : _iosTestUnit,
      _ => null,
    };
  }

  static String? _validProductionUnit(String value) {
    if (!RegExp(r'^ca-app-pub-\d{16}/\d{10}$').hasMatch(value) ||
        value.startsWith('ca-app-pub-3940256099942544/')) {
      return null;
    }
    return value;
  }

  Future<RewardedAdOutcome> _loadAndShow(String unitId) {
    final Completer<RewardedAdOutcome> result = Completer<RewardedAdOutcome>();
    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          bool earned = false;
          void complete(RewardedAdOutcome outcome) {
            if (!result.isCompleted) result.complete(outcome);
          }

          ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
            onAdDismissedFullScreenContent: (RewardedAd value) {
              value.dispose();
              complete(
                earned ? RewardedAdOutcome.earned : RewardedAdOutcome.dismissed,
              );
            },
            onAdFailedToShowFullScreenContent: (RewardedAd value, AdError _) {
              value.dispose();
              complete(RewardedAdOutcome.unavailable);
            },
          );
          ad.show(
            onUserEarnedReward: (AdWithoutView _, RewardItem _) {
              earned = true;
            },
          );
        },
        onAdFailedToLoad: (LoadAdError _) {
          if (!result.isCompleted) {
            result.complete(RewardedAdOutcome.unavailable);
          }
        },
      ),
    );
    return result.future;
  }
}
