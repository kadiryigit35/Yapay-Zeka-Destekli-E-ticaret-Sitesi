using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Web;

namespace eTicaretAPI.Entity
{
    public class kategori
    {
        public int Id { get; set; }
        [DisplayName("Kategori Adı")]
        public string Adi { get; set; }
        [DisplayName("Açıklama")]
        public string Aciklama { get; set; }
        public List<urun> uruns { get; set; }
    }

}