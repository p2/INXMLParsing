/*
 INXMLParser.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 9/23/11.
 Public Domain.
 
 This code is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE
 */


#import "INXMLParser.h"
#if WITH_XML_VALIDATION
# include <libxml/xmlschemastypes.h>
#endif


@interface INXMLParser()

@property (strong, nonatomic) INXMLNode *rootNode;
@property (strong, nonatomic) INXMLNode *currentNode;
@property (strong, nonatomic) NSMutableString *stringBuffer;

@property (copy, nonatomic) NSString *errorOnLine;						///< We capture XML parsing errors here to provide line/column feedback for malformed XML

#if WITH_XML_VALIDATION
void xmlSchemaValidityError(void **ctx, const char *format, ...);
#endif

@end


@implementation INXMLParser


+ (INXMLNode *)parseXML:(NSString *)xmlString error:(NSError * __autoreleasing *)error
{
	INXMLParser *p = [self new];
	return [p parseXML:xmlString error:error];
}

+ (INXMLNode *)parseHTML:(NSString *)htmlString error:(NSError * __autoreleasing *)error
{
	INXMLParser *p = [self new];
	p.htmlMode = YES;
	return [p parseXML:htmlString error:error];
}



#pragma mark - XML Parsing
/**
 *  Starts parsing the given XML string.
 *  This method only returns once parsing has completed. So think of performing the parsing on a separate thread if it could take a long time.
 *  @param xmlString An NSString containing the XML to parse
 *  @param error An NSError pointer which is guaranteed to not be nil if this method returns NO and a pointer was provided
 *  @return An INXMLNode representing the XML structure, or nil if parsing failed
 */
- (INXMLNode *)parseXML:(NSString *)xmlString error:(NSError * __autoreleasing *)error
{
	if ([xmlString length] < 1) {
		INERR(error, @"No XML string provided", 0)
		return nil;
	}
	
	// init parser
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[xmlString dataUsingEncoding:NSUTF8StringEncoding]];
	parser.delegate = self;
	self.errorOnLine = nil;
	self.stringBuffer = [NSMutableString string];
	self.rootNode = [INXMLNode nodeWithName:@"root" attributes:nil];
	self.currentNode = _rootNode;
	
	// start parsing and handle any error
	BOOL ret = [parser parse];
	if (!ret || !_rootNode) {
		NSString *errStr = _errorOnLine ? _errorOnLine : ([parser parserError] ? [[parser parserError] localizedDescription] : @"Parser Error");
		NSInteger errCode = parser.parserError ? [parser.parserError code] : 0;
		INERR(error, errStr, errCode)
		
		self.rootNode = nil;
	}
	else if (error) {
		*error = nil;
	}
	
	// cleanup and return
	self.stringBuffer = nil;
	
	return _rootNode;
}

- (NSString *)currentStringBuffer
{
	NSString *trimmed = [_stringBuffer length] > 0 ? [_stringBuffer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] : nil;
	if (0 == [trimmed length]) {
		return nil;
	}
	
	return _htmlMode ? [_stringBuffer copy] : trimmed;
}



#pragma mark - XML Parser Delegate
/**
 *  Called when the parser encounters a start tag for a given element.
 */
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{
	INXMLNode *node = [INXMLNode nodeWithName:elementName attributes:attributeDict];
	if (_currentNode) {
		
		// do we have text in the buffer?
		NSString *trimmed = [self currentStringBuffer];
		if (trimmed) {
			[_currentNode addChild:[INXMLTextNode nodeWithText:trimmed]];
			[_stringBuffer setString:@""];
		}
		
		// append
		[_currentNode addChild:node];
	}
	else {
		NSAssert(NO, @"Oops, error while parsing, closed child beyond root node!");
	}
	self.currentNode = node;
}

/**
 *  Sent when the parser encounters an end tag for a specific element
 */
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	NSString *trimmed = [self currentStringBuffer];
	if (trimmed) {
		if ([_currentNode.children count] > 0) {
			[_currentNode addChild:[INXMLTextNode nodeWithText:trimmed]];
		}
		else {
			_currentNode.text = trimmed;
		}
	}
	[_stringBuffer setString:@""];
	
	// move a level up
	self.currentNode = _currentNode.parent;
}

/**
 *  Sent by a parser object to provide us with a string representing all or part of the characters of the current element
 */
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	[_stringBuffer appendString:string];
}

/**
 *  When this method is invoked, parsing is stopped
 */
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
	self.errorOnLine = [NSString stringWithFormat:@"Parser error occurred on line %d, column %d", [parser lineNumber], [parser columnNumber]];
}

/**
 *  Finished the document, we remove our artificial root node unless there were several top-level elements in the XML
 */
- (void)parserDidEndDocument:(NSXMLParser *)parser
{
	if (1 == [_rootNode.children count]) {
		self.rootNode = _rootNode.children[0];
	}
}



#if WITH_XML_VALIDATION
#pragma mark - XML Validation
/**
 *  Validates an XML string against an XSD at the given path.
 *  Boldy transcribed from: http://knol2share.blogspot.com/2009/05/validate-xml-against-xsd-in-c.html
 */
+ (BOOL)validateXML:(NSString *)xmlString againstXSD:(NSString *)xsdPath error:(__autoreleasing NSError **)error
{
	BOOL success = NO;
	xmlLineNumbersDefault(1);
	
	const char *xsd_path = [xsdPath cStringUsingEncoding:NSUTF8StringEncoding];
	
	// parse the schema
	xmlSchemaParserCtxtPtr ctx = xmlSchemaNewParserCtxt(xsd_path);
	xmlSchemaSetParserErrors(ctx, (xmlSchemaValidityErrorFunc) fprintf, (xmlSchemaValidityWarningFunc) fprintf, stderr);
	xmlSchemaPtr schema = xmlSchemaParse(ctx);
	xmlSchemaFreeParserCtxt(ctx);
	
	if (NULL == schema) {
		NSString *errStr = [NSString stringWithFormat:@"Failed to parse the schema at %@", xsdPath];
		INERR(error, errStr, 0);
	}
	
	// get our XML into an xmlDocPtr
	else {
		const char *xml = [xmlString cStringUsingEncoding:NSUTF8StringEncoding];
		int len = (int)strlen(xml);
		xmlDocPtr doc = xmlParseMemory(xml, len);
		
		if (NULL == doc) {
			NSString *errStr = [NSString stringWithFormat:@"Failed to parse input XML:\n%@", xmlString];
			INERR(error, errStr, 0);
		}
		
		// XML parsed successfully, validate!
		else {
			xmlSchemaValidCtxtPtr validCtx = xmlSchemaNewValidCtxt(schema);
			char *errorCap = NULL;
			xmlSchemaSetValidErrors(validCtx, (xmlSchemaValidityErrorFunc)xmlSchemaValidityError, (xmlSchemaValidityWarningFunc)xmlSchemaValidityError, &errorCap);
			int ret = xmlSchemaValidateDoc(validCtx, doc);
			if (0 == ret) {
				success = YES;
			}
			else {
				NSString *errStr = [NSString stringWithCString:(errorCap ? errorCap : "Unknown Error") encoding:NSUTF8StringEncoding];
				INERR(error, errStr, 0);
			}
			
			xmlSchemaFreeValidCtxt(validCtx);
			xmlFreeDoc(doc);
		}
		
		xmlSchemaFree(schema);
	}
	xmlSchemaCleanupTypes();
	xmlCleanupParser();
	xmlMemoryDump();
	
	return success;
}


void xmlSchemaValidityError(void **ctx, const char *format, ...)
{
	va_list ap;
	va_start(ap, format);
	char *str = (char *)va_arg(ap, int);
	
	// try to put str into ctx
	if (ctx) {
		*ctx = str;
	}
	else {
		NSLog(@"VALIDATION ERROR: %s", str);
	}
	va_end(ap);
}
#endif


@end
