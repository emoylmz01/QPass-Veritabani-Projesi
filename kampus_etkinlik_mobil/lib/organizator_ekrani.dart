import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'main.dart';
import 'api_config.dart';

class OrganizatorEkrani extends StatefulWidget {
  const OrganizatorEkrani({super.key});

  @override
  State<OrganizatorEkrani> createState() => _OrganizatorEkraniState();
}

class _OrganizatorEkraniState extends State<OrganizatorEkrani> {
  bool taramaKilitli = false;
  bool fenerAcik = false;
  final TextEditingController manuelSifreController = TextEditingController();
  final List<Map<String, dynamic>> taramaGecmisi = [];
  MobileScannerController? _cameraController;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && !Platform.isWindows) {
      _cameraController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    manuelSifreController.dispose();
    super.dispose();
  }

  Future<void> yoklamaGonder(String okunanSifre) async {
    final splitData = okunanSifre.split('-');

    if (splitData.length == 2) {
      int? ogrId = int.tryParse(splitData[0]);
      int? etkId = int.tryParse(splitData[1]);

      if (ogrId == null || etkId == null) {
        _taramaSonucu(false, 'Geçersiz QR kodu formatı!');
        return;
      }

      try {
        final url = Uri.parse(ApiConfig.yoklamaAl);
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: json.encode({"OgrenciID": ogrId, "EtkinlikID": etkId}),
        );

        debugPrint('Yoklama Yanıt [${response.statusCode}]: ${response.body}');

        if (mounted) {
          if (response.statusCode == 200) {
            final veri = json.decode(response.body);
            final mesaj = veri["Mesaj"] ?? veri["mesaj"] ?? 'Yoklama alındı!';
            final ogrAdi = veri["OgrenciAdi"] ?? veri["ogrenciAdi"] ?? 'Öğrenci #$ogrId';
            _taramaSonucu(true, '$mesaj\n🎓 $ogrAdi');
            setState(() {
              taramaGecmisi.insert(0, {
                'ogrenciId': ogrId,
                'ogrenciAdi': ogrAdi,
                'etkinlikId': etkId,
                'basarili': true,
                'zaman': DateTime.now(),
              });
            });
          } else {
            try {
              final hata = json.decode(response.body);
              final hataMesaji = hata["Mesaj"] ?? hata["mesaj"] ?? 'Yoklama alınamadı!';
              final ogrAdi = hata["OgrenciAdi"] ?? hata["ogrenciAdi"];
              
              if (ogrAdi != null) {
                _taramaSonucu(false, '$hataMesaji\n👤 $ogrAdi');
              } else {
                _taramaSonucu(false, hataMesaji);
              }
            } catch (_) {
              _taramaSonucu(false, 'Yoklama alınamadı! (${response.statusCode})');
            }
          }
        }
      } catch (e) {
        debugPrint('Bağlantı Hatası: $e');
        if (mounted) _taramaSonucu(false, 'Sunucuya bağlanılamıyor!');
      }
    } else {
      if (mounted) _taramaSonucu(false, 'Bu geçerli bir Q-Pass kodu değil!');
    }
  }

  void _taramaSonucu(bool basarili, String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              basarili ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(mesaj)),
          ],
        ),
        backgroundColor: basarili ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isWindows = !kIsWeb && Platform.isWindows;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR YOKLAMA'),
        backgroundColor: KampusEtkinlikApp.kArkaPlanRengi,
        foregroundColor: KampusEtkinlikApp.kIkincilRenk,
        actions: [
          // Fener butonu (sadece mobilde)
          if (!isWindows && _cameraController != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: KampusEtkinlikApp.kIkincilRenk.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  fenerAcik ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: fenerAcik ? Colors.amber : KampusEtkinlikApp.kSolukYazi,
                ),
                onPressed: () {
                  _cameraController?.toggleTorch();
                  setState(() { fenerAcik = !fenerAcik; });
                },
              ),
            ),
        ],
      ),
      body: isWindows ? _buildWindowsTestEkrani() : _buildKameraEkrani(),
    );
  }

  // Windows test ekranı
  Widget _buildWindowsTestEkrani() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.computer_rounded, color: Colors.orange, size: 56),
            ),
            const SizedBox(height: 20),
            const Text(
              'SİMÜLASYON MODU',
              style: TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'Windows\'ta kamera kullanılamaz.\nQR kodun değerini aşağıya yazarak test edebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: manuelSifreController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Örn: 1-2 (öğrenciId-etkinlikId)',
                hintStyle: const TextStyle(color: KampusEtkinlikApp.kSolukYazi),
                filled: true,
                fillColor: KampusEtkinlikApp.kKartRengi,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: KampusEtkinlikApp.kIkincilRenk, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8F00)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  label: const Text('YOKLAMA GÖNDER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    if (manuelSifreController.text.trim().isNotEmpty) {
                      yoklamaGonder(manuelSifreController.text.trim());
                      manuelSifreController.clear();
                    }
                  },
                ),
              ),
            ),
            // Tarama geçmişi
            if (taramaGecmisi.isNotEmpty) ...[
              const SizedBox(height: 30),
              _buildTaramaGecmisi(),
            ],
          ],
        ),
      ),
    );
  }

  // Kamera ekranı (mobil)
  Widget _buildKameraEkrani() {
    return Column(
      children: [
        // Kamera alanı
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              if (_cameraController != null)
                MobileScanner(
                  controller: _cameraController!,
                  onDetect: (capture) async {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null && !taramaKilitli) {
                        setState(() { taramaKilitli = true; });
                        await yoklamaGonder(barcode.rawValue!);
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) setState(() { taramaKilitli = false; });
                        });
                      }
                    }
                  },
                ),

              // Tarama çerçevesi
              // Havalı tarama çerçevesi
              Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: KampusEtkinlikApp.kIkincilRenk.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Tarama çizgisi animasyonu simülasyonu (statik tasarımın daha şık hali)
                      Positioned(
                        top: 120,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            boxShadow: [BoxShadow(color: KampusEtkinlikApp.kIkincilRenk, blurRadius: 10, spreadRadius: 2)],
                            color: KampusEtkinlikApp.kIkincilRenk,
                          ),
                        ),
                      ),
                      // Köşe dekorasyonları
                      _buildKose(Alignment.topLeft),
                      _buildKose(Alignment.topRight),
                      _buildKose(Alignment.bottomLeft),
                      _buildKose(Alignment.bottomRight),
                    ],
                  ),
                ),
              ),

              // Alttan bilgi yazısı
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      taramaKilitli ? '⏳ İşleniyor...' : '📸 QR kodu çerçeveye hizalayın',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tarama geçmişi
        if (taramaGecmisi.isNotEmpty)
          Expanded(
            flex: 1,
            child: _buildTaramaGecmisi(),
          ),
      ],
    );
  }

  // Köşe dekorasyonu
  Widget _buildKose(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight
                ? const BorderSide(color: KampusEtkinlikApp.kIkincilRenk, width: 4)
                : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
                ? const BorderSide(color: KampusEtkinlikApp.kIkincilRenk, width: 4)
                : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                ? const BorderSide(color: KampusEtkinlikApp.kIkincilRenk, width: 4)
                : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
                ? const BorderSide(color: KampusEtkinlikApp.kIkincilRenk, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Tarama geçmişi widget'ı
  Widget _buildTaramaGecmisi() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KampusEtkinlikApp.kKartRengi,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: KampusEtkinlikApp.kIkincilRenk, size: 20),
              const SizedBox(width: 8),
              Text(
                'Son Taramalar (${taramaGecmisi.length})',
                style: const TextStyle(color: KampusEtkinlikApp.kIkincilRenk, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: taramaGecmisi.length > 5 ? 5 : taramaGecmisi.length,
              itemBuilder: (context, index) {
                final t = taramaGecmisi[index];
                final saat = '${t['zaman'].hour.toString().padLeft(2, '0')}:${t['zaman'].minute.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        t['basarili'] ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: t['basarili'] ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t['ogrenciAdi'] ?? 'Öğrenci #${t['ogrenciId']}',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      Text(saat, style: const TextStyle(color: KampusEtkinlikApp.kSolukYazi, fontSize: 13)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}