using KampusEtkinlikAPI.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace KampusEtkinlikAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class KulupUyelikController : ControllerBase
    {
        private readonly KampusEtkinlikDbContext _context;

        public KulupUyelikController(KampusEtkinlikDbContext context)
        {
            _context = context;
            try
            {
                // SQL Tablosu yoksa otomatik oluşturur (Migrations gerektirmez)
                _context.Database.ExecuteSqlRaw(@"
                    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='KulupUyesi' AND xtype='U')
                    BEGIN
                        CREATE TABLE KulupUyesi (
                            Id INT IDENTITY(1,1) PRIMARY KEY,
                            KulupId INT NOT NULL,
                            KullaniciId INT NOT NULL,
                            Durum NVARCHAR(20) DEFAULT 'Bekliyor',
                            BasvuruTarihi DATETIME DEFAULT GETDATE(),
                            CONSTRAINT FK_Kulup_KulupId FOREIGN KEY (KulupId) REFERENCES Kulup(KulupID) ON DELETE CASCADE,
                            CONSTRAINT FK_Kullanici_KullaniciId FOREIGN KEY (KullaniciId) REFERENCES Kullanici(KullaniciID) ON DELETE CASCADE,
                            CONSTRAINT UQ_KullaniciKulup UNIQUE(KulupId, KullaniciId)
                        )
                    END
                ");
            }
            catch (Exception ex)
            {
                Console.WriteLine("Table creation error: " + ex.Message);
            }
        }

        [HttpPost("BasvuruYap/{kullaniciId}/{kulupId}")]
        public async Task<IActionResult> BasvuruYap(int kullaniciId, int kulupId)
        {
            var existing = await _context.KulupUyeleris
                .FirstOrDefaultAsync(x => x.KullaniciId == kullaniciId && x.KulupId == kulupId);

            if (existing != null)
                return BadRequest(new { Mesaj = $"Zaten bu kulübe '{existing.Durum}' durumunda kaydınız var." });

            var yeni = new KulupUyesi
            {
                KullaniciId = kullaniciId,
                KulupId = kulupId,
                Durum = "Bekliyor",
                BasvuruTarihi = DateTime.Now
            };

            _context.KulupUyeleris.Add(yeni);
            await _context.SaveChangesAsync();

            return Ok(new { Mesaj = "Başvurunuz başarıyla alındı. Organizatör onayı bekleniyor." });
        }

        [HttpGet("UyeOlduguKulupler/{kullaniciId}")]
        public async Task<IActionResult> UyeOlduguKulupler(int kullaniciId)
        {
            var kulupler = await _context.KulupUyeleris
                .Include(x => x.Kulup)
                .Where(x => x.KullaniciId == kullaniciId && x.Durum == "Onaylandi")
                .Select(x => new
                {
                    kulupId = x.KulupId,
                    kulupAdi = x.Kulup.KulupAdi,
                    katilimTarihi = x.BasvuruTarihi
                })
                .ToListAsync();

            return Ok(kulupler);
        }

        [HttpGet("BekleyenTalepler/{kulupId}")]
        public async Task<IActionResult> BekleyenTalepler(int kulupId)
        {
            var talepler = await _context.KulupUyeleris
                .Include(x => x.Kullanici)
                .Where(x => x.KulupId == kulupId && x.Durum == "Bekliyor")
                .Select(x => new
                {
                    uyelikId = x.Id,
                    kullaniciId = x.KullaniciId,
                    kullaniciAdSoyad = x.Kullanici.Ad + " " + x.Kullanici.Soyad,
                    basvuruTarihi = x.BasvuruTarihi
                })
                .ToListAsync();

            return Ok(talepler);
        }

        [HttpPost("TalepYanitla/{uyelikId}/{kabulMu}")]
        public async Task<IActionResult> TalepYanitla(int uyelikId, bool kabulMu)
        {
            var uyelik = await _context.KulupUyeleris.FindAsync(uyelikId);
            if (uyelik == null)
                return NotFound(new { Mesaj = "Talep bulunamadı." });

            uyelik.Durum = kabulMu ? "Onaylandi" : "Reddedildi";
            
            await _context.SaveChangesAsync();

            return Ok(new { Mesaj = kabulMu ? "Talep onaylandı." : "Talep reddedildi." });
        }
    }
}
