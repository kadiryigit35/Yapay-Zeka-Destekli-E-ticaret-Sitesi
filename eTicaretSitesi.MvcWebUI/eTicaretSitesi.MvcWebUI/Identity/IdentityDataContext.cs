using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web;
using eTicaretSitesi.MvcWebUI.Entity;
using Microsoft.AspNet.Identity.EntityFramework;

namespace eTicaretSitesi.MvcWebUI.Identity
{
    public class IdentityDataContext : IdentityDbContext<kullanici>
    {
        public IdentityDataContext() : base ("baglanti")
        {

        }
    }
}