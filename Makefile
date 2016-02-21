# resources.blogscopia.com

blogscopia:
	neko bin/downloader.n \
		http://resources.blogscopia.com/category/models/ \
		http://resources.blogscopia.com/category/models/page/\\d+/ \
		http://resources.blogscopia.com/\\d+/\\d+/\\d+/[^/]+/ \
		--product-text-property "name:article>header>h1" \
		--product-text-property "description:article>div>p[2]" \
		--product-text-property "image:article>div>p>a>img@src" \
		--product-file-property "file:article>div>ul>li>a@href"
