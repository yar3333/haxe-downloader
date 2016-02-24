import hant.Log;
import haxe.io.Path;
import htmlparser.HtmlDocument;
import sys.FileSystem;
import sys.io.File;
import tink.Url;
import tjson.TJSON;
using stdlib.StringTools;
using stdlib.Lambda;

class Downloader
{
	var reAttrValue = "(?:'([^']*)'|\"([^\"]*)\"|([-_a-z0-9]+))";
	
	var startListUrl : String;
	var nextListUrlRegex : EReg;
	var productUrlRegex : EReg;
	var productTextProperties : Array<{ name:String, selector:String }>;
	var productFileProperties : Array<{ name:String, selector:String }>;
	
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
		this.productTextProperties = productTextProperties.map(function(s) { var ss = s.split(":"); return { name:ss[0], selector:ss.slice(1).join(":") }; });
		this.productFileProperties = productFileProperties.map(function(s) { var ss = s.split(":"); return { name:ss[0], selector:ss.slice(1).join(":") }; });
		
		Sys.println("");
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
				processList(url);
				Log.finishSuccess();
			}
		}
	}
	
	function processList(baseUrl:String)
	{
		var text = HttpTools.get(baseUrl);
		
		for (url in getUrlsFromText(text, baseUrl, productUrlRegex))
		{
			if (processedProducts.indexOf(url) < 0 && toProcessProducts.indexOf(url) < 0)
			{
				toProcessProducts.push(url);
				Log.echo("Found link to product page: " + url);
			}
		}
		
		for (url in getUrlsFromText(text, baseUrl, nextListUrlRegex))
		{
			if (processedLists.indexOf(url) < 0 && toProcessLists.indexOf(url) < 0)
			{
				toProcessLists.push(url);
				Log.echo("Found link to list page: " + url);
			}
		}
	}
	
	function parseProduct(text:String) : Dynamic
	{
		var r : Dynamic = {};
		
		var doc = new HtmlDocument(text, true);
		
		for (property in productTextProperties)
		{
			var value = getPropertyFromHtml(doc, property.selector);
			Reflect.setField(r, property.name, value);
			if (value != null) Log.echo("Found property: " + property.name + " = " + value);
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
		File.saveContent(jsonFilePath, TJSON.encode(data, "fancy"));
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
		var bu = Url.parse(baseUrl);
		return bu.resolve(url);
	}
	
	function getPropertyFromHtml(doc:HtmlDocument, selector:String) : String
	{
		var r = [];
		
		var selectors = selector.split("@");
		
		var nodeSelector = selectors[0];
		var attrSelector = selectors.length > 1 ? selectors[1] : "";
		
		for (node in doc.find(nodeSelector))
		{
			var v = attrSelector == "" ? node.innerHTML : node.getAttribute(attrSelector);
			r.push(v != null ? v : "");
		}
		
		return r.length != 0 ? r.join("\n") : null;
	}
	
	function urlToFile(url:String) : String
	{
		var parts = Url.parse(url);
		return parts.host + "/" + ~/[?()=*\/_]/g.map(parts.path.ltrim("/") + (parts.query != null ? "?" + parts.query : ""), function(re)
		{
			return switch (re.matched(0))
			{
				case "?": "_Q_";
				case "(": "_A_";
				case ")": "_B_";
				case "=": "_E_";
				case "*": "_S_";
				case "/": "_D_";
				case "_": "___";
				case _: re.matched(0);
			}
		});
	}
}