using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using eTicaretAPI.Entity;

namespace eTicaretAPI.Models
{
    public class TeslimatOdemeViewModel
    {
        public teslimatBilgileri Teslimat { get; set; }
        public odemeBilgileri Odeme { get; set; }

        public bool AdresiKaydet { get; set; }
        public bool OdemeyiKaydet { get; set; }

        public List<kayitliAdres> KayitliAdresler { get; set; }
        public List<kayitliOdemeYontemi> KayitliOdemeYontemleri { get; set; }

        public int? SecilenAdresId { get; set; }
        public int? SecilenOdemeId { get; set; }
    }
}
