INXMLParsing
============

Objective-C classes (requires ARC) to simplify:

- XML parsing
- Server communication

The classes were originally built for the [Indivo Framework][indivo], hence the "IN" prefix.


### Example

Here's a quick example on how you could load an XML file (from [PubMed][] in this case) and parse the XML to find specific nodes (MeSH headings in this case):

```objective-c
NSString *urlString = @"http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=23836201&retmode=xml";
NSURL *url = [NSURL URLWithString:urlString];
INURLLoader *loader = [INURLLoader loaderWithURL:url];

[loader getWithCallback:^(BOOL userDidCancel, NSString *__autoreleasing errorMessage) {
	if (!errorMessage && !userDidCancel) {
		
		// did receive XML, parse and extract MeshHeading
		NSError *error = nil;
		INXMLNode *root = [INXMLParser parseXML:loader.responseString error:&error];
		if (root) {
			NSAssert([@"PubmedArticleSet" isEqualToString:root.name], @"Expecting \"PubmedArticleSet\" to be the root XML node name, instead got \"%@\"", root.name);
			NSArray *headings = [[[[root childNamed:@"PubmedArticle"] childNamed:@"MedlineCitation"] childNamed:@"MeshHeadingList"] childrenNamed:@"MeshHeading"];
			
			// loop and log MeSH headings
			for (INXMLNode *heading in headings) {
				NSLog(@"=>  %@", [heading childNamed:@"DescriptorName"].text);
			}
		}
	}
}];
```

XML Parsing
-----------
Wraps `NSXMLParser` to simplify XML parsing and returns the XML tree as `INXMLNode` objects which have DOM traversing features built after [jQuery][].


Block-based Downloading
-----------------------
Wraps `NSURLConnection` and `NSURLResponse` into a block-based API for easy asynchronous interweb communication.


License
-------

This work has been put into the public domain, meaning if you want to use some of the code found here you can do so and don't have to attribute. Enjoy!

<p xmlns:dct="http://purl.org/dc/terms/">
  <a rel="license"
     href="http://creativecommons.org/publicdomain/zero/1.0/">
    <img src="http://i.creativecommons.org/p/zero/1.0/88x31.png" style="border-style: none;" alt="CC0" />
  </a>
  <br />
  To the extent possible under law,
  <span resource="[_:publisher]" rel="dct:publisher">
    <span property="dct:title">Pascal Pfiffner</span></span>
  has waived all copyright and related or neighboring rights to
  <span property="dct:title">INXMLParsing</span>.
</p>


[indivo]: https://github.com/chb/IndivoFramework-ios
[jquery]: http://jquery.com
[pubmed]: http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=23836201&retmode=xml
