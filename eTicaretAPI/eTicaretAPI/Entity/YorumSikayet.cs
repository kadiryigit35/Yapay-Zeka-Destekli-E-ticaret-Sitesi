// eTicaretSitesi.MvcWebUI/Entity/YorumSikayet.cs

using System;
using System.ComponentModel.DataAnnotations;

namespace eTicaretAPI.Entity
{
    public class YorumSikayet
    {
        [Key]
        public int Id { get; set; }
        public int YorumId { get; set; }
        public virtual Yorum Yorum { get; set; }
        public string SikayetEdenKullaniciId { get; set; }
        public DateTime Tarih { get; set; }
        public bool IslemYapildiMi { get; set; } = false;
    }
}