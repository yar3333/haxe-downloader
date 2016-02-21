import hant.CmdOptions;

class Main
{
    static function main()
    {
		var args = Sys.args();
		
		var options = new CmdOptions();
		options.add("startListUrl", "", "Starting url to download and parse to find other links.");
		options.add("nextListUrlRegex", "", "Regex to find additional URLs to download and parse to find other links.");
		options.add("productUrlRegex", "", "Regex to find URLs to product pages.");
		options.addRepeatable("productTextProperty", String, [ "--product-text-property" ], "Text-type property name and selector to find element with a property value in 'name:selector' format.");
		options.addRepeatable("productFileProperty", String, [ "--product-file-property" ], "File-type property name and selector to find element with a property value in 'name:selector' format.");
		
		if (args.length == 0)
		{
			Sys.println("downloader arguments:");
			Sys.println(options.getHelpMessage());
		}
		else
		{
			options.parse(args);
			
			Sys.println("");
			Sys.println("startListUrl = " + options.get("startListUrl"));
			Sys.println("nextListUrlRegex = " + options.get("nextListUrlRegex"));
			Sys.println("productUrlRegex = " + options.get("productUrlRegex"));
			Sys.println("productTextProperty = " + options.get("productTextProperty"));
			Sys.println("productFileProperty = " + options.get("productFileProperty"));
			Sys.println("");
			
			var downloader = new Downloader
			(
				options.get("startListUrl"),
				options.get("nextListUrlRegex"),
				options.get("productUrlRegex"),
				options.get("productTextProperty"),
				options.get("productFileProperty")
			);
			
			downloader.run();
		}
		
		return 0;
    }
}
