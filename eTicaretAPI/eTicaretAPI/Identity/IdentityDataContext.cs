using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web;
using eTicaretAPI.Entity;
using Microsoft.AspNet.Identity.EntityFramework;

namespace eTicaretAPI.Identity
{
    public class IdentityDataContext : IdentityDbContext<kullanici>
    {
        public IdentityDataContext() : base ("baglanti")
        {

        }
    }
}