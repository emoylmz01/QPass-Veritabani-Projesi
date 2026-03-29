import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class QrTarayici extends StatefulWidget {
  final int aktifKullaniciId;
  const QrTarayici({super.key, required this.aktifKullaniciId});

  @override
  State<QrTarayici> createState() => _QrTarayiciState();
}

class _QrTarayiciState extends State<QrTarayici> {
  bool isScanning = true;

  void _onDetect(BarcodeCapture capture) async {
    if (!isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        setState(() => isScanning = false); // Taramayı durdur
        
        // Örnek QR Verisi: "12 (Kullanıcı ID) - 5 (Etkinlik ID)" veya JSON
        // Basit simülasyon: Virgülle veya tireyle ayrılmış ID'ler. 
        // Burada öğrenci QR'ı okutarak "Yoklama" vermiş sayılacak. Ancak normalde organizatör öğrencinin QR'ını okur.
        // Eğer öğrenci etkinlik duvarındaki QR'ı okutuyorsa format farklı olabilir. Biz şimdilik etkinlikID'sini okuduğunu varsayalım.
        int etkinlikId = int.tryParse(code.split('-').last) ?? 0;
        
        if (etkinlikId > 0) {
          _yoklamaVer(etkinlikId);
        } else {
          _hataGoster("Geçersiz QR Kod: $code");
        }
        break;
      }
    }
  }

  Future<void> _yoklamaVer(int etkinlikId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
      );

      final url = Uri.parse(ApiConfig.yoklamaAl);
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "ogrenciID": widget.aktifKullaniciId,
          "etkinlikID": etkinlikId,
        }),
      );

      if (!mounted) return;
      Navigator.pop(context); // Loading'i kapat

      if (response.statusCode == 200) {
        _basariGoster("Yoklama başarılı! Puan kazandınız.");
      } else {
        _hataGoster("Yoklama başarısız veya zaten alınmış.");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _hataGoster("Bağlantı hatası: $e");
    }
  }

  void _basariGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
    );
    Navigator.pop(context, true); // Geri dön ve yenile
  }

  void _hataGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
    setState(() => isScanning = true); // Tekrar okumaya izin ver
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('QR Oku', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          // Hedefleme kutusu görseli
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.purpleAccent, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const Positioned(
            bottom: 50,
            child: Text(
              'Etkinlik QR Kodunu Karenin İçine Alın',
              style: TextStyle(color: Colors.white, fontSize: 16, backgroundColor: Colors.black54),
            ),
          )
        ],
      ),
    );
  }
}
