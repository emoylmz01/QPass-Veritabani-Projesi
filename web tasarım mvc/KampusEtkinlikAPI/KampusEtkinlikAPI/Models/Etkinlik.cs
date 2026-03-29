using System;
using System.Collections.Generic;

namespace KampusEtkinlikAPI.Models;

public partial class Etkinlik
{
    public int EtkinlikId { get; set; }

    public int? KulupId { get; set; }

    public string EtkinlikAdi { get; set; } = null!;

    public DateTime TarihSaat { get; set; }

    public string? Konum { get; set; }

    public int Kontenjan { get; set; }

    public int? YedekKontenjan { get; set; }

    public int? PuanDegeri { get; set; }

    public string? Aciklama { get; set; }

    public bool SertifikaliMi { get; set; } = true;

    public virtual ICollection<KatilimKaydi> KatilimKaydis { get; set; } = new List<KatilimKaydi>();

    public virtual Kulup? Kulup { get; set; }

    public bool? AktifMi { get; set; } = true;
}
