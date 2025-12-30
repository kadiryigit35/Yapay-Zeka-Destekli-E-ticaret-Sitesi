using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace eTicaretSitesi.MvcWebUI.Models
{
    public class kayitOl
    {
        [Required]
        [DisplayName("Adınız")]
        public string Adi {  get; set; }
        [Required]
        [DisplayName("Soyadınız")]
        public string Soyadi { get; set; }
        [Required]
        [DisplayName("Kullanıcı Adı")]
        public string KullaniciAdi { get; set; }
        [Required]
        [DisplayName("Eposta")]
        [EmailAddress(ErrorMessage ="Epostanızı düzgün giriniz.")]
        public string Email { get; set; }
        [Required]
        [DisplayName("Şifre")]
        public string Sifre { get; set; }
        [Required]
        [DisplayName("Şifre Tekrar")]
        [Compare("Sifre",ErrorMessage="Şifreler uyuşmuyor.")]
        public string SifreTekrar { get; set; }
        
    }
}