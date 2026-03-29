import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'main.dart';
import 'api_config.dart';
import 'ogrenci_ekrani.dart';
import 'organizator_paneli.dart';

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController sifreController = TextEditingController();
  final TextEditingController adController = TextEditingController();
  final TextEditingController soyadController = TextEditingController();

  bool kayitModu = false;
  bool yukleniyor = false;
  bool sifreGizli = true;
  bool beniHatirla = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    emailController.dispose();
    sifreController.dispose();
    adController.dispose();
    soyadController.dispose();
    super.dispose();
  }

  Future<void> islemYap() async {
    // Form validasyonu
    if (emailController.text.trim().isEmpty || sifreController.text.trim().isEmpty) {
      mesajGoster('Lütfen tüm alanları doldurun!', Colors.orange);
      return;
    }
    if (kayitModu && (adController.text.trim().isEmpty || soyadController.text.trim().isEmpty)) {
      mesajGoster('Ad ve soyad alanları boş bırakılamaz!', Colors.orange);
      return;
    }

    setState(() { yukleniyor = true; });

    try {
      if (kayitModu) {
        final response = await http.post(
          Uri.parse(ApiConfig.kayitOl),
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "Ad": adController.text.trim(),
            "Soyad": soyadController.text.trim(),
            "Email": emailController.text.trim(),
            "Sifre": sifreController.text,
            "Rol": "Ogrenci"
          }),
        );

        debugPrint('Kayıt Yanıt [${response.statusCode}]: ${response.body}');

        if (response.statusCode == 200) {
          mesajGoster('Kayıt başarılı! Şimdi giriş yapabilirsiniz. ✅', Colors.green);
          setState(() { kayitModu = false; });
        } else {
          // API'den dönen gerçek hatayı göster
          try {
            final hata = json.decode(response.body);
            mesajGoster(hata["Mesaj"] ?? hata["mesaj"] ?? hata["title"] ?? 'Kayıt başarısız!', Colors.red);
          } catch (_) {
            mesajGoster('Kayıt başarısız! (${response.statusCode})', Colors.red);
          }
        }
      } else {
        final response = await http.post(
          Uri.parse(ApiConfig.girisYap),
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "Email": emailController.text.trim(),
            "Sifre": sifreController.text,
          }),
        );

        debugPrint('Giriş Yanıt [${response.statusCode}]: ${response.body}');

        if (response.statusCode == 200) {
          final gelenVeri = json.decode(response.body);
          final int aktifId = gelenVeri["kullaniciId"] ?? gelenVeri["KullaniciId"] ?? gelenVeri["kullaniciID"] ?? gelenVeri["KullaniciID"] ?? gelenVeri["id"] ?? 0;
          final String rol = gelenVeri["rol"] ?? gelenVeri["Rol"] ?? gelenVeri["ROL"] ?? "Ogrenci";

          if (aktifId == 0) {
            mesajGoster('Giriş yapıldı ancak kullanıcı kimliği alınamadı.', Colors.orange);
            return;
          }

          // Beni Hatırla seçiliyse kaydet
          if (beniHatirla) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('kullaniciId', aktifId);
            await prefs.setString('kullaniciRol', rol);
          }

          if (!mounted) return;
          
          if (rol.toLowerCase() == "organizator" || rol.toLowerCase() == "organizatör") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OrganizatorPaneli()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => OgrenciEkrani(aktifKullaniciId: aktifId)),
            );
          }
        } else {
          try {
            final hata = json.decode(response.body);
            mesajGoster(hata["Mesaj"] ?? hata["mesaj"] ?? 'E-posta veya şifre hatalı!', Colors.red);
          } catch (_) {
            mesajGoster('E-posta veya şifre hatalı! (${response.statusCode})', Colors.red);
          }
        }
      }
    } catch (e) {
      debugPrint('Bağlantı Hatası: $e');
      mesajGoster('Sunucuya bağlanılamıyor!\n$e', Colors.red);
    }

    if (mounted) setState(() { yukleniyor = false; });
  }

  void mesajGoster(String mesaj, Color renk) {
    if (!mounted) return;
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
      backgroundColor: const Color(0xFF0F0F0F),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF0F0F0F), // Neon tema zemini
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // İkon ve Başlık
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Q-Pass ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Icon(Icons.bolt_rounded, color: Colors.purpleAccent, size: 40),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    kayitModu ? 'Aramıza Katıl' : 'Hesabınıza Giriş Yapın',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 48),

                  // Kayıt modu alanları
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    child: kayitModu
                        ? Column(
                            children: [
                              _buildTextField(controller: adController, ikon: Icons.person, ipucu: 'Adınız'),
                              const SizedBox(height: 14),
                              _buildTextField(controller: soyadController, ikon: Icons.person_outline, ipucu: 'Soyadınız'),
                              const SizedBox(height: 14),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),

                  // E-posta
                  _buildTextField(controller: emailController, ikon: Icons.email_rounded, ipucu: 'E-Posta Adresiniz'),
                  const SizedBox(height: 14),

                  // Şifre (göster/gizle ile)
                  TextField(
                    controller: sifreController,
                    obscureText: sifreGizli,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_rounded, color: Colors.cyanAccent),
                      suffixIcon: IconButton(
                        icon: Icon(
                          sifreGizli ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: Colors.white54,
                        ),
                        onPressed: () => setState(() => sifreGizli = !sifreGizli),
                      ),
                      hintText: 'Şifreniz',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.purpleAccent, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (!kayitModu)
                    GestureDetector(
                      onTap: () => setState(() => beniHatirla = !beniHatirla),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: beniHatirla,
                              onChanged: (v) => setState(() => beniHatirla = v ?? false),
                              activeColor: Colors.purpleAccent,
                              checkColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text('Beni Hatırla', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 28),

                  // Giriş / Kayıt butonu
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.purpleAccent, Colors.cyanAccent]),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purpleAccent.withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: yukleniyor ? null : islemYap,
                        child: yukleniyor
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text(
                                kayitModu ? 'KAYIT OL' : 'GİRİŞ YAP',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mod değiştirme butonu
                  TextButton(
                    onPressed: () {
                      setState(() { kayitModu = !kayitModu; });
                    },
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                        children: [
                          TextSpan(text: kayitModu ? 'Zaten hesabınız var mı? ' : 'Hesabınız yok mu? '),
                          TextSpan(
                            text: kayitModu ? 'Giriş Yapın' : 'Hemen Kayıt Olun',
                            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
        prefixIcon: Icon(ikon, color: Colors.cyanAccent),
        hintText: ipucu,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.purpleAccent, width: 1.5),
        ),
      ),
    );
  }
}