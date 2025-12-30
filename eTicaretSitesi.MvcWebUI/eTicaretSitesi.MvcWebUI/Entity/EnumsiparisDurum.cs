using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace eTicaretSitesi.MvcWebUI.Entity
{
    public enum EnumsiparisDurum
    {
        [Display(Name = "Sipariş Alındı")]
        SiparisAlındı = 0,

        [Display(Name = "Kargoya Verildi")]
        KargoyaVerildi = 1,

        [Display(Name = "Teslim Edildi")]
        TeslimEdildi = 2,

        [Display(Name = "İptal Edildi")]
        İptalEdildi = 3,

        // YENİ EKLENEN
        [Display(Name = "İade Edildi")]
        IadeEdildi = 4
    }

}