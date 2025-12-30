using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Microsoft.AspNet.Identity.EntityFramework;

namespace eTicaretAPI.Identity
{
    public class yetki:IdentityRole
    {
        public string Aciklama { get; set; }
        public yetki()
        {
              
        }
        public yetki( string rolename, string Aciklama)
        {
            this.Aciklama = Aciklama;
        }
    }
}