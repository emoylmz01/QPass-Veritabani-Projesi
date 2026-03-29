import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Tüm API URL'lerinin merkezi yönetim sınıfı.
/// URL değiştiğinde sadece burayı güncellemeniz yeterli.
class ApiConfig {
  // Telefon Wi-Fi IP adresi (telefonla test ederken güncelle)
  static const String _telefonIp = '10.61.47.185';

  /// Platform bazlı otomatik base URL seçimi
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5079/api';
    }
    if (Platform.isAndroid) {
      // Gerçek telefon Wi-Fi IP Adresi:
      return 'http://$_telefonIp:5079/api';
    }
    // Windows, iOS, macOS, Linux → localhost
    return 'http://127.0.0.1:5079/api';
  }

  // Kullanıcı endpointleri
  static String get kullaniciBase => '$_baseUrl/Kullanici';
  static String get kayitOl => '$kullaniciBase/KayitOl';
  static String get girisYap => '$kullaniciBase/GirisYap';

  static String kullanici(int id) => '$kullaniciBase/$id';

  // Etkinlik endpointleri
  static String get etkinlikBase => '$_baseUrl/Etkinlik';
  static String get etkinlikEkle => '$etkinlikBase/Ekle';
  static String get etkinlikKayitOl => '$etkinlikBase/KayitOl';
  static String get yoklamaAl => '$etkinlikBase/YoklamaAl';

  // Dinamik URL üreticiler
  static String etkinlikBitir(int id) => '$etkinlikBase/Bitir/$id';
  static String sertifikalarim(int kullaniciId) => '$etkinlikBase/Sertifikalarim/$kullaniciId';
  static String gecmisEtkinliklerim(int kullaniciId) => '$etkinlikBase/GecmisEtkinliklerim/$kullaniciId';

  // Duyuru endpointleri
  static String get duyuruBase => '$_baseUrl/Duyuru';

  // Kulüp üyelik endpointleri
  static String get uyelikBase => '$_baseUrl/KulupUyelik';
  static String basvuruYap(int kullaniciId, int kulupId) => '$uyelikBase/BasvuruYap/$kullaniciId/$kulupId';
  static String uyeOlduguKulupler(int kullaniciId) => '$uyelikBase/UyeOlduguKulupler/$kullaniciId';
  static String bekleyenTalepler(int kulupId) => '$uyelikBase/BekleyenTalepler/$kulupId';
  static String talepYanitla(int uyelikId, bool kabulMu) => '$uyelikBase/TalepYanitla/$uyelikId/$kabulMu';
}
