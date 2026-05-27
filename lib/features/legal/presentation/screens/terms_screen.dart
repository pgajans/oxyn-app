import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Kullanım Şartları'),
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
            'Kullanım Şartları',
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
            title: '1. Kabul',
            body:
                'Oxyn uygulamasını indirerek, yükleyerek veya kullanarak bu Kullanım '
                'Şartlarını kabul etmiş sayılırsınız. Bu şartları kabul etmiyorsanız '
                'uygulamayı kullanmayınız.',
          ),
          _Section(
            title: '2. Hizmet Tanımı',
            body:
                'Oxyn, mobil cihazınız için batarya analizi, depolama temizliği, '
                'cihaz performansı izleme ve kişiselleştirme özellikleri sunan bir '
                'yardımcı uygulamadır. Uygulama cihazınızda yerel olarak çalışır.',
          ),
          _Section(
            title: '3. Kullanım Koşulları',
            body: 'Uygulamayı kullanırken aşağıdaki kurallara uymanız gerekmektedir:\n\n'
                '• Uygulamayı yalnızca yasal amaçlarla kullanın\n'
                '• Uygulamayı tersine mühendislik yapmayın, kaynak kodunu çıkarmayın\n'
                '• Uygulamayı başka kişilere veya platformlara dağıtmayın\n'
                '• Uygulama altyapısına zarar verecek eylemlerden kaçının',
          ),
          _Section(
            title: '4. Abonelikler ve Ödemeler',
            body:
                'Oxyn, ücretsiz ve premium (Oxyn Plus) olmak üzere iki kullanım modeli sunar.\n\n'
                'Premium Abonelik:\n'
                '• Abonelikler Apple App Store veya Google Play Store üzerinden işlenir\n'
                '• Abonelik süresi dolmadan en az 24 saat önce iptal edilmezse otomatik '
                'olarak yenilenir\n'
                '• İptal işlemi cihazınızın mağaza ayarlarından yapılmalıdır\n'
                '• Ücretsiz deneme süresi varsa, kullanılmayan kısım abonelik satın '
                'alındığında geçersiz olur\n\n'
                'İade Politikası:\n'
                '• İade talepleri Apple/Google iade politikalarına tabidir\n'
                '• Doğrudan uygulama üzerinden iade işlemi yapılamaz',
          ),
          _Section(
            title: '5. Fikri Mülkiyet',
            body:
                'Oxyn uygulamasının tüm içeriği, tasarımı, logosu, kodları ve diğer '
                'fikri mülkiyet unsurları telif hakkı ile korunmaktadır. Bu materyallerin '
                'izinsiz kullanımı, kopyalanması veya dağıtılması yasaktır.',
          ),
          _Section(
            title: '6. Sorumluluk Sınırlaması',
            body:
                'Oxyn "olduğu gibi" sunulmaktadır. Aşağıdaki konularda sorumluluk '
                'kabul etmiyoruz:\n\n'
                '• Uygulamanın kullanımından kaynaklanan doğrudan veya dolaylı zararlar\n'
                '• Cihaz verilerinin kaybı (temizleme işlemleri kullanıcı onayı ile yapılır)\n'
                '• Uygulamanın kesintisiz veya hatasız çalışacağı garantisi\n'
                '• Üçüncü taraf hizmetlerdeki aksaklıklar\n\n'
                'Temizleme özelliğini kullanırken silinen dosyalar geri getirilemez. '
                'Silme işlemi öncesinde onayınız alınır.',
          ),
          _Section(
            title: '7. Cihaz İzinleri',
            body: 'Uygulamanın düzgün çalışması için aşağıdaki izinler gerekebilir:\n\n'
                '• Fotoğraf/medya erişimi: Temizleme özelliği için\n'
                '• Bildirimler: Batarya uyarıları ve hatırlatmalar için\n'
                '• İnternet erişimi: Abonelik doğrulama ve reklam gösterimi için\n\n'
                'Bu izinleri cihaz ayarlarından istediğiniz zaman geri alabilirsiniz.',
          ),
          _Section(
            title: '8. Yaş Sınırı',
            body:
                'Oxyn, 13 yaşından büyük kullanıcılara yöneliktir. 13 yaşın altındaki '
                'bireyler uygulamayı kullanmamalıdır.',
          ),
          _Section(
            title: '9. Şartlardaki Değişiklikler',
            body:
                'Bu Kullanım Şartlarını önceden bildirimde bulunarak güncelleme hakkını '
                'saklı tutarız. Güncellemelerden sonra uygulamayı kullanmaya devam etmeniz, '
                'yeni şartları kabul ettiğiniz anlamına gelir.',
          ),
          _Section(
            title: '10. Hesap Silme',
            body:
                'Oxyn hesap oluşturma gerektirmeyen bir uygulamadır. Tüm verileriniz '
                'cihazınızda saklanır. Uygulamayı sildiğinizde yerel verileriniz de '
                'silinir. Premium aboneliğinizi iptal etmek için mağaza ayarlarınızı '
                'kullanmanız gerekmektedir.',
          ),
          _Section(
            title: '11. Uygulanacak Hukuk',
            body:
                'Bu Kullanım Şartları Türkiye Cumhuriyeti yasalarına tabidir. '
                'Uyuşmazlıklarda Türkiye mahkemeleri yetkilidir.',
          ),
          _Section(
            title: '12. İletişim',
            body:
                'Kullanım şartları hakkında sorularınız için:\n\n'
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
