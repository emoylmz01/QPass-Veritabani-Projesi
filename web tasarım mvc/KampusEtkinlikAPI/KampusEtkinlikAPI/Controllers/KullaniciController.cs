using KampusEtkinlikAPI.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace KampusEtkinlikAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class KullaniciController : ControllerBase
    {
        private readonly KampusEtkinlikDbContext _context;

        public KullaniciController(KampusEtkinlikDbContext context)
        {
            _context = context;
        }

        // =====================================================================
        // POST: api/Kullanici/GirisYap — Öğrenci girişi
        // =====================================================================
        [HttpPost("GirisYap")]
        public async Task<IActionResult> GirisYap([FromBody] GirisIstegi istek)
        {
            try
            {
                if (string.IsNullOrWhiteSpace(istek.Email) || string.IsNullOrWhiteSpace(istek.Sifre))
                {
                    return BadRequest(new { Mesaj = "E-posta ve şifre boş olamaz!" });
                }

                var kullanici = await _context.Kullanicis
                    .FirstOrDefaultAsync(k => k.Email == istek.Email && k.Sifre == istek.Sifre);

                if (kullanici == null)
                {
                    return BadRequest(new { Mesaj = "E-posta veya şifre hatalı!" });
                }

                // GÜVENLİK: Şifreyi yanıtta döndürmüyoruz!
                return Ok(new
                {
                    kullaniciId = kullanici.KullaniciId,
                    ad = kullanici.Ad,
                    soyad = kullanici.Soyad,
                    email = kullanici.Email,
                    rol = kullanici.Rol
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { Mesaj = "Giriş hatası: " + ex.Message });
            }
        }

        // =====================================================================
        // POST: api/Kullanici/KayitOl — Yeni öğrenci kaydı
        // =====================================================================
        [HttpPost("KayitOl")]
        public async Task<IActionResult> KayitOl([FromBody] Kullanici yeniKullanici)
        {
            try
            {
                // Input validasyonu
                if (string.IsNullOrWhiteSpace(yeniKullanici.Ad) ||
                    string.IsNullOrWhiteSpace(yeniKullanici.Soyad) ||
                    string.IsNullOrWhiteSpace(yeniKullanici.Email))
                {
                    return BadRequest(new { Mesaj = "Ad, soyad ve e-posta alanları zorunludur!" });
                }

                if (string.IsNullOrWhiteSpace(yeniKullanici.Sifre))
                {
                    return BadRequest(new { Mesaj = "Şifre boş olamaz!" });
                }

                // Mükerrer e-posta kontrolü
                var emailVarMi = await _context.Kullanicis.AnyAsync(k => k.Email == yeniKullanici.Email);
                if (emailVarMi)
                {
                    return BadRequest(new { Mesaj = "Bu e-posta adresi zaten kullanılıyor!" });
                }

                // Rol her zaman öğrenci olarak atanır
                yeniKullanici.Rol = "Ogrenci";
                _context.Kullanicis.Add(yeniKullanici);
                await _context.SaveChangesAsync();

                return Ok(new
                {
                    Mesaj = "Kayıt başarıyla tamamlandı!",
                    KullaniciId = yeniKullanici.KullaniciId
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Mesaj = "Kayıt hatası: " + ex.Message });
            }
        }

        // =====================================================================
        // GET: api/Kullanici/{id} — Kullanıcı profili getir
        // =====================================================================
        [HttpGet("{id}")]
        public async Task<IActionResult> GetKullanici(int id)
        {
            try
            {
                var kullanici = await _context.Kullanicis.FindAsync(id);
                if (kullanici == null)
                    return NotFound(new { Mesaj = "Kullanıcı bulunamadı!" });

                // Öğrencinin katıldığı etkinlikler üzerinden kulüplerini buluyoruz (Distinct)
                var kulupler = await _context.KatilimKaydis
                    .Where(k => k.KullaniciId == id && k.Etkinlik.Kulup != null)
                    .Select(k => k.Etkinlik.Kulup.KulupAdi)
                    .Distinct()
                    .ToListAsync();

                return Ok(new
                {
                    kullaniciId = kullanici.KullaniciId,
                    ad = kullanici.Ad,
                    soyad = kullanici.Soyad,
                    email = kullanici.Email,
                    rol = kullanici.Rol,
                    oyunlastirmaPuani = kullanici.OyunlastirmaPuani ?? 0,
                    guvenilirlikPuani = kullanici.GuvenilirlikPuani ?? 100,
                    kulupler = kulupler
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { Mesaj = "Kullanıcı bilgileri alınamadı: " + ex.Message });
            }
        }
    }

    // DTO: Giriş istekleri için
    public class GirisIstegi
    {
        public string Email { get; set; } = null!;
        public string Sifre { get; set; } = null!;
    }
}