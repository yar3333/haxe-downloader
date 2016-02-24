import hant.CmdOptions;

class Main
{
    static function main()
    {
		var args = Sys.args();
		
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
			Sys.println("downloader arguments:");
			Sys.println(options.getHelpMessage());
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
}
