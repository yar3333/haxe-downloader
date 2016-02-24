import hant.Log;
import haxe.io.Path;
import htmlparser.HtmlDocument;
import stdlib.Regex;
import sys.FileSystem;
import sys.io.File;
import tink.Url;
import tjson.TJSON;
import htmlparser.HtmlNodeElement;
using stdlib.StringTools;
using stdlib.Lambda;

class Downloader
{
	var outDir : String;
	var cacheDir : String;
	var outJsonFile : String;
	
	var listRegexes : Array<EReg>;
	var productRegexes : Array<EReg>;
	
	var productTextProperties : Array<{ name:String, selector:String, postRE:Regex }>;
	var productHtmlProperties : Array<{ name:String, selector:String, postRE:Regex }>;
	var productFileProperties : Array<{ name:String, selector:String, postRE:Regex }>;
	
	var processedLists = [];
	var toProcessLists : Array<String>;
	
	var processedProducts = [];
	var toProcessProducts : Array<String>;
	
	var outJsonData = [];
	
	public function new
	(
		outDir:String,
		cacheDir:String,
		outJsonFile:String,
		
		listUrls:Array<String>,
		listRegexes:Array<String>,
		
		productUrls:Array<String>,
		productRegexes:Array<String>,
		
		productTextProperties:Array<String>,
		productHtmlProperties:Array<String>,
		productFileProperties:Array<String>
	)
	{
		this.outDir = Path.removeTrailingSlashes(outDir);
		this.cacheDir = Path.removeTrailingSlashes(cacheDir);
		this.outJsonFile = outJsonFile;
		
		this.toProcessLists = listUrls.copy();
		this.listRegexes = listRegexes.map(function(s) return new EReg(s, ""));
		
		this.toProcessProducts = productUrls.copy();
		this.productRegexes = productRegexes.map(function(s) return new EReg(s, ""));
		
		this.productTextProperties = productTextProperties.map(parseNameAndSelector);
		this.productHtmlProperties = productHtmlProperties.map(parseNameAndSelector);
		this.productFileProperties = productFileProperties.map(parseNameAndSelector);
		
		Sys.println("");
	}
	
	public function run()
	{
		while (toProcessProducts.length > 0 || toProcessLists.length > 0)
		{
			while (toProcessProducts.length > 0)
			{
				var url = toProcessProducts.shift();
				processedProducts.push(url);
				processProduct(url);
			}
			
			while (toProcessLists.length > 0)
			{
				var url = toProcessLists.shift();
				processedLists.push(url);
				processList(url);
				
			}
		}
		
		if (outJsonFile != null && outJsonFile != "")
		{
			saveToFile(outJsonFile, TJSON.encode(outJsonData, "fancy"));
		}
	}
	
	function processList(baseUrl:String)
	{
		Log.start("Process list page: " + baseUrl);
		
		var text = getTextToParse(baseUrl);
		
		for (url in getUrlsFromText(text, baseUrl, productRegexes))
		{
			if (processedProducts.indexOf(url) < 0 && toProcessProducts.indexOf(url) < 0)
			{
				toProcessProducts.push(url);
				Log.echo("Found link to product page: " + url);
			}
		}
		
		for (url in getUrlsFromText(text, baseUrl, listRegexes))
		{
			if (processedLists.indexOf(url) < 0 && toProcessLists.indexOf(url) < 0)
			{
				toProcessLists.push(url);
				Log.echo("Found link to list page: " + url);
			}
		}
		
		Log.finishSuccess();
	}
	
	function processProduct(url:String)
	{
		Log.start("Process product page: " + url);
		
		var doc = new HtmlDocument(getTextToParse(url), true);
		
		var data : Dynamic = {};
		
		for (property in productTextProperties)
		{
			var value = getPropertyFromHtml(doc, property.selector, property.postRE, function(node) return node.innerText.trim());
			Reflect.setField(data, property.name, value);
			//if (value != null) Log.echo("Found property: " + property.name + " = " + value);
		}
		
		for (property in productHtmlProperties)
		{
			var value = getPropertyFromHtml(doc, property.selector, property.postRE, function(node) return node.innerHTML.trim());
			Reflect.setField(data, property.name, value);
			//if (value != null) Log.echo("Found property: " + property.name + " = " + value);
		}
		
		saveToFile(outDir + "/" + urlToFile(url) + "/data.config", TJSON.encode(data, "fancy"));
		
		outJsonData.push(data);
		
		Log.finishSuccess();
	}
	
	function getUrlsFromText(text:String, baseUrl:String, regexes:Array<EReg>) : Array<String>
	{
		var r = [];
		
		for (re in regexes)
		{
			var pos = 0;
			while (re.matchSub(text, pos))
			{
				var url = re.matched(0);
				r.push(url);
				var p = re.matchedPos();
				pos = p.pos + p.len;
			}
		}
		
		return r.map.fn(makeUrlAbsolute(baseUrl, _));
	}
	
	function makeUrlAbsolute(baseUrl:String, url:String) : String
	{
		var bu = Url.parse(baseUrl);
		return bu.resolve(url);
	}
	
	function getPropertyFromHtml(doc:HtmlDocument, selector:String, postRE:Regex, getValueFromNode:HtmlNodeElement->String) : String
	{
		var r = [];
		
		var selectors = selector.split("@");
		
		var nodeSelector = selectors[0];
		var attrSelector = selectors.length > 1 ? selectors[1] : "";
		
		for (node in doc.find(nodeSelector))
		{
			var v = attrSelector == "" ? getValueFromNode(node) : node.getAttribute(attrSelector);
			if (v == null) v = "";
			if (postRE != null) v = postRE.replace(v);
			
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
				case "*": "_S_";
				case "/": "_D_";
				case "_": "___";
				case _: re.matched(0);
			}
		});
	}
	
	function parseNameAndSelector(s:String)
	{
		var ss = s.split(":");
		return
		{
			name:     ss[0],
			selector: ss.slice(1, ss.length > 2 ? ss.length - 1 : ss.length).join(":"),
			postRE:   ss.length > 2 ? new Regex(ss[ss.length - 1]) : null
		}
	}
	
	function getTextToParse(url:String) : String
	{
		var cacheFile = cacheDir + "/" + urlToFile(url);
		
		if (FileSystem.exists(cacheFile))
		{
			return File.getContent(cacheFile);
		}
		else
		{
			var text = HttpTools.get(url);
			saveToFile(cacheFile, text);
			return text;
		}
	}
	
	function saveToFile(file:String, text:String)
	{
		var dir = Path.directory(file);
		if (dir != null && dir != "" && !FileSystem.exists(dir))
		{
			FileSystem.createDirectory(dir);
		}
		File.saveContent(file, text);
	}
}