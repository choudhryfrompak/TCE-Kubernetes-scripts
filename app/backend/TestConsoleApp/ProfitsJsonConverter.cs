using System.Text.Json;
using ClosedXML.Excel;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;
using TestApi.Domain.Models;

namespace TestConsoleApp;

public class ProfitsJsonConverter
{
    public static async Task RunFilePipeline(string[] args, int? indentSize)
    {
        var builder = Host.CreateApplicationBuilder(args);

        builder.Configuration
            .AddUserSecrets<Program>()
            .AddEnvironmentVariables();


        builder.Services.Configure<FileConfig>(builder.Configuration.GetSection("FileConfig"));

        using IHost host = builder.Build();

        var fileConfigOption = host.Services.GetRequiredService<IOptionsMonitor<FileConfig>>();

        var files = Directory.GetFiles(fileConfigOption.CurrentValue.InputFolder, "*.xlsx");
        var options = new JsonSerializerOptions
        {
            WriteIndented = true,
            IndentSize = indentSize ?? 2
        };

        foreach (var filePath in files)
        {
            using var workbook = new XLWorkbook(filePath);
            var worksheet = workbook.Worksheet(1); // Gets first worksheet
            var rows = worksheet.RowsUsed();
            var profitRows = rows.Skip(1).Select(row => new ProfitRow()
            {
                Quarter = row.Cell(1).Value.ToString(), Year = row.Cell(2).Value.ToString(),
                Profit = row.Cell(3).Value.ToString(),
            }).ToList();
            
            var jsonString = JsonSerializer.Serialize(profitRows, options);
            Directory.CreateDirectory(fileConfigOption.CurrentValue.OutputFolder);
            var outFilePath = Path.Combine(fileConfigOption.CurrentValue.OutputFolder, "output.json");
            File.WriteAllText(outFilePath, jsonString);
        }
    }
}