/*
 INXMLNode.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 9/23/11.
 Public Domain.
 
 This code is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE
 */


@import Foundation;


/**
 *  A class to represent one node in an XML document
 */
@interface INXMLNode : NSObject

@property (weak, nonatomic) INXMLNode *parent;

@property (copy, nonatomic) NSString *name;
@property (strong, nonatomic) NSMutableDictionary *attributes;
@property (strong, nonatomic) NSMutableArray *children;
@property (copy, nonatomic) NSString *text;

+ (instancetype)nodeWithName:(NSString *)aName attributes:(NSDictionary *)attributes;


#pragma mark - Attributes
/**
 *  A shortcut to get the object representing the attribute with the given name.
 */
- (id)attr:(NSString *)attributeName;

/**
 *  Returns the attribute as an NSDecimalNumber.
 *
 *  If the value is not numeric you will probably get what you deserve.
 */
- (NSDecimalNumber *)numAttr:(NSString *)attributeName;

/**
 *  Tries to interpret an attribute as a bool value.
 *
 *  Returns NO if the attribute:
 *
 *  - is missing
 *  - is empty
 *  - reads "null", "0", "false" or "no"
 */
- (BOOL)boolAttr:(NSString *)attributeName;

/**
 *  Sets an attribute.
 *  @param attrValue The value to set for the given key
 *  @param attrKey The key for the attribute, must be a string with length 1+
 */
- (void)setAttr:(NSString *)attrValue forKey:(NSString *)attrKey;


#pragma mark - Body Values
/**
 *  Returns a boolean value by interpreting the text content.
 *
 *  Any form of "true", "yes" and 1 returns a YES, everything else a NO.
 */
- (BOOL)boolValue;


#pragma mark - Child Nodes
/**
 *  Add a child node.
 */
- (void)addChild:(INXMLNode *)aNode;

/**
 *  Returns the first child node (or nil).
 */
- (INXMLNode *)firstChild;

/**
 *  Returns the first child node matching the given name.
 *
 *  Only direct child nodes are checked, no deep searching is performed.
 *  @param childName The node name of the child node to be returned
 */
- (INXMLNode *)childNamed:(NSString *)childName;

/**
 *  Searches child nodes for a node with the given name.
 *
 *  Only the direct child nodes are checked, no deep searching is performed.
 *  @param childName The node name of the child nodes to be returned
 *  @return Returns an array with nodes matching the name, nil otherwise
 */
- (NSArray *)childrenNamed:(NSString *)childName;


#pragma mark - Generating XML
/**
 *  Create an XML representation of the receiver with its child nodes.
 */
- (NSString *)xml;

/**
 *  Returns the node's content as XML.
 */
- (NSString *)childXML;

/**
 *  Create an XML representation of the receiver with its child nodes, nicely formatted.
 */
- (NSString *)prettyXML;

@end


/**
 *  Represents a text node in the DOM.
 *  
 *  @attention Text nodes cannot have child nodes, like in DOM.
 */
@interface INXMLTextNode : INXMLNode

+ (instancetype)nodeWithText:(NSString *)text;

@end
