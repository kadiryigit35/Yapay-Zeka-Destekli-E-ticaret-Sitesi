using System.ComponentModel.DataAnnotations;

namespace eTicaretSitesi.MvcWebUI.Models
{
    public class odemeBilgileri
    {
        [Required(ErrorMessage = "Kart Sahibi Adý gerekli")]
        public string KartSahibi { get; set; }

        [Required(ErrorMessage = "Kart Numarasý gerekli")]
        public string KartNumarasi { get; set; }

        [Required(ErrorMessage = "Son kullanma tarihi gerekli")]
        public string SonKullanma { get; set; }

        [Required(ErrorMessage = "CVC gerekli")]
        public string Cvc { get; set; }
    }
}
