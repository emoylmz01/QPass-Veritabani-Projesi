using System;
using System.Collections.Generic;

namespace KampusEtkinlikAPI.Models;

public partial class VwDetayliKatilimListesi
{
    public string OgrenciAdi { get; set; } = null!;

    public string EtkinlikAdi { get; set; } = null!;

    public string? Durum { get; set; }

    public DateTime? KayitZamani { get; set; }

    public string? SertifikaKodu { get; set; }
}
