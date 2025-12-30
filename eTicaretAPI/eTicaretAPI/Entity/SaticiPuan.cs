

using System;
using System.ComponentModel.DataAnnotations;

namespace eTicaretAPI.Entity
{
    public class SaticiPuan
    {
        [Key]
        public int Id { get; set; }
        public int SaticiId { get; set; }
        public virtual satici Satici { get; set; }
        public string KullaniciId { get; set; }
        [Range(1, 5)]
        public int Deger { get; set; }
        public DateTime Tarih { get; set; }
    }
}