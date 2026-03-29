using System;
using System.Collections.Generic;

namespace KampusEtkinlikAPI.Models;

public partial class KatilimKaydi
{
    public int KayitId { get; set; }

    public int? KullaniciId { get; set; }

    public int? EtkinlikId { get; set; }

    public string? Durum { get; set; }

    public DateTime? KayitZamani { get; set; }

    public virtual Etkinlik? Etkinlik { get; set; }

    public virtual Kullanici? Kullanici { get; set; }

    public virtual Sertifika? Sertifika { get; set; }
}
