// eTicaretAPI/Models/KullaniciYonetimViewModel.cs
using System;
using System.Collections.Generic;

namespace eTicaretAPI.Models
{
    public class KullaniciYonetimViewModel
    {
        public string Id { get; set; }
        public string KullaniciAdi { get; set; }
        public string Email { get; set; }
        public List<string> Roller { get; set; }
        public bool BanliMi { get; set; }
        public DateTime? BanBitisTarihi { get; set; }
        public string BanSebebi { get; set; }
    }

    public class BanlamaModel
    {
        public string KullaniciId { get; set; }
        public int? SureGun { get; set; } // Null ise kalıcı ban
        public string Sebep { get; set; }
        public bool YorumlariSil { get; internal set; }
        public List<int> SilinecekYorumlar { get; set; } // Nullable kullanma
    }
}