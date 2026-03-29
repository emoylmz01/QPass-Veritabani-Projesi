using KampusEtkinlikAPI.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace KampusEtkinlikAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class EtkinlikController : ControllerBase
    {
        private readonly KampusEtkinlikDbContext _context;

        public EtkinlikController(KampusEtkinlikDbContext context)
        {
            _context = context;
        }

        // =====================================================================
        // GET: api/Etkinlik — Aktif etkinlikleri listeler
        // =====================================================================
        [HttpGet]
        public async Task<IActionResult> GetEtkinlikler()
        {
            try
            {
                var etkinlikler = await _context.Etkinliks
                    .Include(e => e.Kulup)
                    .Where(e => e.AktifMi != false)
                    .Select(e => new
                    {
                        etkinlikId = e.EtkinlikId,
                        kulupId = e.KulupId,
                        kulupAdi = e.Kulup != null ? e.Kulup.KulupAdi : "Bilinmeyen Topluluk",
                        kulupPuan = e.Kulup != null ? e.Kulup.OrtalamaPuan : (decimal?)0.0,
                        etkinlikAdi = e.EtkinlikAdi,
                        konum = e.Konum,
                        tarih = e.TarihSaat,
                        aciklama = e.Aciklama,
                        kontenjan = e.Kontenjan,
                        sertifikaliMi = e.SertifikaliMi,
                        puanDegeri = e.PuanDegeri ?? 10, // Varsayılan 10 Puan
                        katilimciSayisi = _context.KatilimKaydis.Count(k => k.EtkinlikId == e.EtkinlikId)
                    }).ToListAsync();

                return Ok(etkinlikler);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { Mesaj = "Etkinlikler yüklenirken hata: " + ex.Message });
            }
        }

        // =====================================================================
        // GET: api/Etkinlik/Detay/5 — Tek etkinlik detayı
        // =====================================================================
        [HttpGet("Detay/{id}")]
        public async Task<IActionResult> GetEtkinlikDetay(int id)
        {
            try
            {
                var etkinlik = await _context.Etkinliks
                    .Include(e => e.Kulup)
                    .Where(e => e.EtkinlikId == id)
                    .Select(e => new
                    {
                        etkinlikId = e.EtkinlikId,
                        kulupId = e.KulupId,
                        kulupAdi = e.Kulup != null ? e.Kulup.KulupAdi : "Bilinmeyen Topluluk",
                        kulupPuan = e.Kulup != null ? e.Kulup.OrtalamaPuan : (decimal?)0.0,
                        etkinlikAdi = e.EtkinlikAdi,
                        konum = e.Konum,
                        tarih = e.TarihSaat,
                        aciklama = e.Aciklama,
                        kontenjan = e.Kontenjan,
                        sertifikaliMi = e.SertifikaliMi,
                        puanDegeri = e.PuanDegeri ?? 10,
                        aktifMi = e.AktifMi,
                        katilimciSayisi = _context.KatilimKaydis.Count(k => k.EtkinlikId == e.EtkinlikId),
                        yoklamaAlinanSayisi = (from k in _context.KatilimKaydis
                                               join s in _context.Sertifikas on k.KayitId equals s.KayitId
                                               where k.EtkinlikId == e.EtkinlikId
                                               select s).Count()
                    }).FirstOrDefaultAsync();

                if (etkinlik == null)
                    return NotFound(new { Mesaj = "Etkinlik bulunamadı!" });

                return Ok(etkinlik);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { Mesaj = "Hata: " + ex.Message });
            }
        }

        // =====================================================================
        // POST: api/Etkinlik/KayitOl — Öğrenci etkinliğe kaydolur
        // =====================================================================
        [HttpPost("KayitOl")]
        public async Task<IActionResult> KayitOl([FromBody] KayitIstegi istek)
        {
            try
            {
                // Mükerrer kayıt kontrolü
                var zatenKayitliMi = await _context.KatilimKaydis
                    .AnyAsync(k => k.KullaniciId == istek.OgrenciID && k.EtkinlikId == istek.EtkinlikID);

                if (zatenKayitliMi)
                {
                    return Ok(new { Mesaj = "Bu etkinliğe zaten kayıtlısınız!", ZatenKayitli = true });
                }

                // Kontenjan kontrolü
                var etkinlik = await _context.Etkinliks.FindAsync(istek.EtkinlikID);
                if (etkinlik == null)
                    return NotFound(new { Mesaj = "Etkinlik bulunamadı!" });

                var mevcutKayit = await _context.KatilimKaydis
                    .CountAsync(k => k.EtkinlikId == istek.EtkinlikID);

                if (mevcutKayit >= etkinlik.Kontenjan && etkinlik.Kontenjan > 0)
                {
                    return BadRequest(new { Mesaj = "Etkinlik kontenjanı dolmuştur!" });
                }

                // Stored Procedure ile kayıt (mevcut yapı korunuyor)
                await _context.Database.ExecuteSqlRawAsync(
                    "EXEC sp_EtkinlikKayitYap {0}, {1}", istek.OgrenciID, istek.EtkinlikID);

                return Ok(new { Mesaj = "Etkinliğe başarıyla kayıt oldunuz!" });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Mesaj = "Kayıt hatası: " + ex.Message });
            }
        }

        // =====================================================================
        // POST: api/Etkinlik/YoklamaAl — QR taratarak yoklama alır
        // =====================================================================
        [HttpPost("YoklamaAl")]
        public async Task<IActionResult> YoklamaAl([FromBody] KayitIstegi istek)
        {
            try
            {
                // 1. Öğrenci bu etkinliğe kayıtlı mı?
                var kayit = await _context.KatilimKaydis
                    .FirstOrDefaultAsync(k => k.KullaniciId == istek.OgrenciID && k.EtkinlikId == istek.EtkinlikID);

                if (kayit == null)
                {
                    return BadRequest(new { Mesaj = "Bu öğrenci etkinliğe kayıtlı değil!" });
                }

                // Öğrenci bilgisini baştan al ki mesajlarda ismi kullanabilelim
                var ogrenci = await _context.Kullanicis.FindAsync(istek.OgrenciID);
                string ogrenciAdi = ogrenci != null ? $"{ogrenci.Ad} {ogrenci.Soyad}" : "Bilinmiyor";

                // 2. Yoklama (sertifika) daha önce alınmış mı?
                var sertifikaVarMi = await _context.Sertifikas
                    .AnyAsync(s => s.KayitId == kayit.KayitId);

                if (sertifikaVarMi)
                {
                    return Ok(new { Mesaj = "Yoklaması Zaten Alındı", ZatenAlindi = true, OgrenciAdi = ogrenciAdi });
                }

                // 3. Yoklama durumunu güncelle (Bu işlem DB'deki trg_OtomatikSertifikaUret trigger'ını çalıştırıp Sertifika oluşturur)
                kayit.Durum = "Katildi";
                
                // 4. Öğrencinin oyunlaştırma puanını artır
                var etkinlikDegeri = await _context.Etkinliks.FindAsync(istek.EtkinlikID);
                var kazanilanPuan = etkinlikDegeri?.PuanDegeri ?? 10;
                if (ogrenci != null)
                {
                    ogrenci.OyunlastirmaPuani = (ogrenci.OyunlastirmaPuani ?? 0) + kazanilanPuan;
                }

                await _context.SaveChangesAsync();

                // Trigger'ın oluşturduğu sertifikayı DB'den çek
                var olusanSertifika = await _context.Sertifikas.FirstOrDefaultAsync(s => s.KayitId == kayit.KayitId);

                // Öğrenci bilgisini de dön (kamerada göstermek için)
                return Ok(new
                {
                    Mesaj = "Yoklama başarıyla alındı!",
                    OgrenciAdi = ogrenci != null ? $"{ogrenci.Ad} {ogrenci.Soyad}" : "Bilinmiyor",
                    SertifikaKodu = olusanSertifika != null ? olusanSertifika.SertifikaKodu : "Oluşturuluyor..."
                });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Mesaj = "Yoklama hatası: " + ex.Message });
            }
        }

        // =====================================================================
        // POST: api/Etkinlik/Ekle — Yeni etkinlik oluşturur
        // =====================================================================
        [HttpPost("Ekle")]
        public async Task<IActionResult> EtkinlikEkle([FromBody] Etkinlik yeniEtkinlik)
        {
            try
            {
                // Zorunlu alan kontrolü
                if (string.IsNullOrWhiteSpace(yeniEtkinlik.EtkinlikAdi))
                {
                    return BadRequest(new { Mesaj = "Etkinlik adı boş olamaz!" });
                }

                // Varsayılan değerler
                yeniEtkinlik.AktifMi = true;
                if (yeniEtkinlik.TarihSaat == default)
                {
                    yeniEtkinlik.TarihSaat = DateTime.Now;
                }

                _context.Etkinliks.Add(yeniEtkinlik);
                await _context.SaveChangesAsync();

                return Ok(new { Mesaj = "Yeni etkinlik başarıyla oluşturuldu!", EtkinlikId = yeniEtkinlik.EtkinlikId });
            }
            catch (Exception ex)
            {
                return BadRequest(new { Mesaj = "Etkinlik eklenirken hata: " + ex.Message });
            }
        }

        // =====================================================================
        // GET: api/Etkinlik/Sertifikalarim/5 — Öğrencinin sertifikaları
        // =====================================================================
        [HttpGet("Sertifikalarim/{ogrenciId}")]
        public async Task<IActionResult> GetSertifikalarim(int ogrenciId)
        {
            try
            {
                var sertifikalar = await (from s in _context.Sertifikas
                                         join k in _context.KatilimKaydis on s.KayitId equals k.KayitId
                                         join e in _context.Etkinliks on k.EtkinlikId equals e.EtkinlikId
                                         where k.KullaniciId == ogrenciId
                                         select new
                                         {
                                             sertifikaKodu = s.SertifikaKodu,
                                             uretimTarihi = s.UretimTarihi,
                                             etkinlikAdi = e.EtkinlikAdi,
                                             konum = e.Konum
                                         }).ToListAsync();

                return Ok(sertifikalar);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Mesaj = "Sertifikalar çekilirken hata: " + ex.Message });
            }
        }

        // =====================================================================
        // GET: api/Etkinlik/GecmisEtkinliklerim/5 — Öğrencinin katıldığı bitmiş etkinlikler
        // =====================================================================
        [HttpGet("GecmisEtkinliklerim/{ogrenciId}")]
        public async Task<IActionResult> GetGecmisEtkinliklerim(int ogrenciId)
        {
            try
            {
                var gecmisEtkinlikler = await (from k in _context.KatilimKaydis
                                              join e in _context.Etkinliks on k.EtkinlikId equals e.EtkinlikId
                                              where k.KullaniciId == ogrenciId && e.AktifMi != true
                                              select new
                                              {
                                                  etkinlikAdi = e.EtkinlikAdi,
                                                  konum = e.Konum,
                                                  tarih = e.TarihSaat,
                                                  durum = k.Durum,
                                                  kayitZamani = k.KayitZamani
                                              }).ToListAsync();

                return Ok(gecmisEtkinlikler);
            }
            catch (Exception ex)
            {
                return BadRequest(new { Mesaj = "Geçmiş etkinlikler yüklenirken hata: " + ex.Message });
            }
        }

        // =====================================================================
        // POST: api/Etkinlik/Bitir/5 — Etkinliği bitirir + toplu sertifika basar
        // =====================================================================
        [HttpPost("Bitir/{id}")]
        public async Task<IActionResult> EtkinligiBitir(int id)
        {
            try
            {
                var etkinlik = await _context.Etkinliks.FindAsync(id);
                if (etkinlik == null)
                    return NotFound(new { Mesaj = "Etkinlik bulunamadı!" });

                if (etkinlik.AktifMi == false)
                    return BadRequest(new { Mesaj = "Bu etkinlik zaten bitirilmiş!" });

                // 1. Etkinliği pasif yap
                etkinlik.AktifMi = false;

                // 2. Yoklaması alınmış ama sertifikası olmayan katılımcılara toplu sertifika bas
                var sertifikasizKayitlar = await _context.KatilimKaydis
                    .Where(k => k.EtkinlikId == id && k.Durum == "Katildi")
                    .Where(k => !_context.Sertifikas.Any(s => s.KayitId == k.KayitId))
                    .ToListAsync();

                foreach (var kayit in sertifikasizKayitlar)
                {
                    _context.Sertifikas.Add(new Sertifika
                    {
                        KayitId = kayit.KayitId,
                        UretimTarihi = DateTime.Now,
                        SertifikaKodu = Guid.NewGuid().ToString().Substring(0, 8).ToUpper()
                    });
                }

                await _context.SaveChangesAsync();

                var toplamSertifika = await _context.Sertifikas
                    .CountAsync(s => _context.KatilimKaydis
                        .Any(k => k.KayitId == s.KayitId && k.EtkinlikId == id));

                return Ok(new
                {
                    Mesaj = "Etkinlik başarıyla bitirildi!",
                    ToplamSertifika = toplamSertifika
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { Mesaj = "Etkinlik bitirme hatası: " + ex.Message });
            }
        }
    }

    // DTO: Kayıt ve Yoklama istekleri için
    public class KayitIstegi
    {
        public int OgrenciID { get; set; }
        public int EtkinlikID { get; set; }
    }
}