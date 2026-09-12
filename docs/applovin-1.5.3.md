# AppLovin Reklam Entegrasyonu — 1.5.3 Takip Notu

## Durum (bekliyoruz)
- AppLovin yayıncı hesabı: `pgajans@gmail.com` — **onay bekliyor**.
- Aktivasyon maili `pgajans@gmail.com`'dan `account-approval@applovin.com`'a gönderildi.
- Play Store geliştirici iletişim e-postası `oxynapp@gmail.com` → **`pgajans@gmail.com`** yapıldı
  (AppLovin şart #3: store geliştirici e-postası = AppLovin hesabı e-postası).
- iOS App Store: uygulama CANLI (public e-posta alanı yok, değişiklik gerekmedi).

## Tetikleyici
**Kullanıcı, AppLovin onayı gelince yazacak.** O zaman birlikte build alınacak.

## Onay gelince yapılacaklar
1. AppLovin panelinden **SDK Key** + **Ad Unit ID'leri** al (interstitial, banner, rewarded).
2. Anahtarlarla build:
   ```
   flutter build appbundle --release \
     --dart-define=APPLOVIN_SDK_KEY=... \
     --dart-define=APPLOVIN_INTERSTITIAL_ID=... \
     --dart-define=APPLOVIN_BANNER_ID=... \
     --dart-define=APPLOVIN_REWARDED_ID=...
   ```
   iOS için: `flutter build ipa --release --dart-define=...` (aynı anahtarlar).
3. Her iki store'a gönder (yeniden inceleme).

## 1.5.3'te hazır olan kod
- `lib/core/services/ad_service.dart`: interstitial sıklık limiti + `maybeShowInterstitial(isPremium:)`.
- `lib/core/widgets/oxyn_banner_ad.dart`: premium'da ve anahtar yokken kendini gizleyen banner.
- Banner: Haberler + Trivia (başlangıç/oyun sonu).
- Interstitial: Trivia oyun sonu (frequency-capped).
- Android: `com.google.android.gms.permission.AD_ID` izni.
- iOS: `NSUserTrackingUsageDescription` (ATT) + `SKAdNetworkItems`.
- Versiyon: `1.5.3+15`.

## Sonraya bırakılanlar
- Rewarded (ödüllü) UI butonları — 5 dil ARB metni ile eklenecek (AdService hazır).
- iOS privacy manifest (opsiyonel; AppLovin SDK kendi manifestini getirir).

## Notlar
- Reklamlar **agresif değil** (Play "Disruptive Ads" politikasına uygun); premium kullanıcıya reklam yok.
- AppLovin `dashboard.applovin.com` KAPALI — giriş: `https://www.applovin.com/en/login`.
