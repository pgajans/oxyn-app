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
          'Sen bir cep telefonu sağlık uzmanısın. Aşağıdaki cihaz verilerini analiz et ve kullanıcıya Türkçe olarak 3-4 cümlelik kısa, kişiselleştirilmiş ve anlaşılır bir rapor yaz. Teknik jargondan kaçın.\n\n'
          'Cihaz Verileri:\n'
          '- Batarya Seviyesi: %$batteryLevel\n'
          '- Batarya Sıcaklığı: ${batteryTemperature.toStringAsFixed(1)}°C\n'
          '- Batarya Sağlığı: %$batteryHealth\n'
          '- Depolama Kullanımı: %${usedStoragePercent.toStringAsFixed(0)}\n'
          '- Boş Alan: $freeStorage\n\n'
          'Rapor:';

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
            'temperature': 0.7,
            'maxOutputTokens': 200,
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
    final parts = <String>[];

    if (batteryHealth >= 90) {
      parts.add(
          'Bataryanızın sağlık durumu iyi görünüyor (%$batteryHealth). Pil ömrünü uzun tutmak için şarjı %20-80 arasında tutmaya çalışın.');
    } else if (batteryHealth >= 70) {
      parts.add(
          'Bataryanızda orta düzeyde yıpranma var (%$batteryHealth). Piliniz hâlâ kullanılabilir durumda ancak ileride değişim gerekebilir.');
    } else {
      parts.add(
          'Bataryanız ciddi şekilde yıpranmış (%$batteryHealth). Pil değişimi düşünmenizi öneririz.');
    }

    if (batteryTemperature > 38) {
      parts.add(
          'Cihaz sıcaklığınız (${batteryTemperature.toStringAsFixed(0)}°C) normalin üzerinde. Arka plan uygulamalarını kapatarak sıcaklığı düşürebilirsiniz.');
    }

    if (usedStoragePercent > 85) {
      parts.add(
          'Depolama alanınız %${usedStoragePercent.toStringAsFixed(0)} dolu. Gereksiz dosyaları temizleyerek cihazınızın performansını artırabilirsiniz.');
    } else {
      parts.add(
          'Depolama alanınızda yeterli boş yer var ($freeStorage boş). Cihazınız depolama açısından sağlıklı.');
    }

    if (batteryLevel < 20) {
      parts.add(
          'Batarya seviyeniz düşük (%$batteryLevel). En kısa sürede şarj etmenizi öneririz.');
    }

    final result = parts.join(' ');
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
