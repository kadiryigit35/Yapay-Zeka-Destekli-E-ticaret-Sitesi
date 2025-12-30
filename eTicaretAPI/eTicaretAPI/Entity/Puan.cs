using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace eTicaretAPI.Entity
{
    public class Puan
    {
        [Key]
        public int Id { get; set; }

        public int UrunId { get; set; }
        public virtual urun Urun { get; set; }

        public string KullaniciId { get; set; }

        [Range(1, 5)]
        public int Deger { get; set; } // 1'den 5'e kadar puan

        public DateTime Tarih { get; set; }
    }
}