import hant.Log;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import tjson.TJSON;
using stdlib.StringTools;
using stdlib.Lambda;

class Downloader
{
	var reAttrValue = "(?:'([^']*)'|\"([^\"]*)\"|([-_a-z0-9]+))";
	
	var startListUrl : String;
	var nextListUrlRegex : EReg;
	var productUrlRegex : EReg;
	var productTextProperties : Array<{ name:String, re:EReg }>;
	var productFileProperties : Array<{ name:String, re:EReg }>;
	
	var processedLists = [];
	var toProcessLists = [];
	
	var processedProducts = [];
	var toProcessProducts = [];
	
	public function new
	(
		startListUrl:String,
		nextListUrlRegex:String,
		productUrlRegex:String,
		productTextProperties:Array<String>,
		productFileProperties:Array<String>
	)
	{
		this.startListUrl = startListUrl;
		this.nextListUrlRegex = new EReg(nextListUrlRegex, "");
		this.productUrlRegex = new EReg(productUrlRegex, "");
		this.productTextProperties = productTextProperties.map(function(s) { var ss = s.split(":"); return { name:ss[0], re:selectorToRegex(ss.slice(1).join(":")) }; });
		this.productFileProperties = productFileProperties.map(function(s) { var ss = s.split(":"); return { name:ss[0], re:selectorToRegex(ss.slice(1).join(":")) }; });
	}
	
	public function run()
	{
		toProcessLists.push(startListUrl);
		
		while (toProcessProducts.length > 0 || toProcessLists.length > 0)
		{
			while (toProcessProducts.length > 0)
			{
				var url = toProcessProducts.shift();
				processedProducts.push(url);
				
				Log.start("Process product page: " + url);
				var data = parseProduct(HttpTools.get(url));
				saveProduct(urlToFile(url) + "/data.config", data);
				Log.finishSuccess();
			}
			
			while (toProcessLists.length > 0)
			{
				var url = toProcessLists.shift();
				processedLists.push(url);
				
				Log.start("Process list page: " + url);
				processList(url, HttpTools.get(url));
				Log.finishSuccess();
			}
		}
	}
	
	function processList(baseUrl:String)
	{
		var text = HttpTools.get(baseUrl);
		
		for (url in getUrlsFromText(text, productUrlRegex))
		{
			if (processedProducts.indexOf(url) < 0 && toProcessProducts.indexOf(url) < 0)
			{
				toProcessProducts.push(url);
				Log.echo("Found link to product page: " + url);
			}
		}
		
		for (url in getUrlsFromText(text, nextListUrlRegex))
		{
			if (processedLists.indexOf(url) < 0 && toProcessLists.indexOf(url) < 0)
			{
				toProcessLists.push(url));
				Log.echo("Found link to list page: " + url);
			}
		}
	}
	
	function parseProduct(text:String) : Dynamic
	{
		var r : Dynamic = {};
		
		for (property in productTextProperties)
		{
			Reflect.setField(r, property.name, getPropertyFromText(text, property.re));
		}
		
		return r;
	}
	
	function saveProduct(jsonFilePath:String, data:Dynamic)
	{
		var dir = Path.directory(jsonFilePath);
		if (dir != null && dir != "" && !FileSystem.exists(dir))
		{
			FileSystem.createDirectory(dir);
		}
		File.saveContent(jsonFilePath, TJSON.encode(data));
	}
	
	function getUrlsFromText(text:String, baseUrl:String, re:EReg) : Array<String>
	{
		var r = [];
		
		var pos = 0;
		while (re.matchSub(text, pos))
		{
			var url = re.matched(0);
			r.push(url);
			var p = re.matchedPos();
			pos = p.pos + p.len;
		}
		
		return r.map.fn(makeUrlAbsolute(baseUrl, _));
	}
	
	function makeUrlAbsolute(baseUrl:String, url:String) : String
	{
		
	}
	
	function getPropertyFromText(text:String, re:EReg) : String
	{
		var r = [];
		
		var pos = 0;
		while (re.matchSub(text, pos))
		{
			var property : String = null;
			for (i in 1...10)
			{
				try property = re.matched(i) catch (_:Dynamic) {}
				if (!property.isEmpty()) break;
			}
			if (property.isEmpty()) try property = re.matched(0) catch (_:Dynamic) {}
			
			r.push(property);
			var p = re.matchedPos();
			pos = p.pos + p.len;
		}
		
		return r.join("\n\n");
	}
	
	function urlToFile(url:String) : String
	{
		return ~/[?()=*_]/g.map(url, function(re)
		{
			return switch (re.matched(0))
			{
				case "?": "_Q_";
				case "(": "_A_";
				case ")": "_B_";
				case "=": "_E_";
				case "*": "_S_";
				case "_": "___";
				case _: re.matched(0);
			}
		});
	}
	
	function selectorToRegex(selector:String) : EReg
	{
		var selectors = selector.split("@");
		
		var nodeSelector = selectors[0];
		var attrSelector = selectors.length > 1 ? selectors[1] : "";
		
		var parts = nodeSelector.split(">");
		var last = parts[parts.length - 1];
		
		var r = attrSelector == ""
				? parts.map.fn("[<]" + _ + "[^>]*?[>]").join(".*?") + "(.*?)[<][/]" + last + "[>]"
				: parts.slice(0, parts.length - 1).map.fn("[<]" + _).join("[^>]*?[>].*?") + "\\s+.*?" + attrSelector + "\\s*[=]\\s*" + reAttrValue;
		
		Log.echo("selectorToRegex: " + selector + " => " + r);
		
		return new EReg(r, "s");
	}
}