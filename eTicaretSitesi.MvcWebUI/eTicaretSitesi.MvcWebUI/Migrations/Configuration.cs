namespace eTicaretSitesi.MvcWebUI.Migrations
{
    using System;
    using System.Data.Entity;
    using System.Data.Entity.Migrations;
    using System.Linq;

    internal sealed class Configuration : DbMigrationsConfiguration<eTicaretSitesi.MvcWebUI.Identity.IdentityDataContext>
    {
        public Configuration()
        {
            AutomaticMigrationsEnabled = false;
            ContextKey = "eTicaretSitesi.MvcWebUI.Identity.IdentityDataContext";
        }

        protected override void Seed(eTicaretSitesi.MvcWebUI.Identity.IdentityDataContext context)
        {
            //  This method will be called after migrating to the latest version.

            //  You can use the DbSet<T>.AddOrUpdate() helper extension method
            //  to avoid creating duplicate seed data.
        }
    }
}
