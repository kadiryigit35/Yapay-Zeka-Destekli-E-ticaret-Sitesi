using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel;
using System.Linq;
using System.Web;

namespace eTicaretAPI.Models
{
    public class girisYap
    {
        [Required]
        [DisplayName("Kullanıcı Adı")]
        public string KullaniciAdi { get; set; }

        [Required]
        [DisplayName("Şifre")]
        public string Sifre { get; set; }
        [DisplayName("Beni Hatırla")]
        public bool BeniHatirla { get; set; }

    }
}