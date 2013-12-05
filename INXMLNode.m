/*
 INXMLNode.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 9/23/11.
 Public Domain.
 
 This code is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE
 */


#import "INXMLNode.h"


@implementation INXMLNode


+ (instancetype)nodeWithName:(NSString *)aName attributes:(NSDictionary *)attributes
{
	INXMLNode *n = [self new];
	n.name = aName;
	n.attributes = [attributes mutableCopy];
	
	return n;
}



#pragma mark - Child Nodes
- (void)addChild:(INXMLNode *)aNode
{
	NSParameterAssert(aNode != nil);
	
	aNode.parent = self;
	if (!_children) {
		self.children = [NSMutableArray arrayWithObject:aNode];
	}
	else {
		[_children addObject:aNode];
	}
}

- (INXMLNode *)firstChild
{
	return [_children firstObject];
}

- (INXMLNode *)childNamed:(NSString *)childName
{
	NSParameterAssert([childName length] > 0);
	
	for (INXMLNode *child in _children) {
		if ([child.name isEqualToString:childName]) {
			return child;
		}
	}
	
	return nil;
}

- (NSArray *)childrenNamed:(NSString *)childName
{
	NSMutableArray *found = nil;
	if ([_children count] > 0) {
		found = [NSMutableArray array];
		
		for (INXMLNode *child in _children) {
			if ([child.name isEqualToString:childName]) {
				[found addObject:child];
			}
		}
	}
	
	return [found copy];
}



#pragma mark - Attributes
- (id)attr:(NSString *)attributeName
{
	NSParameterAssert([attributeName length] > 0);
	return _attributes[attributeName];
}

- (NSDecimalNumber *)numAttr:(NSString *)attributeName
{
	NSString *attr = [self attr:attributeName];
	if ([attr length] < 1) {
		return nil;
	}
	return [NSDecimalNumber decimalNumberWithString:attr];
}

- (BOOL)boolAttr:(NSString *)attributeName
{
	NSParameterAssert([attributeName length] > 0);
	
	NSString *attr = [self attr:attributeName];
	if ([attr length] < 1) {
		return NO;
	}
	if (NSOrderedSame == [@"null" compare:attr options:NSCaseInsensitiveSearch]
		|| NSOrderedSame == [@"0" compare:attr options:NSCaseInsensitiveSearch]
		|| NSOrderedSame == [@"false" compare:attr options:NSCaseInsensitiveSearch]
		|| NSOrderedSame == [@"no" compare:attr options:NSCaseInsensitiveSearch]) {
		return NO;
	}
	return YES;
}

- (void)setAttr:(NSString *)attrValue forKey:(NSString *)attrKey
{
	NSParameterAssert([attrKey length] > 0);
	
	if (attrValue) {
		if (!_attributes) {
			self.attributes = [NSMutableDictionary dictionaryWithObject:attrValue forKey:attrKey];
		}
		else {
			_attributes[attrKey] = attrValue;
		}
	}
	else {
		[_attributes removeObjectForKey:attrKey];
	}
}



#pragma mark - Body Values
- (BOOL)boolValue
{
	if (NSOrderedSame == [@"true" compare:_text options:NSCaseInsensitiveSearch]
		|| NSOrderedSame == [@"yes" compare:_text options:NSCaseInsensitiveSearch]
		|| NSOrderedSame == [@"1" compare:_text options:NSCaseInsensitiveSearch]) {
		return YES;
	}
	return NO;
}



#pragma mark - XML Generation
- (NSString *)xml
{
	if (0 == [_children count] && 0 == [_text length]) {
		return [NSString stringWithFormat:@"<%@ />", _name];
	}
	
	return [NSString stringWithFormat:@"<%@>%@</%@>", _name, [self childXML], _name];
}

- (NSString *)childXML
{
	if (0 == [_children count]) {
		return ([_text length] > 0) ? _text : nil;
	}
	
	NSMutableString *xml = [NSMutableString new];
	for (INXMLNode *child in _children) {
		[xml appendString:[child xml]];
	}
	
	return [xml copy];
}

- (NSString *)prettyXML
{
	return [self prettyXMLForLevel:0];
}

/**
 *  Creates an XML representation of the receiver with its child nodes, prepending tabs for the given depth.
 */
- (NSString *)prettyXMLForLevel:(NSUInteger)level
{
	NSMutableString *tabs = [NSMutableString stringWithString:@""];
	if (level > 0) {
		NSUInteger i = 0;
		for (; i < level; i++) {
			[tabs appendString:@"\t"];
		}
	}
	
	if (0 == [_children count]) {
		if ([_text length] > 0) {
			return [NSString stringWithFormat:@"%@<%@>%@</%@>", tabs, _name, _text, _name];
		}
		return [NSString stringWithFormat:@"%@<%@ />", tabs, _name];
	}
	
	NSMutableString *xml = [NSMutableString stringWithFormat:@"%@<%@>\n", tabs, _name];
	for (INXMLNode *child in _children) {
		[xml appendFormat:@"%@%@\n", tabs, [child prettyXMLForLevel:(level + 1)]];
	}
	[xml appendFormat:@"%@</%@>", tabs, _name];
	return xml;
}



#pragma mark - Utilities
- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@: %p> \"%@\"", NSStringFromClass([self class]), self, _name];
}


@end


@implementation INXMLTextNode


+ (instancetype)nodeWithText:(NSString *)text
{
	INXMLTextNode *n = [self new];
	n.text = text;
	
	return n;
}



#pragma mark - Text Handling
- (NSString *)xml
{
	return self.text;
}

- (NSString *)childXML
{
	return self.text;
}



#pragma mark - Children
- (void)addChild:(INXMLNode *)aNode
{
	NSAssert(NO, @"Text nodes cannot have child nodes");
}


@end
