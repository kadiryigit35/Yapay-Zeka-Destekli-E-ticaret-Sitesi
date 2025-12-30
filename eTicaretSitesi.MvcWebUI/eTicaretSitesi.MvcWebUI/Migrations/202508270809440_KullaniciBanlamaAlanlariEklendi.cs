namespace eTicaretSitesi.MvcWebUI.Migrations
{
    using System;
    using System.Data.Entity.Migrations;
    
    public partial class KullaniciBanlamaAlanlariEklendi : DbMigration
    {
        public override void Up()
        {
            AddColumn("dbo.AspNetUsers", "BanliMi", c => c.Boolean(nullable: false));
            AddColumn("dbo.AspNetUsers", "BanBitisTarihi", c => c.DateTime());
            AddColumn("dbo.AspNetUsers", "BanSebebi", c => c.String());
        }
        
        public override void Down()
        {
            DropColumn("dbo.AspNetUsers", "BanSebebi");
            DropColumn("dbo.AspNetUsers", "BanBitisTarihi");
            DropColumn("dbo.AspNetUsers", "BanliMi");
        }
    }
}
