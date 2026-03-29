using Microsoft.AspNetCore.Mvc;

namespace KampusEtkinlikAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DuyuruController : ControllerBase
    {
        // Basit simülasyon: Veritabanında (SQL) tablo olmadığı için in-memory kullanıyoruz.
        private static readonly List<DuyuruItem> _duyurular = new List<DuyuruItem>
        {
            new DuyuruItem { Kulup = "Kampüs Yönetimi", Mesaj = "Sisteme hoş geldiniz! Etkinlik biletleri aktif edilmiştir.", Zaman = DateTime.Now.AddDays(-1) }
        };

        [HttpGet]
        public IActionResult GetDuyurular()
        {
            var sonuc = _duyurular.OrderByDescending(d => d.Zaman).Select(d => new
            {
                kulup = d.Kulup,
                mesaj = d.Mesaj,
                zaman = HesaplaGecenSure(d.Zaman)
            });

            return Ok(sonuc);
        }

        [HttpPost]
        public IActionResult DuyuruEkle([FromBody] YeniDuyuruIstek istek)
        {
            if (string.IsNullOrWhiteSpace(istek.Mesaj))
                return BadRequest(new { Mesaj = "Duyuru mesajı boş olamaz." });

            var yeniDuyuru = new DuyuruItem
            {
                Kulup = string.IsNullOrWhiteSpace(istek.KulupAdi) ? "Bilinmeyen Topluluk" : istek.KulupAdi,
                Mesaj = istek.Mesaj,
                Zaman = DateTime.Now
            };

            _duyurular.Add(yeniDuyuru);
            return Ok(new { Mesaj = "Duyuru başarıyla yayınlandı!" });
        }

        private static string HesaplaGecenSure(DateTime zaman)
        {
            var fark = DateTime.Now - zaman;
            if (fark.TotalMinutes < 60) return $"{(int)fark.TotalMinutes} dakika önce";
            if (fark.TotalHours < 24) return $"{(int)fark.TotalHours} saat önce";
            return $"{(int)fark.TotalDays} gün önce";
        }
    }

    public class DuyuruItem
    {
        public string Kulup { get; set; } = null!;
        public string Mesaj { get; set; } = null!;
        public DateTime Zaman { get; set; }
    }

    public class YeniDuyuruIstek
    {
        public string KulupAdi { get; set; } = null!;
        public string Mesaj { get; set; } = null!;
    }
}
