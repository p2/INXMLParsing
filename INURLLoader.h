/*
 INURLLoader.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 10/13/11.
 Public Domain.
 
 This code is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE
 */

@import Foundation;

#define kINURLLoaderDefaultTimeoutInterval 60.0								///< timeout interval in seconds

extern NSString *const INErrorKey;


/**
 *  A block returning a success flag and a user info dictionary.
 *  If success is NO, you might find an NSError object in userInfo with key "INErrorKey". If no error is present, the operation was cancelled.
 */
typedef void (^INSuccessRetvalueBlock)(BOOL success, NSDictionary * __autoreleasing userInfo);

/**
 *  A block returning a flag whether the user cancelled and an error message on failure, nil otherwise.
 *  If userDidCancel is NO and errorMessage is nil, the operation completed successfully.
 */
typedef void (^INCancelErrorBlock)(BOOL userDidCancel, NSString * __autoreleasing errorMessage);


/**
 *  This class simplifies loading data from a URL.
 */
@interface INURLLoader : NSObject

@property (strong, nonatomic) NSURL *url;							///< The URL we will load from
@property (copy, nonatomic, readonly) NSData *responseData;			///< Will contain the response data as loaded from url
@property (copy, nonatomic, readonly) NSString *responseString;		///< Will contain the response as NSString as loaded from url
@property (nonatomic, readonly) NSUInteger responseStatus;			///< The HTTP response status code
@property (nonatomic) BOOL expectBinaryData;						///< NO by default. Set to YES if you expect binary data; "responseString" will be left nil!

- (id)initWithURL:(NSURL *)anURL;
+ (id)loaderWithURL:(NSURL *)anURL;

/**
 *  Start loading data from an URL.
 *  @param callback An INCancelErrorBlock that will be called when the operation finishes or aborts
 */
- (void)getWithCallback:(INCancelErrorBlock)callback;

/**
 *  POST body values to the receiver's URL.
 *  @param callback An INCancelErrorBlock that will be called when the operation finishes or aborts
 */
- (void)post:(NSString *)postBody withCallback:(INCancelErrorBlock)callback;

/**
 *  Perform an NSURLRequest asynchronically.
 *  This method is internally used as the endpoint of all convenience methods, all load operations start here.
 *  @param request The NSURLRequest to perform
 *  @param callback An INCancelErrorBlock that will be called when the operation finishes or aborts
 */
- (void)performRequest:(NSURLRequest *)aRequest withCallback:(INCancelErrorBlock)aCallback;

/**
 *  Abort loading data.
 */
- (void)abort;

+ (NSDictionary *)queryFromRequest:(NSURLRequest *)aRequest;
+ (NSDictionary *)queryFromRequestString:(NSString *)aString;

@end


/// Make callback or logging easy
#ifndef CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO
# define CANCEL_ERROR_CALLBACK_OR_LOG_USER_INFO(cb, didCancel, userInfo)\
	NSError *error = [userInfo objectForKey:INErrorKey];\
	if (cb) {\
		cb(didCancel, [error localizedDescription]);\
	}\
	else if (!didCancel) {\
		NSLog(@"No callback on this method, logging to debug. Error: %@", [error localizedDescription]);\
	}
#endif

#ifndef CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING
# define CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(cb, didCancel, errStr)\
	if (cb) {\
		cb(didCancel, errStr);\
	}\
	else if (errStr || didCancel) {\
		NSLog(@"No callback on this method, logging to debug. Error: %@ (Cancelled: %d)", errStr, didCancel);\
	}
#endif

#ifndef SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO
# define SUCCESS_RETVAL_CALLBACK_OR_LOG_USER_INFO(cb, success, userInfo)\
	if (cb) {\
	cb(success, userInfo);\
	}\
	else if (!success) {\
		NSLog(@"No callback on this method, logging to debug. Result: %@", [[userInfo objectForKey:INErrorKey] localizedDescription]);\
	}
#endif

#ifndef SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING
# define SUCCESS_RETVAL_CALLBACK_OR_LOG_ERR_STRING(cb, errStr, errCode)\
	if (cb) {\
		NSError *error = nil;\
		if (errStr) {\
			error = [NSError errorWithDomain:NSCocoaErrorDomain code:(errCode ? errCode : 0) userInfo:[NSDictionary dictionaryWithObject:errStr forKey:NSLocalizedDescriptionKey]];\
		}\
		cb((nil == error), error ? [NSDictionary dictionaryWithObject:error forKey:INErrorKey] : nil);\
	}\
	else if (errStr) {\
		NSLog(@"No callback on this method, logging to debug. Error %d: %@", errCode, errStr);\
	}
#endif

#ifndef INERR
# define INERR(p, s, c) if (p != NULL && s) {\
	*p = [NSError errorWithDomain:NSXMLParserErrorDomain code:(c ? c : 0) userInfo:[NSDictionary dictionaryWithObject:s forKey:NSLocalizedDescriptionKey]];\
}
#endif
