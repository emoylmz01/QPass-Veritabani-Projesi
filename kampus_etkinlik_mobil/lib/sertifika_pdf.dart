import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

class SertifikaPdf {
  // Renk sabitleri
  static const _altin = PdfColor.fromInt(0xFFD4AF37);
  static const _koyu = PdfColor.fromInt(0xFF1A1A2E);
  static const _gri = PdfColor.fromInt(0xFF888888);
  static const _acikGri = PdfColor.fromInt(0xFF555555);
  static const _teal = PdfColor.fromInt(0xFF00B8A9);
  static const _krem = PdfColor.fromInt(0xFFFFFDF5);

  /// PDF sertifika oluşturur ve yazdırma/kaydetme dialogu açar
  static Future<void> olusturVeIndir({
    required String etkinlikAdi,
    required String sertifikaKodu,
    required String tarih,
    String? konum,
  }) async {
    // Türkçe karakter destekli fontları yükle
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final fontItalic = await PdfGoogleFonts.notoSansItalic();

    final pdf = pw.Document();

    // İmza görselini yükle
    final imzaData = await rootBundle.load('assets/imza.png');
    final imzaImage = pw.MemoryImage(imzaData.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(0),
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
          italic: fontItalic,
        ),
        build: (pw.Context context) {
          return pw.Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const pw.BoxDecoration(color: _krem),
            child: pw.Stack(
              children: [
                // === Dış çerçeve ===
                pw.Positioned.fill(
                  child: pw.Container(
                    margin: const pw.EdgeInsets.all(20),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _altin, width: 3),
                    ),
                    child: pw.Container(
                      margin: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: _altin, width: 1),
                      ),
                    ),
                  ),
                ),

                // === Köşe süslemeleri ===
                // Sol üst
                pw.Positioned(
                  top: 30, left: 30,
                  child: _koseDekorasyon(ust: true, sol: true),
                ),
                // Sağ üst
                pw.Positioned(
                  top: 30, right: 30,
                  child: _koseDekorasyon(ust: true, sol: false),
                ),
                // Sol alt
                pw.Positioned(
                  bottom: 30, left: 30,
                  child: _koseDekorasyon(ust: false, sol: true),
                ),
                // Sağ alt
                pw.Positioned(
                  bottom: 30, right: 30,
                  child: _koseDekorasyon(ust: false, sol: false),
                ),

                // === Ana içerik ===
                pw.Positioned.fill(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 80,
                      vertical: 45,
                    ),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        // Madalya rozeti
                        pw.CustomPaint(
                          size: const PdfPoint(65, 65),
                          painter: (PdfGraphics canvas, PdfPoint size) {
                            final cx = size.x / 2;
                            final cy = size.y / 2;
                            final r = size.x / 2 - 4;

                            // Altın dış daire
                            canvas
                              ..setColor(_altin)
                              ..setLineWidth(2.5)
                              ..drawEllipse(cx, cy, r, r)
                              ..strokePath();

                            // İç daire
                            canvas
                              ..setLineWidth(1.5)
                              ..drawEllipse(cx, cy, r - 6, r - 6)
                              ..strokePath();

                            // Onay işareti (✓) — düzgün koordinatlar
                            canvas
                              ..setLineWidth(3)
                              ..moveTo(cx - 10, cy)
                              ..lineTo(cx - 3, cy - 8)
                              ..lineTo(cx + 12, cy + 10)
                              ..strokePath();
                          },
                        ),
                        pw.SizedBox(height: 12),

                        // Başlık
                        pw.Text(
                          'KATILIM SERTİFİKASI',
                          style: pw.TextStyle(
                            fontSize: 30,
                            fontWeight: pw.FontWeight.bold,
                            color: _koyu,
                            letterSpacing: 5,
                          ),
                        ),
                        pw.SizedBox(height: 5),

                        // Dekoratif altın çizgi
                        pw.Container(
                          width: 180,
                          height: 2,
                          color: _altin,
                        ),
                        pw.SizedBox(height: 18),

                        // Açıklama
                        pw.Text(
                          'Bu belge ile aşağıdaki etkinliğe katılım sağlandığı onaylanır.',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: _acikGri,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                        pw.SizedBox(height: 20),

                        // Etkinlik adı — altın çerçeve
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 14,
                          ),
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              top: pw.BorderSide(color: _altin, width: 1),
                              bottom: pw.BorderSide(color: _altin, width: 1),
                            ),
                          ),
                          child: pw.Text(
                            etkinlikAdi,
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: _koyu,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.SizedBox(height: 16),

                        // Tarih ve konum bilgisi
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            _bilgiKutusu('TARİH', tarih),
                            if (konum != null && konum.isNotEmpty) ...[
                              pw.SizedBox(width: 50),
                              _bilgiKutusu('KONUM', konum),
                            ],
                          ],
                        ),
                        pw.SizedBox(height: 24),

                        // Alt bilgi satırı: Q-Pass | İmza | Sertifika No
                        pw.Row(
                          mainAxisAlignment:
                              pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            // Sol: Q-Pass
                            pw.Column(
                              crossAxisAlignment:
                                  pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'Q-Pass',
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _teal,
                                  ),
                                ),
                                pw.Text(
                                  'Kampüs Etkinlik Yönetim Sistemi',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: _gri,
                                  ),
                                ),
                              ],
                            ),

                            // Orta: İmza
                            pw.Column(
                              children: [
                                pw.Image(imzaImage,
                                    width: 130, height: 50),
                                pw.SizedBox(height: 2),
                                pw.Container(
                                  width: 140,
                                  height: 1,
                                  color: const PdfColor.fromInt(0xFF333333),
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  'Organizatör İmzası',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    color: _gri,
                                    font: font,
                                  ),
                                ),
                              ],
                            ),

                            // Sağ: Sertifika kodu
                            pw.Column(
                              crossAxisAlignment:
                                  pw.CrossAxisAlignment.end,
                              children: [
                                pw.Text(
                                  'Sertifika No',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: _gri,
                                  ),
                                ),
                                pw.Text(
                                  sertifikaKodu,
                                  style: pw.TextStyle(
                                    fontSize: 13,
                                    fontWeight: pw.FontWeight.bold,
                                    color: _altin,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Sertifika_$sertifikaKodu',
    );
  }

  /// Köşe dekorasyonu — doğru yönlere border koyar (rotate kullanmadan)
  static pw.Widget _koseDekorasyon({
    required bool ust,
    required bool sol,
  }) {
    return pw.Container(
      width: 30,
      height: 30,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: ust
              ? const pw.BorderSide(color: _altin, width: 2)
              : pw.BorderSide.none,
          bottom: !ust
              ? const pw.BorderSide(color: _altin, width: 2)
              : pw.BorderSide.none,
          left: sol
              ? const pw.BorderSide(color: _altin, width: 2)
              : pw.BorderSide.none,
          right: !sol
              ? const pw.BorderSide(color: _altin, width: 2)
              : pw.BorderSide.none,
        ),
      ),
    );
  }

  /// Bilgi kutusu (tarih, konum vb.)
  static pw.Widget _bilgiKutusu(String baslik, String deger) {
    return pw.Column(
      children: [
        pw.Text(
          baslik,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _gri,
            letterSpacing: 2,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          deger,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF333333),
          ),
        ),
      ],
    );
  }
}
