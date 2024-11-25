using Microsoft.EntityFrameworkCore;
using TestApi.Domain.Entities;

namespace TestApi.Domain.Context;

public class TestContext(DbContextOptions options) : DbContext(options)
{
    public DbSet<Summary> Summaries { get; set; }
}