import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart';
import 'api_config.dart';
import 'organizator_ekrani.dart';
import 'yeni_etkinlik_ekrani.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'giris_ekrani.dart';

class OrganizatorPaneli extends StatefulWidget {
  const OrganizatorPaneli({super.key});

  @override
  State<OrganizatorPaneli> createState() => _OrganizatorPaneliState();
}

class _OrganizatorPaneliState extends State<OrganizatorPaneli> {
  List<dynamic> etkinlikler = [];
  List<dynamic> bekleyenTalepler = [];
  int aktifKulupId = 0;
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    etkinlikleriGetir();
  }

  Future<void> etkinlikleriGetir() async {
    try {
      final url = Uri.parse(ApiConfig.etkinlikBase);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        if (data.isNotEmpty) {
          aktifKulupId = data.first['kulupId'] ?? data.first['kulupID'] ?? 0;
          if (aktifKulupId != 0) {
            try {
              final tResponse = await http.get(Uri.parse(ApiConfig.bekleyenTalepler(aktifKulupId)));
              if (tResponse.statusCode == 200) {
                bekleyenTalepler = json.decode(tResponse.body);
              }
            } catch (e) {
              debugPrint('Talep Listeleme Hatası: $e');
            }
          }
        }
        if (mounted) {
          setState(() {
            etkinlikler = data;
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

  // Etkinliği bitirme fonksiyonu — onay dialoglu
  Future<void> etkinligiBitirOnay(int id, String etkinlikAdi) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: KampusEtkinlikApp.kKartRengi,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_rounded, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Etkinliği Bitir', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                children: [
                  TextSpan(text: '"$etkinlikAdi"', style: const TextStyle(fontWeight: FontWeight.bold, color: KampusEtkinlikApp.kIkincilRenk)),
                  const TextSpan(text: ' etkinliğini bitirmek istediğinize emin misiniz?'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Yoklaması alınmış tüm katılımcılara otomatik sertifika gönderilecek.',
                      style: TextStyle(color: Colors.amber, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('VAZGEÇ', style: TextStyle(color: KampusEtkinlikApp.kSolukYazi)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.red, Color(0xFFD32F2F)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.stop_circle_rounded, color: Colors.white, size: 20),
              label: const Text('BİTİR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context, true),
            ),
          ),
        ],
      ),
    );

    if (onay == true) {
      await _etkinligiBitir(id);
    }
  }

  Future<void> _etkinligiBitir(int id) async {
    try {
      final url = Uri.parse(ApiConfig.etkinlikBitir(id));
      final response = await http.post(url);

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.celebration_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Etkinlik bitirildi! Sertifikalar katılımcılara gönderildi. 🎉')),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() { yukleniyor = true; });
        etkinlikleriGetir();
      }
    } catch (e) {
      debugPrint('Hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Etkinlik bitirilemedi. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String tAd = "Kampüs Yönetimi";
    double tPuan = 5.0;
    if (etkinlikler.isNotEmpty) {
      tAd = etkinlikler.first["kulupAdi"] ?? "Kampüs Yönetimi";
      final p = etkinlikler.first["kulupPuan"];
      if (p != null) tPuan = double.tryParse(p.toString()) ?? 5.0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ORGANİZATÖR PANELİ', style: TextStyle(fontSize: 16)),
            Row(
              children: [
                const Icon(Icons.group_work_rounded, size: 14, color: Colors.purpleAccent),
                const SizedBox(width: 4),
                Text(tAd, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(width: 8),
                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                Text(' $tPuan', style: const TextStyle(fontSize: 12, color: Colors.amber)),
              ],
            )
          ],
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.people_alt_rounded, color: Colors.amber),
                  tooltip: 'Üyelik Talepleri',
                  onPressed: () => _uyelikTalepleriModaliAc(aktifKulupId),
                ),
                if (bekleyenTalepler.isNotEmpty)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      child: Text(
                        '${bekleyenTalepler.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.campaign_rounded, color: Colors.purpleAccent),
              tooltip: 'Duyuru Yayınla',
              onPressed: () => _duyuruGonderModaliAc(tAd),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              tooltip: 'Çıkış Yap',
              onPressed: _cikisYap,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.purpleAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.purpleAccent),
              tooltip: 'Yenile',
              onPressed: () {
                setState(() { yukleniyor = true; });
                etkinlikleriGetir();
              },
            ),
          ),
        ],
      ),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator(color: KampusEtkinlikApp.kIkincilRenk))
          : etkinlikler.isEmpty
              ? _buildBosListe()
              : RefreshIndicator(
                  color: KampusEtkinlikApp.kIkincilRenk,
                  onRefresh: etkinlikleriGetir,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: etkinlikler.length,
                    itemBuilder: (context, index) {
                      return _buildEtkinlikKarti(etkinlikler[index], index);
                    },
                  ),
                ),

      // Yeni Etkinlik FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final basariliMi = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const YeniEtkinlikEkrani()),
          );
          if (basariliMi == true) {
            setState(() { yukleniyor = true; });
            etkinlikleriGetir();
          }
        },
        backgroundColor: Colors.purpleAccent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('YENİ ETKİNLİK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }

  Future<void> _cikisYap() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const GirisEkrani()));
  }

  void _uyelikTalepleriModaliAc(int kulupId) {
    if (kulupId == 0) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            expand: false,
            builder: (_, scrollController) => Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 20),
                const Text(
                  'ÜYELİK TALEPLERİ',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: bekleyenTalepler.isEmpty
                      ? const Center(child: Text('Bekleyen talep bulunmuyor.', style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: bekleyenTalepler.length,
                          itemBuilder: (context, index) {
                            final talep = bekleyenTalepler[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2D3E),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.amber.withOpacity(0.3)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), shape: BoxShape.circle),
                                  child: const Icon(Icons.person, color: Colors.amber),
                                ),
                                title: Text(talep["kullaniciAdSoyad"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: const Text('Topluluğuna katılmak istiyor', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                                      onPressed: () async {
                                        await http.post(Uri.parse(ApiConfig.talepYanitla(talep["uyelikId"], false)));
                                        setModalState(() {
                                          bekleyenTalepler.removeAt(index);
                                        });
                                        setState(() {});
                                      },
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.check_rounded, color: Colors.greenAccent),
                                        onPressed: () async {
                                          await http.post(Uri.parse(ApiConfig.talepYanitla(talep["uyelikId"], true)));
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('${talep["kullaniciAdSoyad"]} onaylandı!'), backgroundColor: Colors.green)
                                            );
                                          }
                                          setModalState(() {
                                            bekleyenTalepler.removeAt(index);
                                          });
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _duyuruGonderModaliAc(String kulupAdi) {
    final TextEditingController mesajController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.campaign_rounded, color: Colors.purpleAccent),
            SizedBox(width: 8),
            Text('Duyuru Yayınla', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: TextField(
          controller: mesajController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Öğrencilerinize ne söylemek istersiniz?',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF2A2D3E),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (mesajController.text.trim().isEmpty) return;
              Navigator.pop(context);
              
              // Backend API'ye POST et
              try {
                final response = await http.post(
                  Uri.parse(ApiConfig.duyuruBase),
                  headers: {"Content-Type": "application/json"},
                  body: json.encode({
                    "kulupAdi": kulupAdi,
                    "mesaj": mesajController.text.trim(),
                  })
                );
                
                if (response.statusCode == 200 && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Duyuru başarıyla yayınlandı!'), backgroundColor: Colors.green)
                  );
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red)
                );
              }
            },
            child: const Text('YAYINLA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEtkinlikKarti(dynamic etkinlik, int index) {
    final int katilimci = etkinlik["katilimciSayisi"] ?? 0;
    int etkinlikId = etkinlik["etkinlikId"] ?? 1;

    List<List<Color>> gradients = [
      [Colors.cyanAccent, Colors.blueAccent],
      [Colors.orangeAccent, Colors.redAccent],
      [Colors.purpleAccent, Colors.deepPurpleAccent],
    ];
    List<Color> gradient = gradients[index % gradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2), // Çerçeve kalınlığı
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141416),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Opacity(
                opacity: 0.15,
                child: Image.network(
                  'https://loremflickr.com/400/200/technology,software,computer?lock=$etkinlikId',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: gradient[0].withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.campaign_rounded, color: gradient[0], size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          etkinlik["etkinlikAdi"],
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_rounded, color: gradient[0], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Katılımcı: $katilimci',
                          style: TextStyle(color: gradient[0], fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      // Yoklama Al butonu
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradient),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                              label: const Text('YOKLAMA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizatorEkrani()));
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Bitir butonu
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.stop_circle_rounded, color: Colors.redAccent, size: 20),
                          label: const Text('BİTİR', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withOpacity(0.1),
                            shadowColor: Colors.transparent,
                            side: const BorderSide(color: Colors.redAccent, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () {
                            etkinligiBitirOnay(etkinlikId, etkinlik["etkinlikAdi"]);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KampusEtkinlikApp.kKartRengi,
              ),
              child: const Icon(Icons.event_busy_rounded, size: 64, color: KampusEtkinlikApp.kSolukYazi),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aktif etkinlik yok',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Yeni bir etkinlik oluşturmak için sağ alttaki butonu kullanın.',
              style: TextStyle(color: KampusEtkinlikApp.kSolukYazi, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}