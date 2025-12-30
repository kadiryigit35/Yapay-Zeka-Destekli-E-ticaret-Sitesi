// eTicaretSitesi.MvcWebUI/Entity/satici.cs

using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations.Schema; // Bu using ifadesini ekleyin
using System.Linq; // Bu using ifadesini ekleyin

namespace eTicaretSitesi.MvcWebUI.Entity
{
    public class satici
    {
        public int Id { get; set; }
        [DisplayName("Satýcý Adý")]
        public string Adi { get; set; }
        [DisplayName("Satýcý Hakkýnda")]
        public string Hakkinda { get; set; }
        public string Resim { get; set; }
        public string KullaniciId { get; set; }

        // YENÝ EKLENENLER
        public virtual ICollection<SaticiPuan> Puanlar { get; set; }

        [NotMapped]
        public double OrtalamaPuan => Puanlar != null && Puanlar.Any() ? Puanlar.Average(p => p.Deger) : 0;

        [NotMapped]
        public int ToplamPuanSayisi => Puanlar?.Count ?? 0;
    }
}