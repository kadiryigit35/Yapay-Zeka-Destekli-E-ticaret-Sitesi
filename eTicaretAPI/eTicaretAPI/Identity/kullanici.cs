using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Microsoft.AspNet.Identity.EntityFramework;
namespace eTicaretAPI.Identity
{
    public class kullanici:IdentityUser
    {
        public string Adi { get; set; }
        public string Soyadi { get; set; }
        public string ProfilResmi { get; set; }
        public bool BanliMi { get; set; } = false;
        public DateTime? BanBitisTarihi { get; set; }
        public string BanSebebi { get; set; }
    }
}