using System;
using System.Linq;
using Microsoft.AspNetCore.Builder;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using TestApi.Domain.Context;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

builder.Services.AddDbContext<TestContext>(options =>
{
    var connStr = builder.Configuration.GetConnectionString("TestContext");
    options.UseNpgsql(connStr);
});
string[] existingSites =
    builder.Configuration
        .GetValue<string>("AllowedWebsites")
        ?.Split(new[] { "," }, StringSplitOptions.RemoveEmptyEntries) ?? Array.Empty<string>();

builder.Services.AddCors(options =>
{
    options.AddPolicy(
        "TestCorsPolicy",
        policy => policy.WithOrigins(existingSites).AllowAnyHeader().AllowAnyMethod()
    );
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseHttpsRedirection();


app.MapGet("/weatherforecast", (TestContext _context) =>
    {
        var summaries = _context.Summaries.Select(s => s.Description).ToList();
        var forecast = Enumerable.Range(1, 5).Select(index =>
                new WeatherForecast
                (
                    DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
                    Random.Shared.Next(-20, 55),
                    summaries[Random.Shared.Next(summaries.Count)]
                ))
            .ToArray();
        return forecast;
    })
    .WithName("GetWeatherForecast");

app.UseCors("TestCorsPolicy");
app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}