using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using TestApi.Domain.Context;
using Microsoft.Extensions.Configuration;

namespace TestApi.Migrations;

public class MigrationsDbContextFactory : IDesignTimeDbContextFactory<TestContext>
{
    public TestContext CreateDbContext(string[] args)
    {
        var configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json")
            .AddEnvironmentVariables()
            .Build();

        var builder = new DbContextOptionsBuilder<TestContext>();
        var connectionString = configuration.GetConnectionString("TestContext");

        builder.UseNpgsql(connectionString,
            x => x.MigrationsAssembly(typeof(DBMigrations).Assembly.GetName().Name));

        return new TestContext(builder.Options);
    }
}