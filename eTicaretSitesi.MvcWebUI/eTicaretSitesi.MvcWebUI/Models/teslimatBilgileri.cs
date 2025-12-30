using System.ComponentModel.DataAnnotations;

namespace eTicaretSitesi.MvcWebUI.Models
{
    public class teslimatBilgileri
    {
        public string TamAd { get; set; }

        [Required(ErrorMessage = "Lütfen Adres Tanımını Girin")]
        public string AdresBasligi { get; set; }

        [Required(ErrorMessage = "Lütfen Bir Adres Girin")]
        public string Adres { get; set; }

        [Required(ErrorMessage = "Lütfen Sehir Girin")]
        public string Sehir { get; set; }

        [Required(ErrorMessage = "Lütfen Mahalle Girin")]
        public string Mahalle { get; set; }

        [Required(ErrorMessage = "Lütfen Sokak Girin")]
        public string Sokak { get; set; }

        public string PostaKodu { get; set; }
        public string Eposta { get; set; }

        [Required(ErrorMessage = "Lütfen Telefon Numarası Girin")]
        [Phone(ErrorMessage = "Geçerli bir telefon numarası girin")]
        public string Telefon { get; set; }
    }
}
