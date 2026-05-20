import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'audio_manager.dart';

class AdMobManager {
  static final AdMobManager _instance = AdMobManager._internal();
  factory AdMobManager() => _instance;
  AdMobManager._internal();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;

  // ВАЖНО: Замени на свои Ad Unit ID из AdMob консоли!
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // TEST ID - замени на свой!
      return 'ca-app-pub-9604144074094777/9950655590';
      // Твой ID будет вида: 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY'
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910';
    }
    return '';
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-9604144074094777/9783134638'; // TEST ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }
    return '';
  }

  // Инициализация AdMob (вызвать в main.dart)
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  // ========== INTERSTITIAL AD (После игры) ==========
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          print('✅ Interstitial ad loaded');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              _loadInterstitialAd(); // Загружаем следующую
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('❌ Failed to show interstitial: $error');
              ad.dispose();
              _isInterstitialAdReady = false;
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('❌ Failed to load interstitial: $error');
          _isInterstitialAdReady = false;
          // Повторная попытка через 30 секунд
          Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
        },
      ),
    );
  }

  void showInterstitialAd({VoidCallback? onAdClosed}) {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _isInterstitialAdReady = false;
      if (onAdClosed != null) {
        Future.delayed(const Duration(seconds: 1), onAdClosed);
      }
    } else {
      print('⚠️ Interstitial ad not ready yet');
      if (onAdClosed != null) onAdClosed();
    }
  }

  // ========== REWARDED AD (За подсказку) ==========
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          print('✅ Rewarded ad loaded');

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isRewardedAdReady = false;
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('❌ Failed to show rewarded: $error');
              ad.dispose();
              _isRewardedAdReady = false;
              _loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('❌ Failed to load rewarded: $error');
          _isRewardedAdReady = false;
          Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
        },
      ),
    );
  }

  void showRewardedAd({required Function(bool) onRewardEarned}) {
    if (_isRewardedAdReady && _rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          print('🎁 User earned reward: ${reward.amount} ${reward.type}');
          onRewardEarned(true);
        },
      );
      _rewardedAd = null;
      _isRewardedAdReady = false;
    } else {
      print('⚠️ Rewarded ad not ready');
      onRewardEarned(false);
    }
  }

  bool get isRewardedAdReady => _isRewardedAdReady;

  // Очистка ресурсов
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}