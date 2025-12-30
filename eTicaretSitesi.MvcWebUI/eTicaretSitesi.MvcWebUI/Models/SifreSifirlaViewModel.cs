using System.ComponentModel.DataAnnotations;

namespace eTicaretSitesi.MvcWebUI.Models
{
    public class SifreSifirlaViewModel
    {
        [Required, EmailAddress]
        public string Email { get; set; }

        // Kod gönderildikten sonra görünür olacak
        public bool KodGonderildi { get; set; }

        public string GirilenKod { get; set; }

        // Kod doðruysa yeni þifre adýmý gösterilecek
        public bool KodDogruMu { get; set; }

        [DataType(DataType.Password)]
        public string YeniSifre { get; set; }

        [DataType(DataType.Password)]
        [Compare("YeniSifre", ErrorMessage = "Þifreler uyuþmuyor")]
        public string YeniSifreTekrar { get; set; }
    }
}
