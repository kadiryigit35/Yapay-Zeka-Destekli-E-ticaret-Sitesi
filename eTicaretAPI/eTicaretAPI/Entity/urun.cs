
using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Web;

namespace eTicaretAPI.Entity
{
    public class urun
    {
        public int Id { get; set; }
        [DisplayName("Ürün Adı")]
        public string Adi { get; set; }
        [DisplayName("Ürün Açıklaması")]
        public string Aciklama { get; set; }
        public double Fiyat { get; set; }
        public int Stok { get; set; }
        public string Resim { get; set; }
        public int kategoriId { get; set; }
        public int saticiId { get; set; }
        public kategori Kategori { get; set; }
        public satici Satici { get; set; }

        public virtual ICollection<Yorum> Yorumlar { get; set; }
        // --- YENİ EKLENENLER ---
        public virtual ICollection<Puan> Puanlar { get; set; }

        [NotMapped]
        public double OrtalamaPuan
        {
            get
            {
                if (Puanlar != null && Puanlar.Any())
                {
                    return Puanlar.Average(p => p.Deger);
                }
                return 0;
            }
        }

        [NotMapped]
        public int ToplamPuanSayisi
        {
            get
            {
                if (Puanlar != null)
                {
                    return Puanlar.Count;
                }
                return 0;
            }
        }
    }
}