import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'api_config.dart';

class YeniEtkinlikEkrani extends StatefulWidget {
  const YeniEtkinlikEkrani({super.key});

  @override
  State<YeniEtkinlikEkrani> createState() => _YeniEtkinlikEkraniState();
}

class _YeniEtkinlikEkraniState extends State<YeniEtkinlikEkrani> {
  final adController = TextEditingController();
  final konumController = TextEditingController();
  final aciklamaController = TextEditingController();
  bool yukleniyor = false;
  bool sertifikaliMi = true;
  DateTime? secilenTarih;
  TimeOfDay? secilenSaat;

  @override
  void dispose() {
    adController.dispose();
    konumController.dispose();
    aciklamaController.dispose();
    super.dispose();
  }

  Future<void> tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: KampusEtkinlikApp.kIkincilRenk,
              surface: KampusEtkinlikApp.kKartRengi,
            ),
          ),
          child: child!,
        );
      },
    );
    if (secilen != null) {
      setState(() { secilenTarih = secilen; });
    }
  }

  Future<void> saatSec() async {
    final secilen = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: KampusEtkinlikApp.kIkincilRenk,
              surface: KampusEtkinlikApp.kKartRengi,
            ),
          ),
          child: child!,
        );
      },
    );
    if (secilen != null) {
      setState(() { secilenSaat = secilen; });
    }
  }

  Future<void> etkinlikKaydet() async {
    if (adController.text.trim().isEmpty || konumController.text.trim().isEmpty) {
      _mesajGoster('Etkinlik adı ve konum zorunludur!', Colors.orange);
      return;
    }

    setState(() { yukleniyor = true; });

    try {
      final url = Uri.parse(ApiConfig.etkinlikEkle);

      // Tarih: seçildiyse onu kullan, yoksa şu anı kullan
      DateTime etkinlikTarihi = secilenTarih ?? DateTime.now();
      if (secilenSaat != null) {
        etkinlikTarihi = DateTime(etkinlikTarihi.year, etkinlikTarihi.month, etkinlikTarihi.day, secilenSaat!.hour, secilenSaat!.minute);
      }

      Map<String, dynamic> body = {
        "EtkinlikAdi": adController.text.trim(),
        "Konum": konumController.text.trim(),
        "TarihSaat": etkinlikTarihi.toIso8601String(),
        "Kontenjan": 100,
        "SertifikaliMi": sertifikaliMi,
        "AktifMi": true,
      };

      if (aciklamaController.text.trim().isNotEmpty) {
        body["Aciklama"] = aciklamaController.text.trim();
      }

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      debugPrint('Etkinlik Yanıt [${response.statusCode}]: ${response.body}');

      if (response.statusCode == 200) {
        if (mounted) {
          _mesajGoster('Etkinlik başarıyla yayınlandı! 🎉', Colors.green);
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          try {
            final hata = json.decode(response.body);
            _mesajGoster(hata["Mesaj"] ?? hata["mesaj"] ?? hata["title"] ?? 'Etkinlik kaydedilemedi!', Colors.red);
          } catch (_) {
            _mesajGoster('Hata: Etkinlik kaydedilemedi! (${response.statusCode})', Colors.red);
          }
        }
      }
    } catch (e) {
      debugPrint('Etkinlik Hata: $e');
      if (mounted) _mesajGoster('Sunucuya bağlanılamıyor!', Colors.red);
    }

    if (mounted) setState(() { yukleniyor = false; });
  }

  void _mesajGoster(String mesaj, Color renk) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: renk,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YENİ ETKİNLİK'),
        backgroundColor: KampusEtkinlikApp.kArkaPlanRengi,
        foregroundColor: KampusEtkinlikApp.kIkincilRenk,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ikonu
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: KampusEtkinlikApp.kIkincilRenk.withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.campaign_rounded, size: 56, color: KampusEtkinlikApp.kIkincilRenk),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Yeni bir etkinlik oluşturun',
                style: TextStyle(color: KampusEtkinlikApp.kSolukYazi, fontSize: 14),
              ),
            ),
            const SizedBox(height: 28),

            // Etkinlik Adı
            _buildLabel('Etkinlik Adı *'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: adController,
              ikon: Icons.event_rounded,
              ipucu: 'Örn: Siber Güvenlik Zirvesi',
            ),
            const SizedBox(height: 20),

            // Konum
            _buildLabel('Konum *'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: konumController,
              ikon: Icons.location_on_rounded,
              ipucu: 'Örn: Mühendislik Fakültesi Z-10',
            ),
            const SizedBox(height: 20),

            // Tarih ve Saat seçiciler
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Tarih'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: tarihSec,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: KampusEtkinlikApp.kKartRengi,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: KampusEtkinlikApp.kIkincilRenk, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  secilenTarih != null
                                      ? '${secilenTarih!.day.toString().padLeft(2, '0')}.${secilenTarih!.month.toString().padLeft(2, '0')}.${secilenTarih!.year}'
                                      : 'Tarih Seç',
                                  style: TextStyle(
                                    color: secilenTarih != null ? Colors.white : KampusEtkinlikApp.kSolukYazi,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Saat'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: saatSec,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: KampusEtkinlikApp.kKartRengi,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, color: KampusEtkinlikApp.kIkincilRenk, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  secilenSaat != null
                                      ? '${secilenSaat!.hour.toString().padLeft(2, '0')}:${secilenSaat!.minute.toString().padLeft(2, '0')}'
                                      : 'Saat Seç',
                                  style: TextStyle(
                                    color: secilenSaat != null ? Colors.white : KampusEtkinlikApp.kSolukYazi,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Sertifikalı Etkinlik Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: KampusEtkinlikApp.kKartRengi,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: sertifikaliMi ? Colors.amber.withValues(alpha: 0.4) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: sertifikaliMi ? Colors.amber : KampusEtkinlikApp.kSolukYazi,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sertifikalı Etkinlik', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          sertifikaliMi ? 'Katılımcılara sertifika verilecek' : 'Sertifika verilmeyecek',
                          style: const TextStyle(color: KampusEtkinlikApp.kSolukYazi, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: sertifikaliMi,
                    onChanged: (v) => setState(() => sertifikaliMi = v),
                    activeThumbColor: Colors.amber,
                    activeTrackColor: Colors.amber.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildLabel('Açıklama (Opsiyonel)'),
            const SizedBox(height: 8),
            TextField(
              controller: aciklamaController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Etkinlik hakkında kısa bir açıklama yazın...',
                hintStyle: const TextStyle(color: KampusEtkinlikApp.kSolukYazi),
                filled: true,
                fillColor: KampusEtkinlikApp.kKartRengi,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: KampusEtkinlikApp.kIkincilRenk, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 36),

            // Yayınla butonu
            SizedBox(
              width: double.infinity,
              height: 54,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8F00)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: KampusEtkinlikApp.kIkincilRenk.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: yukleniyor
                      ? const SizedBox.shrink()
                      : const Icon(Icons.publish_rounded, color: Colors.white),
                  label: yukleniyor
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text(
                          'ETKİNLİĞİ YAYINLA',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: yukleniyor ? null : etkinlikKaydet,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData ikon,
    required String ipucu,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(ikon, color: KampusEtkinlikApp.kIkincilRenk),
        hintText: ipucu,
        hintStyle: const TextStyle(color: KampusEtkinlikApp.kSolukYazi),
        filled: true,
        fillColor: KampusEtkinlikApp.kKartRengi,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KampusEtkinlikApp.kIkincilRenk, width: 1.5),
        ),
      ),
    );
  }
}