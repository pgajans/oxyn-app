import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Gizlilik Politikası'),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Gizlilik Politikası',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Son güncelleme: 1 Nisan 2026',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
          ),
          SizedBox(height: AppSpacing.lg),
          _Section(
            title: '1. Giriş',
            body:
                'Oxyn ("biz", "uygulama") olarak gizliliğinize saygı duyuyoruz. '
                'Bu Gizlilik Politikası, Oxyn mobil uygulamasını kullandığınızda '
                'hangi bilgilerin toplandığını, nasıl kullanıldığını ve nasıl korunduğunu açıklar.',
          ),
          _Section(
            title: '2. Toplanan Bilgiler',
            body:
                'Oxyn, cihazınızda yerel olarak çalışan bir optimizasyon uygulamasıdır. '
                'Topladığımız bilgiler:\n\n'
                '• Cihaz bilgileri: Cihaz modeli, işletim sistemi sürümü, batarya durumu, '
                'depolama kullanımı gibi teknik bilgiler. Bu veriler yalnızca cihazınızda '
                'işlenir ve sunucularımıza gönderilmez.\n\n'
                '• Kullanım analitikleri: Uygulama içi etkileşimleriniz hakkında anonim '
                've toplu istatistikler (Firebase Analytics aracılığıyla). Bunlar kişisel '
                'bilgilerinizi içermez.\n\n'
                '• Abonelik bilgileri: Premium abonelik durumunuz RevenueCat altyapısı '
                'üzerinden yönetilir. Ödeme bilgileriniz Apple/Google tarafından işlenir, '
                'biz doğrudan erişemeyiz.\n\n'
                '• Fotoğraflar ve medya: Temizleme özelliğini kullandığınızda fotoğraflarınıza '
                'erişim izni istenir. Bu veriler yalnızca cihazınızda analiz edilir ve '
                'hiçbir sunucuya yüklenmez.',
          ),
          _Section(
            title: '3. Bilgilerin Kullanımı',
            body: 'Toplanan bilgileri şu amaçlarla kullanırız:\n\n'
                '• Uygulama özelliklerini sağlamak (batarya analizi, depolama temizliği, '
                'cihaz optimizasyonu)\n'
                '• Uygulama performansını iyileştirmek\n'
                '• Teknik sorunları tespit etmek ve gidermek\n'
                '• Kullanıcı deneyimini geliştirmek',
          ),
          _Section(
            title: '4. Veri Paylaşımı',
            body:
                'Kişisel verilerinizi üçüncü taraflarla satmıyor veya kiralamıyoruz. '
                'Aşağıdaki hizmet sağlayıcılarla sınırlı veri paylaşımı yapılabilir:\n\n'
                '• Firebase (Google): Anonim kullanım analitikleri ve bildirimler\n'
                '• RevenueCat: Abonelik yönetimi\n'
                '• AppLovin: Reklam gösterimi (ücretsiz kullanıcılar için)\n\n'
                'Bu hizmet sağlayıcıların kendi gizlilik politikaları geçerlidir.',
          ),
          _Section(
            title: '5. Reklam ve İzleme',
            body:
                'Ücretsiz kullanıcılara reklam göstermek için AppLovin MAX kullanılmaktadır. '
                'Reklam ağları, size daha uygun reklamlar göstermek amacıyla cihaz tanımlayıcısı '
                '(IDFA/GAID) kullanabilir. iOS cihazlarda App Tracking Transparency izni '
                'istenir; izin vermezseniz kişiselleştirilmemiş reklamlar gösterilir.\n\n'
                'Premium aboneler reklam görmez.',
          ),
          _Section(
            title: '6. Veri Güvenliği',
            body:
                'Verilerinizi korumak için endüstri standardı güvenlik önlemleri uygularız. '
                'Cihaz verileriniz yerel olarak işlenir ve şifrelenmemiş olarak dış sunuculara '
                'aktarılmaz. Ancak internet üzerinden yapılan hiçbir iletişimin %100 güvenli '
                'olduğu garanti edilemez.',
          ),
          _Section(
            title: '7. Çocukların Gizliliği',
            body:
                'Oxyn, 13 yaşın altındaki çocuklara yönelik değildir. Bilerek 13 yaşından '
                'küçük kullanıcılardan kişisel bilgi toplamayız. Böyle bir durum tespit '
                'edilirse ilgili verileri derhal sileriz.',
          ),
          _Section(
            title: '8. Haklarınız',
            body: 'Aşağıdaki haklara sahipsiniz:\n\n'
                '• Verilerinize erişim talep etme\n'
                '• Verilerinizin silinmesini isteme\n'
                '• Reklam izlemeyi reddetme (iOS ATT / Android Ad Settings)\n'
                '• Bildirimleri kapatma\n\n'
                'Bu haklarınızı kullanmak için bize pgajans@gmail.com adresinden ulaşabilirsiniz.',
          ),
          _Section(
            title: '9. Politika Değişiklikleri',
            body:
                'Bu Gizlilik Politikasını zaman zaman güncelleyebiliriz. Önemli değişikliklerde '
                'uygulama içi bildirim göndeririz. Güncel politikayı her zaman bu sayfadan '
                'kontrol edebilirsiniz.',
          ),
          _Section(
            title: '10. İletişim',
            body:
                'Gizlilik politikamız hakkında sorularınız için:\n\n'
                'E-posta: pgajans@gmail.com',
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
