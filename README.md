INXMLParsing
============

Objective-C classes (requires ARC) to simplify:

- XML parsing
- Server communication

The classes were originally built for the [Indivo Framework][], hence the "IN" prefix.


XML Parsing
-----------
Wraps `NSXMLParser` to simplify XML parsing and returns the XML tree as `INXMLNode` objects which have features built after [jQuery][].


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


[jquery]: http://jquery.com