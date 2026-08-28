using Equipify.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace Equipify.Api;

public class DesignTimeDbContextFactory : IDesignTimeDbContextFactory<EquipifyDbContext>
{
    public EquipifyDbContext CreateDbContext(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<EquipifyDbContext>();
        optionsBuilder.UseNpgsql("Host=localhost;Database=equipify_db");
        return new EquipifyDbContext(optionsBuilder.Options);
    }
}
