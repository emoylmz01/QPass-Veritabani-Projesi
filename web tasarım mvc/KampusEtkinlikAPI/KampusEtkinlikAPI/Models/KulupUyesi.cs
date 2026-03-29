using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KampusEtkinlikAPI.Models
{
    [Table("KulupUyesi")]
    public class KulupUyesi
    {
        [Key]
        public int Id { get; set; }

        [Required]
        public int KulupId { get; set; }
        
        [ForeignKey("KulupId")]
        public virtual Kulup Kulup { get; set; } = null!;

        [Required]
        public int KullaniciId { get; set; }

        [ForeignKey("KullaniciId")]
        public virtual Kullanici Kullanici { get; set; } = null!;

        [Required]
        [MaxLength(20)]
        public string Durum { get; set; } = "Bekliyor"; // "Bekliyor", "Onaylandi", "Reddedildi"

        public DateTime BasvuruTarihi { get; set; } = DateTime.Now;
    }
}
