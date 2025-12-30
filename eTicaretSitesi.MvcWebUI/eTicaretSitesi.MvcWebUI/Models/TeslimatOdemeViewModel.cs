using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using eTicaretSitesi.MvcWebUI.Entity;

namespace eTicaretSitesi.MvcWebUI.Models
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
