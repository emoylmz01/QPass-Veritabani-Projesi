using System;
using System.Collections.Generic;

namespace KampusEtkinlikAPI.Models;

public partial class Kullanici
{
    public int KullaniciId { get; set; }

    public string Ad { get; set; } = null!;

    public string Soyad { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string? Sifre { get; set; }
    public string Rol { get; set; } = null!;

    public int? GuvenilirlikPuani { get; set; }

    public int? OyunlastirmaPuani { get; set; }

    public virtual ICollection<KatilimKaydi> KatilimKaydis { get; set; } = new List<KatilimKaydi>();
}
