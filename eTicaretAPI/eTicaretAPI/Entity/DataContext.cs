using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Web;
using eTicaretAPI.Identity;
using Microsoft.AspNet.Identity.EntityFramework;

namespace eTicaretAPI.Entity
{
    public class DataContext : DbContext
    {
        public DataContext() : base("baglanti")
        {
            
        }
        public DbSet<urun> urunler { get; set; }
        public DbSet<kategori> kategori { get; set; }
        public DbSet<siparis> siparisler { get; set; }
        public DbSet<satici> saticilar { get; set; }
        public DbSet<Yorum> Yorumlar { get; set; }
        public DbSet<Favori> Favoriler { get; set; }
        public DbSet<kayitliAdres> KayitliAdresler { get; set; }
        public DbSet<kayitliOdemeYontemi> KayitliOdemeYontemleri { get; set; }
        public DbSet<siparisYolu> siparisYolu { get; set; }
        public DbSet<Puan> Puanlar { get; set; }
        public DbSet<SaticiPuan> SaticiPuanlari { get; set; }
        public DbSet<YorumSikayet> YorumSikayetleri { get; set; }

    }
}