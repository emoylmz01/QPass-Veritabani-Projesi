using System;
using System.Collections.Generic;

namespace KampusEtkinlikAPI.Models;

public partial class Kulup
{
    public int KulupId { get; set; }

    public string KulupAdi { get; set; } = null!;

    public string? IletisimEmail { get; set; }

    public decimal? OrtalamaPuan { get; set; }

    public virtual ICollection<Etkinlik> Etkinliks { get; set; } = new List<Etkinlik>();
}
