import haxe.Http;
import haxe.io.BytesOutput;
import sys.net.Host;
using StringTools;

private typedef AbstractSocket =
{
	var input(default,null) : haxe.io.Input;
	var output(default,null) : haxe.io.Output;
	function connect( host : Host, port : Int ) : Void;
	function setTimeout( t : Float ) : Void;
	function write( str : String ) : Void;
	function close() : Void;
	function shutdown( read : Bool, write : Bool ) : Void;
}

class HttpTools
{
	public static function get(url:String, ?headers:Array<{ name:String, value:String }>) : String
	{
		var http = new Http(url);
		
		if (headers != null) for (h in headers) http.addHeader(h.name, h.value);
		
		http.onError = function(msg)
		{
			trace("ERROR get '" + url + "': " + msg);
		};
		
		http.noShutdown = true;
		http.cnxTimeout = 10;
		
		return request(false, http);
	}
	
	public static function post(url:String, ?params:Array<{ name:String, value:String }>, ?headers:Array<{ name:String, value:String }>) : String
	{
		var http = new Http(url);
		
		if (params != null) for (p in params) http.addParameter(p.name, p.value);
		if (headers != null) for (h in headers) http.addHeader(h.name, h.value);
		
		http.onError = function(msg)
		{
			trace("ERROR post '" + url + "': " + msg);
			trace(params);
			trace(headers);
		};
		
		http.noShutdown = true;
		http.cnxTimeout = 10;
		
		return request(true, http, params, headers);
	}
	
	static function request(post:Bool, http:Http, ?params:Array<{ name:String, value:String }>, ?headers:Array<{ name:String, value:String }>) : String
	{
		try
		{
			var buf = new BytesOutput();
			http.customRequest(post, buf, createSocket(http.url.startsWith("https://")));
			return buf.getBytes().toString();
		}
		catch (e:Dynamic)
		{
			trace("Error " + (post ? "post" : "get") + " request url '" + http.url + "':");
			if (params != null) trace(params);
			if (headers != null) trace(headers);
			neko.Lib.rethrow(e);
			return null;
		}
	}
	
	static function createSocket(secure:Bool) : AbstractSocket
	{
		if (secure)
		{
			var sock = null;
			
			#if php
			sock = new php.net.SslSocket();
			#elseif java
			sock = new java.net.SslSocket();
			#elseif hxssl
			#if neko
			sock = new neko.tls.Socket();
			#else
			sock = new sys.ssl.Socket();
			#end
			#else
			throw "Https is only supported with -lib hxssl";
			#end
			
			sock.validateCert = false;
			
			return sock;
		}
		
		return new sys.net.Socket();
	}
}