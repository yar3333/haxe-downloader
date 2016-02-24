import hant.CmdOptions;
import hant.Path;
import haxe.CallStack;
import neko.Lib;

class Main
{
    static function main()
    {
        var args = Sys.args();
		
		var exeDir = Path.normalize(Sys.getCwd());
		if (args.length > 0)
		{
			var dir = args.pop();
			try
			{
				Sys.setCwd(dir);
			}
			catch (e:Dynamic)
			{
				fail("Error: could not change dir to '" + dir + "'.");
			}
		}
		
		var options = new CmdOptions();
		
		options.add("outDir", "result", [ "--output-directory" ], "Destination directory to store parsed data and downloaded files. Default is 'result'.");
		options.add("cacheDir", "cache", [ "--cache-directory" ], "Destination directory to store cache files. Default is 'cache'.");
		options.add("outJsonFile", "", [ "--output-json-file" ], "Specify path to output JSON file if you want it.");
		
		options.addRepeatable("listUrls",              String, [ "--list-url" ],              "URL to download and parse to find other links.");
		options.addRepeatable("listRegexes",           String, [ "--list-regex" ],            "Regex to find additional URLs to download and parse to find other links.");
		options.addRepeatable("productUrls",           String, [ "--product-url" ],           "Manually specified URL to download and parse product.");
		options.addRepeatable("productRegexes",        String, [ "--product-regex" ],         "Regex to find URLs to product pages.");
		options.addRepeatable("productTextProperties", String, [ "--product-text-property" ], "Text-type property in 'name:css_selector[:regex_to_postprocess]' format.");
		options.addRepeatable("productHtmlProperties", String, [ "--product-html-property" ], "HTML-type property in 'name:css_selector[:regex_to_postprocess]' format.");
		options.addRepeatable("productFileProperties", String, [ "--product-file-property" ], "File-type property in 'name:css_selector[:regex_to_postprocess]' format.");
		
		if (args.length == 0)
		{
			Sys.println("Downloader is a tool to download and parse sites into JSON file.");
			Sys.println("Usage: haxelib run downloader <args>");
			Sys.println("where <args> may be:");
			Sys.println("");
			Sys.println(options.getHelpMessage());
			Sys.println("");
			Sys.println("Example:");
			Sys.println("");
			Sys.println("\thaxelib run downloader");
			Sys.println("\t\t--output-json-file bin/php/data.json \\");
			Sys.println("\t\t--list-url \"http://php.net/manual/en/ref.array.php\" \\");
			Sys.println("\t\t--product-regex \"function[.][a-zA-Z0-9_-]+[.]php\" \\");
			Sys.println("\t\t--product-text-property \"name:h1\" \\");
			Sys.println("\t\t--product-text-property \"prototype:div.methodsynopsis.dc-description:/[\\t\\r\\n ]+/ /\" \\");
			Sys.println("\t\t--product-html-property \"parameters:div.refsect1.parameters>p>dl:/[\\t\\r\\n ]+/ /\" \\");
			Sys.println("\t\t--product-text-property \"return:div.refsect1.returnvalues>p:/[\\t\\r\\n ]+/ /\"");
		}
		else
		{
			options.parse(args);
			
			Sys.println("");
			Sys.println("listUrls =\n\t" + options.get("listUrls").join("\n\t"));
			Sys.println("listRegexes =\n\t" + options.get("listRegexes").join("\n\t"));
			Sys.println("productUrls =\n\t" + options.get("productUrls").join("\n\t"));
			Sys.println("productRegexes =\n\t" + options.get("productRegexes").join("\n\t"));
			Sys.println("productTextProperties =\n\t" + options.get("productTextProperties").join("\n\t"));
			Sys.println("productHtmlProperties =\n\t" + options.get("productHtmlProperties").join("\n\t"));
			Sys.println("productFileProperties =\n\t" + options.get("productFileProperties").join("\n\t"));
			Sys.println("");
			
			var downloader = new Downloader
			(
				options.get("outDir"),
				options.get("cacheDir"),
				options.get("outJsonFile"),
				
				options.get("listUrls"),
				options.get("listRegexes"),
				
				options.get("productUrls"),
				options.get("productRegexes"),
				
				options.get("productTextProperties"),
				options.get("productHtmlProperties"),
				options.get("productFileProperties")
			);
			
			downloader.run();
		}
		
		return 0;
    }
	
	static function fail(message:String)
	{
		Lib.println("ERROR: " + message);
		Lib.println(CallStack.toString(CallStack.callStack()));
		Sys.exit(1);
	}
}
