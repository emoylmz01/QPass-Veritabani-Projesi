using System;
using System.Collections.Generic;

namespace KampusEtkinlikAPI.Models;

public partial class Sertifika
{
    public int SertifikaId { get; set; }

    public int? KayitId { get; set; }

    public string SertifikaKodu { get; set; } = null!;

    public DateTime? UretimTarihi { get; set; }

    public virtual KatilimKaydi? Kayit { get; set; }
}
