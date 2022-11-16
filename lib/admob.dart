import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static String? get bannerAdUnitId {
    if (Platform.isAndroid) {
      // Androidの広告ユニットID
      return 'ca-app-pub-8319377204356997/7596288607';
    } else if (Platform.isIOS) {
      // iOSの広告ユニットID
      return 'ca-app-pub-8319377204356997/2208230554';
    }
    return 'error';
  }

  static String? get rewardedAdUnitId {
    if (Platform.isAndroid) {
      // Androidの広告ユニットID
      return 'ca-app-pub-8319377204356997/9412040953';
    } else if (Platform.isIOS) {
      // iOSの広告ユニットID
      return 'ca-app-pub-8319377204356997/1661543442';
    }
    return 'error';
  }

  static final BannerAdListener bannerAdListener = BannerAdListener(
    onAdLoaded: (ad) => debugPrint(''),
    onAdFailedToLoad: (ad, error) {
      ad.dispose();
      debugPrint('Ad failed to load ; $error');
    },
    onAdOpened: (ad) => debugPrint('Ad opened'),
    onAdClosed: (ad) => debugPrint('Ad closed'),
  );
}

class AppOpenAdManager {
  String adUnitId = Platform.isAndroid
      ? 'ca-app-pub-8319377204356997/8331566022'
      : 'ca-app-pub-8319377204356997/9644647690';

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;

  void loadAd() {
    AppOpenAd.load(
      adUnitId: adUnitId,
      orientation: AppOpenAd.orientationPortrait,
      request: AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('AppOpenAd failed to load: $error');
          // Handle the error.
        },
      ),
    );
  }

  /// Whether an ad is available to be shown.
  bool get isAdAvailable {
    return _appOpenAd != null;
  }
}
