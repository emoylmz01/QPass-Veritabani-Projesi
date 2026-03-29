import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'main.dart';
import 'api_config.dart';
import 'sertifikalarim_ekrani.dart';
import 'qr_tarayici.dart';

class OgrenciEkrani extends StatefulWidget {
  final int aktifKullaniciId;
  const OgrenciEkrani({super.key, required this.aktifKullaniciId});

  @override
  State<OgrenciEkrani> createState() => _OgrenciEkraniState();
}

class _OgrenciEkraniState extends State<OgrenciEkrani> {
  List<dynamic> aktifEtkinlikler = [];
  List<dynamic> gecmisEtkinlikler = [];
  List<dynamic> uyeKulupler = [];
  Map<String, dynamic>? profilBilgisi;
  bool aktifYukleniyor = true;
  bool gecmisYukleniyor = true;
  bool profilYukleniyor = true;

  int _seciliSekme = 1; // 0: Keşfet, 1: Yaklaşanlar, 2: Etkinliklerim
  int _seciliAltSekme = 0; // Alt navbar indeksi
  String _aramaMetni = "";
  
  List<dynamic> get filtrelenmisAktifEtkinlikler {
    final liste = aktifEtkinlikler.where((e) {
      final ad = (e["etkinlikAdi"] ?? "").toString().toLowerCase();
      final arama = _aramaMetni.toLowerCase();
      return ad.contains(arama);
    }).toList();
    
    final profilKulupIdleri = uyeKulupler.map((k) => k["kulupId"]).toList();
        
    if (_seciliSekme == 0) {
      // Keşfet: Kullanıcının üye OLMADIĞI kulüpler veya geneli
      if (profilKulupIdleri.isEmpty) return liste;
      return liste.where((e) => !profilKulupIdleri.contains(e["kulupId"] ?? e["kulupID"])).toList();
    } else if (_seciliSekme == 1) {
      // Yaklaşanlar: Kullanıcının üye OLDUĞU kulüpler
      if (profilKulupIdleri.isEmpty) return [];
      return liste.where((e) => profilKulupIdleri.contains(e["kulupId"] ?? e["kulupID"])).toList();
    }
    return liste;
  }
  
  List<dynamic> get filtrelenmisGecmisEtkinlikler {
    return gecmisEtkinlikler.where((e) {
      final ad = (e["etkinlikAdi"] ?? "").toString().toLowerCase();
      final arama = _aramaMetni.toLowerCase();
      return ad.contains(arama);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    profilGetir();
    etkinlikleriGetir();
    gecmisEtkinlikleriGetir();
  }

  Future<void> profilGetir() async {
    try {
      final url = Uri.parse(ApiConfig.kullanici(widget.aktifKullaniciId));
      final response = await http.get(url);

      final kulupUrl = Uri.parse(ApiConfig.uyeOlduguKulupler(widget.aktifKullaniciId));
      final kulupRes = await http.get(kulupUrl);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            profilBilgisi = json.decode(response.body);
            if (kulupRes.statusCode == 200) {
              uyeKulupler = json.decode(kulupRes.body);
            }
            profilYukleniyor = false;
          });
        }
      } else {
        if (mounted) setState(() => profilYukleniyor = false);
      }
    } catch (e) {
      if (mounted) setState(() => profilYukleniyor = false);
    }
  }

  Future<void> etkinlikleriGetir() async {
    try {
      final url = Uri.parse(ApiConfig.etkinlikBase);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            aktifEtkinlikler = json.decode(response.body);
            aktifYukleniyor = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Bağlantı Hatası: $e');
      if (mounted) setState(() { aktifYukleniyor = false; });
    }
  }

  Future<void> gecmisEtkinlikleriGetir() async {
    try {
      final url = Uri.parse(ApiConfig.gecmisEtkinliklerim(widget.aktifKullaniciId));
      final response = await http.get(url);

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            gecmisEtkinlikler = json.decode(response.body);
            gecmisYukleniyor = false;
          });
        }
      } else {
        final sertUrl = Uri.parse(ApiConfig.sertifikalarim(widget.aktifKullaniciId));
        final sertResponse = await http.get(sertUrl);
        if (sertResponse.statusCode == 200 && mounted) {
          setState(() {
            gecmisEtkinlikler = json.decode(sertResponse.body);
            gecmisYukleniyor = false;
          });
        } else {
          if (mounted) setState(() { gecmisYukleniyor = false; });
        }
      }
    } catch (e) {
      debugPrint('Geçmiş etkinlik hatası: $e');
      if (mounted) setState(() { gecmisYukleniyor = false; });
    }
  }

  Future<void> kayitOlVeQrGoster(int etkinlikId, String etkinlikAdi) async {
    try {
      final url = Uri.parse(ApiConfig.etkinlikKayitOl);
      await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "ogrenciID": widget.aktifKullaniciId,
          "etkinlikID": etkinlikId,
        }),
      );

      String qrVeri = "${widget.aktifKullaniciId}-$etkinlikId";

      if (!mounted) return;
      
      // Puan artti bilgisini ekle
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber),
              const SizedBox(width: 8),
              const Expanded(child: Text('Başarıyla kayıt olundu! Puan hanenize eklendi! 🎉')),
            ]
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        )
      );

      // Profil bilgisini güncelle (Puan arttığını görmek için)
      profilGetir();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E), // Koyu arka plan
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Colors.purpleAccent, width: 1),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Kayıt Başarılı!',
                  style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$etkinlikAdi için yeriniz ayrıldı.',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Etkinlik kapısında aşağıdaki QR kodu okutun.',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(data: qrVeri, version: QrVersions.auto, backgroundColor: Colors.white),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('KAPAT', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Kayıt Hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Kayıt sırasında bir hata oluştu.'),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Çok koyu zemin
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomAppBar(),
            _buildSearchBar(),
            _buildTabs(),
            Expanded(
              child: _buildIcerik(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCustomAppBar() {
    String initials = "Q";
    if (profilBilgisi != null) {
      final ad = profilBilgisi!['ad'] ?? '';
      final soyad = profilBilgisi!['soyad'] ?? '';
      initials = '${ad.isNotEmpty ? ad[0] : ''}${soyad.isNotEmpty ? soyad[0] : ''}';
      if (initials.isEmpty) initials = "Q";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo
          const Row(
            children: [
              Text(
                'Q-Pass ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Icon(Icons.bolt_rounded, color: Colors.purpleAccent, size: 28),
            ],
          ),
          // Aksiyonlar
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_active_rounded, color: Colors.purpleAccent),
                onPressed: _bildirimleriAc,
              ),
              GestureDetector(
                onTap: _kullaniciMenusuAc,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade900,
                    border: Border.all(color: Colors.purpleAccent.withOpacity(0.8), width: 2),
                  ),
                  child: Center(
                    child: Text(
                      initials.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(25),
        ),
        child: TextField(
          onChanged: (deger) {
            setState(() {
              _aramaMetni = deger;
            });
          },
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Etkinlikleri, kulüpleri ara...',
            hintStyle: TextStyle(color: Colors.white38),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.white54),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    List<String> sekmeler = ['Keşfet', 'Yaklaşanlar', 'Etkinliklerim'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(sekmeler.length, (index) {
          bool secili = _seciliSekme == index;
          return GestureDetector(
            onTap: () => setState(() => _seciliSekme = index),
            child: Column(
              children: [
                Text(
                  sekmeler[index],
                  style: TextStyle(
                    color: secili ? Colors.white : Colors.white54,
                    fontSize: 15,
                    fontWeight: secili ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 6),
                if (secili)
                  Container(
                    width: sekmeler[index].length * 6.0,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purpleAccent.withOpacity(0.6),
                          blurRadius: 8,
                        )
                      ]
                    ),
                  ),
                if (!secili) const SizedBox(height: 3),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildIcerik() {
    if (_seciliSekme == 0 || _seciliSekme == 1) {
      if (aktifYukleniyor) return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
      
      final liste = filtrelenmisAktifEtkinlikler;
      if (liste.isEmpty) return _buildBosListe(_aramaMetni.isNotEmpty ? 'Aramanıza uygun etkinlik bulunamadı.' : (_seciliSekme == 0 ? 'Keşfedilecek yeni etkinlik yok.' : 'Kayıtlı topluluklarınızda yaklaşan etkinlik yok.'), Icons.event_busy_rounded);
      
      return RefreshIndicator(
        color: Colors.purpleAccent,
        onRefresh: etkinlikleriGetir,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: liste.length,
          itemBuilder: (context, index) {
            final etkinlik = liste[index];
            return _buildNeonCard(etkinlik, index, aktifMi: true);
          },
        ),
      );
    } else {
      if (gecmisYukleniyor) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
      
      final liste = filtrelenmisGecmisEtkinlikler;
      if (liste.isEmpty) return _buildBosListe(_aramaMetni.isNotEmpty ? 'Aramanıza uygun geçmiş etkinlik bulunamadı.' : 'Geçmiş etkinlik bulunamadı.', Icons.history_rounded);
      
      return RefreshIndicator(
        color: Colors.cyanAccent,
        onRefresh: gecmisEtkinlikleriGetir,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: liste.length,
          itemBuilder: (context, index) {
            final etkinlik = liste[index];
            return _buildNeonCard(etkinlik, index, aktifMi: false);
          },
        ),
      );
    }
  }

  Widget _buildNeonCard(dynamic etkinlik, int index, {required bool aktifMi}) {
    List<List<Color>> gradients = [
      [Colors.cyanAccent, Colors.blueAccent],
      [Colors.purpleAccent, Colors.deepPurpleAccent],
      [Colors.orangeAccent, Colors.redAccent],
    ];
    List<Color> gradient = gradients[index % gradients.length];
    
    String ad = etkinlik["etkinlikAdi"] ?? "Gizemli Etkinlik";
    String rawDate = etkinlik["uretimTarihi"] ?? etkinlik["tarih"] ?? "";
    String tarih = "Belirtilmemiş";
    if (rawDate.length > 10) {
       tarih = rawDate.substring(0, 16).replaceAll('T', ' | ');
    } else if (rawDate.isNotEmpty) {
       tarih = rawDate;
    }
    String konum = etkinlik["konum"] ?? "Kampüs İçi";
    String rozet = etkinlik["kulupAdi"] ?? "KAMPÜS";
    int katilimcilar = etkinlik["katilimciSayisi"] ?? 0;
    int etkinlikId = etkinlik["etkinlikId"] ?? 1;

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
            // Arka plan fotoğraf efekti - Teknoloji Temalı
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: gradient[0].withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          rozet,
                          style: TextStyle(color: gradient[0], fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.favorite_border_rounded, color: Colors.white54, size: 22),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ad,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Colors.white54, size: 14),
                      const SizedBox(width: 6),
                      Text(tarih, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white54, size: 14),
                      const SizedBox(width: 6),
                      Text(konum, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Bu harika etkinlikte yerinizi ayırtın, kampüs hayatının tadını çıkarın!",
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Katılımcı Avatarları
                      Row(
                        children: [
                          _buildMiniAvatar(Colors.redAccent),
                          Transform.translate(offset: const Offset(-10, 0), child: _buildMiniAvatar(Colors.blueAccent)),
                          Transform.translate(offset: const Offset(-20, 0), child: _buildMiniAvatar(Colors.greenAccent)),
                          Transform.translate(
                            offset: const Offset(-25, 0),
                            child: Text('  $katilimcilar Katılıyor', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          )
                        ],
                      ),
                      if (aktifMi)
                        ElevatedButton(
                          onPressed: () {
                            final int id = etkinlik["etkinlikId"] ?? etkinlik["etkinlikID"] ?? etkinlik["id"];
                            kayitOlVeQrGoster(id, ad);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purpleAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 8,
                            shadowColor: Colors.purpleAccent,
                          ),
                          child: const Text('KATIL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                          ),
                          child: const Text('KATILILDI', style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                        )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniAvatar(Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: const Color(0xFF141416), width: 2),
      ),
      child: const Icon(Icons.person, size: 14, color: Colors.white),
    );
  }

  Widget _buildBosListe(String mesaj, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.white24),
          const SizedBox(height: 16),
          Text(mesaj, style: const TextStyle(color: Colors.white54, fontSize: 16)),
        ],
      ),
    );
  }

  void _kullaniciMenusuAc() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            if (profilBilgisi != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Builder(
                  builder: (context) {
                    int puan = profilBilgisi!['oyunlastirmaPuani'] ?? 0;
                    String seviyeAd = puan < 50 ? "Çaylak Üye" : (puan < 150 ? "Aktif Kampüslü" : "Elit Organizatör");
                    double progress = puan < 50 ? puan / 50.0 : (puan < 150 ? (puan - 50) / 100.0 : 1.0);
                    int hedef = puan < 50 ? 50 : (puan < 150 ? 150 : puan);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                                const SizedBox(width: 12),
                                Text(
                                  seviyeAd,
                                  style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Text(
                              '$puan / $hedef Puan',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white10,
                            color: Colors.amber,
                            minHeight: 8,
                          ),
                        ),
                        if (uyeKulupler.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text('Üye Olduğum Topluluklar', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...uyeKulupler.map((k) => ListTile(
                            leading: const Icon(Icons.group_work_rounded, color: Colors.purpleAccent),
                            title: Text(k["kulupAdi"], style: const TextStyle(color: Colors.white)),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          )),
                        ]
                      ],
                    );
                  }
                ),
              ),
            ],
            ListTile(
              leading: const Icon(Icons.workspace_premium_rounded, color: Colors.amber),
              title: const Text('Sertifikalarım', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => SertifikalarimEkrani(aktifKullaniciId: widget.aktifKullaniciId)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('kullaniciId');
                await prefs.remove('kullaniciRol');
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const AnaEkran()), (route) => false);
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      )
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F0F),
        border: Border(top: BorderSide(color: Colors.white10, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_filled, 'Ana Sayfa', 0),
          _buildNavItem(Icons.search_rounded, 'Keşfet', 1, isColored: true),
          _buildNavItem(Icons.groups_rounded, 'Topluluklar', 2),
          _buildNavItem(Icons.person_outline_rounded, 'Profil', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, {bool isColored = false, bool showBadge = false}) {
    bool isSelected = _seciliAltSekme == index;
    Color color = isSelected || isColored ? Colors.purpleAccent : Colors.white54;
    return GestureDetector(
      onTap: () async {
        setState(() => _seciliAltSekme = index);
        if (index == 0 || index == 1) {
          setState(() => _seciliSekme = 0); // Keşfet sekmesine geç
        } else if (index == 2) {
          _topluluklarMenusuAc();
        } else if (index == 3) {
          _kullaniciMenusuAc();
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
          if (showBadge)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
              )
            )
        ],
      ),
    );
  }

  void _topluluklarMenusuAc() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
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
              'YENİ TOPLULUK KEŞFET',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Builder(
                builder: (context) {
                  Map<int, dynamic> kuluplerMap = {};
                  for(var e in aktifEtkinlikler) {
                    int id = e["kulupId"] ?? e["kulupID"] ?? 0;
                    if(id != 0 && !kuluplerMap.containsKey(id)) { kuluplerMap[id] = {"id": id, "adi": e["kulupAdi"], "puan": e["kulupPuan"]}; }
                  }
                  List<dynamic> ulasilabilirKulupler = kuluplerMap.values.toList();
                  
                  if (ulasilabilirKulupler.isEmpty) {
                    return const Center(child: Text("Henüz aktif bir topluluk yok.", style: TextStyle(color: Colors.white54)));
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: ulasilabilirKulupler.length,
                    itemBuilder: (context, index) {
                      final kulup = ulasilabilirKulupler[index];
                      // Zaten üye miyiz kontrolü
                      bool uyeMiyiz = uyeKulupler.any((k) => k["kulupId"] == kulup["id"]);
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2D3E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.group_work_rounded, color: Colors.purpleAccent),
                          ),
                          title: Text(kulup["adi"], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('Değerlendirme: ${kulup["puan"] ?? 5.0}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          trailing: uyeMiyiz ? const Text("Zaten Üye", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)) : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () async {
                              final response = await http.post(Uri.parse(ApiConfig.basvuruYap(widget.aktifKullaniciId, kulup["id"])));
                              if (context.mounted) {
                                Navigator.pop(context);
                                if (response.statusCode == 200) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${kulup["adi"]} topluluğuna katılma isteği gönderildi!'), backgroundColor: Colors.green)
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Zaten bekleyen bir isteğiniz var!'), backgroundColor: Colors.orange)
                                  );
                                }
                              }
                            },
                            child: const Text('KATIL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    },
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _bildirimleriAc() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text(
              'TOPLULUK DUYURULARI',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<http.Response>(
                future: http.get(Uri.parse(ApiConfig.duyuruBase)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.purpleAccent));
                  }
                  if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
                    return const Center(child: Text("Duyurular yüklenemedi.", style: TextStyle(color: Colors.white54)));
                  }
                  
                  List<dynamic> duyurular = json.decode(snapshot.data!.body);
                  if (duyurular.isEmpty) {
                    return const Center(child: Text("Henüz duyuru yok.", style: TextStyle(color: Colors.white54)));
                  }
                  
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: duyurular.length,
                    itemBuilder: (context, index) {
                      final duyuru = duyurular[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2D3E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.purpleAccent.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.campaign_rounded, color: Colors.purpleAccent, size: 18),
                                    const SizedBox(width: 8),
                                    Text(duyuru["kulup"].toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Text(duyuru["zaman"].toString(), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              duyuru["mesaj"].toString(),
                              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                            )
                          ],
                        ),
                      );
                    },
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}