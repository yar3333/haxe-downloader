blogscopia:
	neko bin/downloader.n \
		--output-directory bin/blogscopia \
		--cache-directory bin/cache \
		--output-json-file bin/blogscopia/data.json \
		--list-url http://resources.blogscopia.com/category/models/ \
		--list-regex http://resources.blogscopia.com/category/models/page/\\d+/ \
		--product-regex http://resources.blogscopia.com/\\d+/\\d+/\\d+/[^/]+/ \
		--product-text-property "name:article>header>h1" \
		--product-text-property "description:article>div>p[2]" \
		--product-text-property "image:article>div>p>a>img@src" \
		--product-file-property "file:article>div>ul>li>a@href"

php:
	neko bin/downloader.n \
		--output-directory bin/php \
		--cache-directory bin/cache \
		--output-json-file bin/php/data.json \
		--list-url "http://php.net/manual/en/ref.array.php" \
		--product-regex "function[.][a-zA-Z0-9_-]+[.]php" \
		--product-text-property "name:h1" \
		--product-text-property "prototype:div.methodsynopsis.dc-description:/[\\t\\r\\n ]+/ /" \
		--product-html-property "parameters:div.refsect1.parameters>p>dl:/[\\t\\r\\n ]+/ /" \
		--product-text-property "return:div.refsect1.returnvalues>p:/[\\t\\r\\n ]+/ /"

php-test:
	neko bin/downloader.n \
		--output-directory bin/php \
		--cache-directory bin/cache \
		--output-json-file bin/php/data.json \
		--product-url "http://php.net/manual/en/function.array-change-key-case.php" \
		--product-text-property "prototype:div.methodsynopsis.dc-description:/[\\t\\r\\n ]+/ /" \
		--product-html-property "parameters:div.refsect1.parameters>p>dl:/[\\t\\r\\n ]+/ /"
