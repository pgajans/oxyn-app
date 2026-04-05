import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiDoctorService {
  // Google AI Studio'dan ücretsiz API key al: https://aistudio.google.com/apikey
  static const _geminiApiKey = 'AIzaSyA76EiMgXRB2Sb2yumt4P6iVM-OrRtNNJc';
  static const _lastResultKey = 'ai_doctor_last_result';
  static const _lastDateKey = 'ai_doctor_last_date';

  static bool get _isPlaceholderKey => _geminiApiKey.startsWith('YOUR_');

  Future<bool> canAnalyzeToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastDateKey);
    if (lastDate == null) return true;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return lastDate != today;
  }

  Future<String?> getLastResult() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastResultKey);
  }

  Future<String> analyzeDevice({
    required int batteryLevel,
    required double batteryTemperature,
    required int batteryHealth,
    required double usedStoragePercent,
    required String freeStorage,
  }) async {
    if (_isPlaceholderKey) {
      return _generateLocalReport(
        batteryLevel: batteryLevel,
        batteryTemperature: batteryTemperature,
        batteryHealth: batteryHealth,
        usedStoragePercent: usedStoragePercent,
        freeStorage: freeStorage,
      );
    }

    try {
      final prompt =
          'Sen 15 yıllık deneyime sahip kıdemli bir mobil cihaz uzmanısın. '
          'Bir kullanıcının telefonunu detaylı analiz ediyorsun. '
          'Aşağıdaki cihaz verilerini profesyonel bir şekilde değerlendir.\n\n'
          '📊 CİHAZ VERİLERİ:\n'
          '• Batarya Seviyesi: %$batteryLevel\n'
          '• Batarya Sıcaklığı: ${batteryTemperature.toStringAsFixed(1)}°C\n'
          '• Tahmini Batarya Sağlığı: %$batteryHealth\n'
          '• Depolama Kullanımı: %${usedStoragePercent.toStringAsFixed(0)}\n'
          '• Kullanılabilir Boş Alan: $freeStorage\n\n'
          'RAPOR FORMATI (bu formatı kesinlikle takip et):\n\n'
          '🔍 GENEL DEĞERLENDİRME\n'
          'Cihazın genel durumunu 2-3 cümle ile özetle. Ciddi ve profesyonel bir ton kullan.\n\n'
          '⚠️ TESPİT EDİLEN SORUNLAR\n'
          'Tespit ettiğin her sorunu madde madde yaz. Her maddenin başına • koy. '
          'Sorun yoksa "Kritik bir sorun tespit edilmedi" yaz. '
          'Küçük sorunları bile belirt (örn: depolama %70 üzeriyse uyar, sıcaklık 35°C üzeriyse uyar, batarya sağlığı %85 altındaysa uyar).\n\n'
          '💡 ÖNERİLER\n'
          'En az 3 somut öneri yaz. Her önerinin başına numara koy (1. 2. 3.). '
          'Öneriler spesifik olsun, genel tavsiye değil. '
          'Örnek: "Şarjı %20 altına düşürmemeye çalışın" gibi.\n\n'
          '📈 RİSK SEVİYESİ\n'
          'Cihazın genel risk seviyesini belirt: DÜŞÜK / ORTA / YÜKSEK. '
          'Yanına kısa bir açıklama ekle.\n\n'
          'ÖNEMLİ KURALLAR:\n'
          '- Türkçe yaz\n'
          '- Profesyonel ve güven veren bir ton kullan\n'
          '- Kullanıcıyı gereksiz korkutma ama sorunları görmezden gelme\n'
          '- Rapor en az 150 kelime olsun\n'
          '- Emoji başlıklarını aynen kullan (🔍 ⚠️ 💡 📈)';

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_geminiApiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.6,
            'maxOutputTokens': 800,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final result = (parts[0]['text'] as String).trim();
            await _saveResult(result);
            return result;
          }
        }
        return _generateLocalReport(
          batteryLevel: batteryLevel,
          batteryTemperature: batteryTemperature,
          batteryHealth: batteryHealth,
          usedStoragePercent: usedStoragePercent,
          freeStorage: freeStorage,
        );
      } else {
        debugPrint('Gemini API error: ${response.statusCode} ${response.body}');
        return _generateLocalReport(
          batteryLevel: batteryLevel,
          batteryTemperature: batteryTemperature,
          batteryHealth: batteryHealth,
          usedStoragePercent: usedStoragePercent,
          freeStorage: freeStorage,
        );
      }
    } catch (e) {
      debugPrint('AI Doctor error: $e');
      return _generateLocalReport(
        batteryLevel: batteryLevel,
        batteryTemperature: batteryTemperature,
        batteryHealth: batteryHealth,
        usedStoragePercent: usedStoragePercent,
        freeStorage: freeStorage,
      );
    }
  }

  Future<String> _generateLocalReport({
    required int batteryLevel,
    required double batteryTemperature,
    required int batteryHealth,
    required double usedStoragePercent,
    required String freeStorage,
  }) async {
    final buffer = StringBuffer();

    buffer.writeln('🔍 GENEL DEĞERLENDİRME');
    if (batteryHealth >= 85 && usedStoragePercent < 80 && batteryTemperature < 38) {
      buffer.writeln('Cihazınız genel olarak sağlıklı bir durumda. Batarya ve depolama değerleri kabul edilebilir seviyede. Düzenli bakım ile cihazınızın ömrünü uzatabilirsiniz.');
    } else if (batteryHealth >= 70) {
      buffer.writeln('Cihazınızda bazı iyileştirme gerektiren alanlar tespit edildi. Acil bir durum söz konusu olmasa da, aşağıdaki önerileri dikkate almanız cihaz performansını artıracaktır.');
    } else {
      buffer.writeln('Cihazınızda dikkat edilmesi gereken önemli bulgular tespit edildi. Özellikle batarya sağlığı konusunda önlem almanız önerilir.');
    }

    buffer.writeln();
    buffer.writeln('⚠️ TESPİT EDİLEN SORUNLAR');
    bool hasIssue = false;

    if (batteryHealth < 85) {
      buffer.writeln('• Batarya sağlığı %$batteryHealth seviyesinde. ${batteryHealth < 70 ? "Pil değişimi düşünülmeli." : "Yıpranma başlamış, dikkatli kullanım önerilir."}');
      hasIssue = true;
    }
    if (batteryTemperature > 35) {
      buffer.writeln('• Cihaz sıcaklığı ${batteryTemperature.toStringAsFixed(1)}°C ile normalin üzerinde. Aşırı ısınma batarya ömrünü kısaltır.');
      hasIssue = true;
    }
    if (usedStoragePercent > 75) {
      buffer.writeln('• Depolama alanının %${usedStoragePercent.toStringAsFixed(0)}\'${usedStoragePercent >= 90 ? "ı" : "i"} dolu. ${usedStoragePercent >= 90 ? "Kritik seviyede alan azlığı var." : "Temizlik yapılması önerilir."}');
      hasIssue = true;
    }
    if (batteryLevel < 20) {
      buffer.writeln('• Batarya seviyesi %$batteryLevel ile düşük. Cihazı en kısa sürede şarj edin.');
      hasIssue = true;
    }
    if (!hasIssue) {
      buffer.writeln('Kritik bir sorun tespit edilmedi.');
    }

    buffer.writeln();
    buffer.writeln('💡 ÖNERİLER');
    buffer.writeln('1. Şarj seviyesini %20-80 arasında tutarak batarya ömrünü uzatın.');
    buffer.writeln('2. ${usedStoragePercent > 75 ? "Gereksiz dosya ve fotoğrafları temizleyerek depolama alanı açın." : "Depolama alanınız iyi durumda, düzenli temizlik yapmaya devam edin."}');
    buffer.writeln('3. ${batteryTemperature > 35 ? "Cihazı serin bir ortamda kullanın ve ağır uygulamaları kapatın." : "Arka planda çalışan gereksiz uygulamaları kapatarak performansı artırın."}');

    buffer.writeln();
    buffer.writeln('📈 RİSK SEVİYESİ');
    if (batteryHealth >= 85 && usedStoragePercent < 80 && batteryTemperature < 38) {
      buffer.write('DÜŞÜK - Cihazınız sağlıklı durumda, düzenli bakımla uzun süre sorunsuz kullanabilirsiniz.');
    } else if (batteryHealth >= 70 && usedStoragePercent < 90) {
      buffer.write('ORTA - Bazı iyileştirmeler yapılması önerilir, ancak acil bir durum yok.');
    } else {
      buffer.write('YÜKSEK - Bazı konularda acil müdahale önerilir.');
    }

    final result = buffer.toString();
    await _saveResult(result);
    return result;
  }

  Future<void> _saveResult(String result) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString(_lastResultKey, result);
    await prefs.setString(_lastDateKey, today);
  }
}
