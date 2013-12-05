/*
 INServerCall.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 9/23/11.
 Public Domain.
 
 This code is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE
 */



@import Foundation;

#import "INXMLNode.h"


/**
 *  A simle XML Parser to parse XML into our XML nodes.
 */
@interface INXMLParser : NSObject <NSXMLParserDelegate>

/** If set to YES does not strip whitespace in text. */
@property (nonatomic) BOOL htmlMode;

/**
 *  Returns a dictionary generated from parsing the given XML string.
 *  This method only returns once parsing has completed. So think of performing the parsing on a separate thread if it could take a long time.
 *  @param xmlString An NSString containing the XML to parse
 *  @param error An NSError pointer which is guaranteed to not be nil if this method returns NO and a pointer was provided
 *  @return An INXMLNode representing the XML structure, or nil if parsing failed
 */
+ (INXMLNode *)parseXML:(NSString *)xmlString error:(NSError * __autoreleasing *)error;

/**
 *  Returns a dictionary generated from parsing the given XML string.
 *  This method only returns once parsing has completed. So think of performing the parsing on a separate thread if it could take a long time.
 *  @param htmlString An NSString containing the HTML to parse
 *  @param error An NSError pointer which is guaranteed to not be nil if this method returns NO and a pointer was provided
 *  @return An INXMLNode representing the HTML structure, or nil if parsing failed
 */
+ (INXMLNode *)parseHTML:(NSString *)xmlString error:(NSError * __autoreleasing *)error;

@end


#ifndef INERR
# define INERR(p, s, c) if (p != NULL && s) {\
	*p = [NSError errorWithDomain:NSXMLParserErrorDomain code:(c ? c : 0) userInfo:[NSDictionary dictionaryWithObject:s forKey:NSLocalizedDescriptionKey]];\
}
#endif
