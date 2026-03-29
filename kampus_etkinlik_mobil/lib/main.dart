import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'giris_ekrani.dart';
import 'organizator_paneli.dart';
import 'ogrenci_ekrani.dart';
import 'api_config.dart';

// Geliştirme: kendi imzalı HTTPS sertifikalarını kabul et
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const KampusEtkinlikApp());
}

class KampusEtkinlikApp extends StatelessWidget {
  const KampusEtkinlikApp({super.key});

  // Uygulama Renk Paleti
  static const Color kArkaPlanRengi = Color(0xFF0A0E21);
  static const Color kYuzeyRengi = Color(0xFF1A1F38);
  static const Color kKartRengi = Color(0xFF1E2342);
  static const Color kBirincilRenk = Color(0xFF00E5A0);
  static const Color kIkincilRenk = Color(0xFFFF6B35);
  static const Color kYaziRengi = Color(0xFFE8E8E8);
  static const Color kSolukYazi = Color(0xFF8D8D8D);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Q-Pass',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kArkaPlanRengi,
        primaryColor: kBirincilRenk,
        appBarTheme: const AppBarTheme(
          backgroundColor: kArkaPlanRengi,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: kYaziRengi,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kYuzeyRengi,
            foregroundColor: kYaziRengi,
            elevation: 5,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        useMaterial3: true,
      ),
      home: const AnaEkran(),
    );
  }
}

// =====================================================================
// ANA EKRAN — Animasyonlu karşılama ekranı
// =====================================================================
class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _animController.forward();

    // Otomatik giriş kontrolü
    _otomatikGirisKontrol();
  }

  Future<void> _otomatikGirisKontrol() async {
    final prefs = await SharedPreferences.getInstance();
    final kayitliId = prefs.getInt('kullaniciId');
    final kayitliRol = prefs.getString('kullaniciRol') ?? 'Ogrenci';
    if (kayitliId != null && kayitliId > 0 && mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        if (kayitliRol.toLowerCase() == 'organizator' || kayitliRol.toLowerCase() == 'organizatör') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OrganizatorPaneli()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => OgrenciEkrani(aktifKullaniciId: kayitliId)),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E21),
              Color(0xFF141A36),
              Color(0xFF0A0E21),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // — Logo alanı —
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00E5A0), Color(0xFF00B8D4)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00E5A0).withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded, size: 72, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // — Uygulama adı —
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF00E5A0), Color(0xFF00B8D4)],
                      ).createShader(bounds),
                      child: const Text(
                        'Q-Pass',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kampüs Etkinlik Yönetim Sistemi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 60),

                    // — Öğrenci Girişi Butonu —
                    _buildPremiumButton(
                      icon: Icons.school_rounded,
                      label: 'ÖĞRENCİ GİRİŞİ',
                      gradientColors: const [Color(0xFF00E5A0), Color(0xFF00B8D4)],
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const GirisEkrani()));
                      },
                    ),
                    const SizedBox(height: 16),

                    // — Organizatör Girişi Butonu —
                    _buildPremiumButton(
                      icon: Icons.admin_panel_settings_rounded,
                      label: 'ORGANİZATÖR GİRİŞİ',
                      gradientColors: const [Color(0xFFFF6B35), Color(0xFFFF8F00)],
                      textColor: Colors.white,
                      outlined: true,
                      onPressed: () => _organizatorGirisDialog(context),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Premium buton widget'ı
  Widget _buildPremiumButton({
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
    required Color textColor,
    required VoidCallback onPressed,
    bool outlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: outlined
          ? OutlinedButton.icon(
              icon: Icon(icon, color: gradientColors[0]),
              label: Text(label, style: TextStyle(color: gradientColors[0], fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: gradientColors[0], width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: onPressed,
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: Icon(icon, color: textColor),
                label: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: onPressed,
              ),
            ),
    );
  }

  // Organizatör giriş dialogu — API üzerinden gerçek giriş
  void _organizatorGirisDialog(BuildContext context) {
    final emailController = TextEditingController();
    final sifreController = TextEditingController();
    bool sifreGizli = true;
    bool yukleniyor = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: KampusEtkinlikApp.kKartRengi,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: KampusEtkinlikApp.kIkincilRenk.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.shield_rounded, color: KampusEtkinlikApp.kIkincilRenk, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Organizatör Girişi',
                      style: TextStyle(color: KampusEtkinlikApp.kIkincilRenk, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email_rounded, color: KampusEtkinlikApp.kIkincilRenk),
                      labelText: 'E-Posta',
                      labelStyle: const TextStyle(color: KampusEtkinlikApp.kSolukYazi),
                      filled: true,
                      fillColor: KampusEtkinlikApp.kArkaPlanRengi,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: sifreController,
                    obscureText: sifreGizli,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock, color: KampusEtkinlikApp.kIkincilRenk),
                      suffixIcon: IconButton(
                        icon: Icon(sifreGizli ? Icons.visibility_off : Icons.visibility, color: KampusEtkinlikApp.kSolukYazi),
                        onPressed: () => setDialogState(() => sifreGizli = !sifreGizli),
                      ),
                      labelText: 'Şifre',
                      labelStyle: const TextStyle(color: KampusEtkinlikApp.kSolukYazi),
                      filled: true,
                      fillColor: KampusEtkinlikApp.kArkaPlanRengi,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('İPTAL', style: TextStyle(color: KampusEtkinlikApp.kSolukYazi)),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8F00)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: yukleniyor ? null : () async {
                      if (emailController.text.trim().isEmpty || sifreController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('E-posta ve şifre boş olamaz!'),
                            backgroundColor: Colors.orange.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => yukleniyor = true);

                      try {
                        final response = await http.post(
                          Uri.parse(ApiConfig.girisYap),
                          headers: {"Content-Type": "application/json"},
                          body: json.encode({
                            "Email": emailController.text.trim(),
                            "Sifre": sifreController.text,
                          }),
                        ).timeout(const Duration(seconds: 10));

                        if (response.statusCode == 200) {
                          final veri = json.decode(response.body);
                          final rol = veri["rol"] ?? veri["Rol"] ?? "Ogrenci";

                          if (rol.toString().toLowerCase() != 'organizator' && rol.toString().toLowerCase() != 'organizatör') {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Bu hesap organizatör hesabı değil!'),
                                  backgroundColor: Colors.red.shade700,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                            setDialogState(() => yukleniyor = false);
                            return;
                          }

                          // Beni hatırla → kaydet
                          final prefs = await SharedPreferences.getInstance();
                          final aktifId = veri["kullaniciId"] ?? veri["KullaniciId"] ?? 0;
                          await prefs.setInt('kullaniciId', aktifId);
                          await prefs.setString('kullaniciRol', rol.toString());

                          if (context.mounted) {
                            Navigator.pop(dialogContext);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const OrganizatorPaneli()));
                          }
                        } else {
                          String hataMesaji = 'E-posta veya şifre hatalı!';
                          try {
                            final hata = json.decode(response.body);
                            hataMesaji = hata["Mesaj"] ?? hata["mesaj"] ?? hataMesaji;
                          } catch (_) {}
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.white),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(hataMesaji)),
                                  ],
                                ),
                                backgroundColor: Colors.red.shade700,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Sunucuya bağlanılamıyor!'),
                              backgroundColor: Colors.red.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      }

                      setDialogState(() => yukleniyor = false);
                    },
                    child: yukleniyor
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('GİRİŞ YAP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}