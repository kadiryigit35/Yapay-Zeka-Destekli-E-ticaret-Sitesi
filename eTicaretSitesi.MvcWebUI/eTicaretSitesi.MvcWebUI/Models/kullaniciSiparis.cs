using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using eTicaretSitesi.MvcWebUI.Entity;

namespace eTicaretSitesi.MvcWebUI.Models
{
    public class kullaniciSiparis
    {
        public int Id { get; set; }
        public string SiparisNumarasi { get; set; }
        public double Toplam { get; set; }
        public DateTime SiparisTarihi { get; set; }
        public EnumsiparisDurum siparisDurum { get; set; }
    }
}