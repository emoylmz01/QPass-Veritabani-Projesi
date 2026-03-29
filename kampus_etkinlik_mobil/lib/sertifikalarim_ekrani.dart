import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'api_config.dart';
import 'sertifika_pdf.dart';

class SertifikalarimEkrani extends StatefulWidget {
  final int aktifKullaniciId;
  const SertifikalarimEkrani({super.key, required this.aktifKullaniciId});

  @override
  State<SertifikalarimEkrani> createState() => _SertifikalarimEkraniState();
}

class _SertifikalarimEkraniState extends State<SertifikalarimEkrani> {
  List<dynamic> sertifikalar = [];
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    sertifikalariGetir();
  }

  Future<void> sertifikalariGetir() async {
    try {
      final url = Uri.parse(ApiConfig.sertifikalarim(widget.aktifKullaniciId));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            sertifikalar = json.decode(response.body);
            yukleniyor = false;
          });
        }
      } else {
        if (mounted) setState(() { yukleniyor = false; });
      }
    } catch (e) {
      debugPrint('Bağlantı Hatası: $e');
      if (mounted) setState(() { yukleniyor = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SERTİFİKALARIM'),
        foregroundColor: Colors.amber,
      ),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : sertifikalar.isEmpty
              ? _buildBosListe()
              : RefreshIndicator(
                  color: Colors.amber,
                  onRefresh: sertifikalariGetir,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sertifikalar.length,
                    itemBuilder: (context, index) {
                      return _buildSertifikaKarti(sertifikalar[index], index);
                    },
                  ),
                ),
    );
  }

  Widget _buildSertifikaKarti(dynamic s, int index) {
    final rawDate = s["uretimTarihi"] ?? "";
    final String tarih = rawDate.length > 10 ? rawDate.substring(0, 10) : rawDate;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KampusEtkinlikApp.kKartRengi,
            KampusEtkinlikApp.kKartRengi.withValues(alpha: 0.8),
          ],
        ),
        border: Border.all(
          width: 2,
          color: Colors.amber.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Üst dekoratif çizgi
            Container(
              width: 60,
              height: 4,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.amber, Color(0xFFFFD54F)]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Madalya ikonu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.amber.withValues(alpha: 0.2), Colors.amber.withValues(alpha: 0.05)],
                ),
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 52),
            ),
            const SizedBox(height: 12),

            // Başlık
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.amber, Color(0xFFFFD54F)],
              ).createShader(bounds),
              child: const Text(
                'KATILIM SERTİFİKASI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Etkinlik adı
            Text(
              s["etkinlikAdi"],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),

            // Ayırıcı
            Row(
              children: [
                Expanded(child: Container(height: 1, color: Colors.amber.withValues(alpha: 0.2))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.star_rounded, color: Colors.amber.withValues(alpha: 0.5), size: 16),
                ),
                Expanded(child: Container(height: 1, color: Colors.amber.withValues(alpha: 0.2))),
              ],
            ),
            const SizedBox(height: 14),

            // Tarih ve Kod
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: Colors.grey.shade400, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      tarih.isNotEmpty ? tarih : 'Tarih yok',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: KampusEtkinlikApp.kBirincilRenk.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: KampusEtkinlikApp.kBirincilRenk.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${s["sertifikaKodu"]}',
                    style: const TextStyle(
                      color: KampusEtkinlikApp.kBirincilRenk,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // PDF İndir Butonu
            SizedBox(
              width: double.infinity,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.amber, Color(0xFFFFD54F)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download_rounded, color: Color(0xFF1A1A2E), size: 20),
                  label: const Text(
                    'PDF OLARAK İNDİR',
                    style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    SertifikaPdf.olusturVeIndir(
                      etkinlikAdi: s["etkinlikAdi"] ?? 'Etkinlik',
                      sertifikaKodu: s["sertifikaKodu"] ?? '',
                      tarih: tarih,
                      konum: s["konum"],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBosListe() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KampusEtkinlikApp.kKartRengi,
              ),
              child: const Icon(Icons.emoji_events_outlined, size: 64, color: KampusEtkinlikApp.kSolukYazi),
            ),
            const SizedBox(height: 24),
            const Text(
              'Henüz sertifikanız yok',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Etkinliklere katılıp yoklama yaptırdığınızda\nsertifikalarınız burada görünecek.',
              style: TextStyle(color: KampusEtkinlikApp.kSolukYazi, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}