// See https://aka.ms/new-console-template for more information

using System.CommandLine;
using TestConsoleApp;

var rootCommand =
    new RootCommand("Test pipeline that can process excel file to json");


// file pipeline command
var indentSizeOption = new Option<int?>
(name: "--indentSize",
    description: "Indentation size in json output. Default is 2.");
indentSizeOption.AddAlias("-i");
var filePipelineCommand = new Command("convert",
    "Test pipeline that can process excel file to json");
filePipelineCommand.AddOption(indentSizeOption);
rootCommand.Add(filePipelineCommand);

filePipelineCommand.SetHandler(
    async (indentSize) => { await ProfitsJsonConverter.RunFilePipeline(args, indentSize); },
    indentSizeOption);

return await rootCommand.InvokeAsync(args);