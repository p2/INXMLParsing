/*
 INURLLoader.h
 IndivoFramework
 
 Created by Pascal Pfiffner on 10/13/11.
 Public Domain.
 
 This code is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE
 */

#import "INURLLoader.h"

@interface INURLLoader ()

@property (copy, nonatomic) INCancelErrorBlock callback;
@property (strong, nonatomic) NSMutableData *loadingCache;
@property (copy, nonatomic, readwrite) NSData *responseData;
@property (copy, nonatomic, readwrite) NSString *responseString;
@property (nonatomic, readwrite) NSUInteger responseStatus;

@property (strong, nonatomic) NSURLConnection *currentConnection;
@property (strong, nonatomic) NSURLResponse *currentResponse;
@property (nonatomic) NSTimeInterval timeoutInterval;
@property (strong, nonatomic) NSTimer *timeout;

@end


@implementation INURLLoader


/**
 *  Designated initializer.
 */
- (id)initWithURL:(NSURL *)anURL
{
	if ((self = [super init])) {
		self.url = anURL;
	}
	return self;
}

+ (instancetype)loaderWithURL:(NSURL *)anURL
{
	return [[self alloc] initWithURL:anURL];
}



#pragma mark - URL Loading
/**
 *  Praparations before beginning to load.
 */
- (void)prepareWithCallback:(INCancelErrorBlock)callback
{
	self.responseData = nil;
	self.responseString = nil;
	self.responseStatus = 1000;
	self.currentConnection = nil;
	self.currentResponse = nil;
	self.callback = callback;
	[_timeout invalidate];
	self.timeout = nil;
	self.loadingCache = [NSMutableData data];
}

- (void)getWithCallback:(INCancelErrorBlock)callback
{
	if (!_url) {
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, @"No URL given");
		return;
	}
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_url];
	[request setTimeoutInterval:kINURLLoaderDefaultTimeoutInterval];
	
	[self performRequest:request withCallback:callback];
}

- (void)post:(NSString *)postBody withCallback:(INCancelErrorBlock)callback
{
	if (!_url) {
		CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, @"No URL given");
		return;
	}
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_url];
	request.HTTPMethod = @"POST";
	request.HTTPBody = [postBody dataUsingEncoding:NSUTF8StringEncoding];
	[request setTimeoutInterval:kINURLLoaderDefaultTimeoutInterval];
	
	[self performRequest:request withCallback:callback];
}

- (void)performRequest:(NSURLRequest *)request withCallback:(INCancelErrorBlock)callback
{
	if (!_url) {
		self.url = request.URL;
		if (!_url) {
			CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(callback, NO, @"No URL given");
			return;
		}
	}
	
	// prepare and set a timeout timer manually
	[self prepareWithCallback:callback];
	self.timeoutInterval = fmin(kINURLLoaderDefaultTimeoutInterval, request.timeoutInterval);
	self.timeout = [NSTimer scheduledTimerWithTimeInterval:_timeoutInterval target:self selector:@selector(didTimeout:) userInfo:nil repeats:NO];
	
	//NSLog(@"-->  %@", request.URL);
	self.currentConnection = [NSURLConnection connectionWithRequest:request delegate:self];
}


/**
 *  This finishing method creates an NSString from any loaded data and calls the callback, if one was given.
 */
- (void)didFinishWithError:(NSError *)anError wasCancelled:(BOOL)didCancel
{
	[_timeout invalidate];
	self.timeout = nil;
	
	// extract response
	if ([_loadingCache length] > 0) {
		if ([_currentResponse isKindOfClass:[NSHTTPURLResponse class]]) {
			self.responseStatus = [(NSHTTPURLResponse *)_currentResponse statusCode];
		}
		
		// extract response string
		self.responseData = _loadingCache;
		self.loadingCache = nil;
		if (!_expectBinaryData) {
			self.responseString = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
		}
	}
	
	// finish up
	CANCEL_ERROR_CALLBACK_OR_LOG_ERR_STRING(_callback, didCancel, [anError localizedDescription]);
	self.callback = nil;
	self.currentConnection = nil;
}


/**
 *  Our timer calls this method when the time is up.
 */
- (void)didTimeout:(NSTimer *)timer
{
	[self.currentConnection cancel];
	self.loadingCache = nil;
	
	[self didFinishWithError:nil wasCancelled:YES];
}


- (void)abort
{
	[self didTimeout:nil];
}



#pragma mark - NSURLConnection Delegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	self.currentResponse = response;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_loadingCache appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self didFinishWithError:nil wasCancelled:NO];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if (!error) {
		error = nil;
		INERR(&error, @"Unknown Error", 0);
	}
	[self didFinishWithError:error wasCancelled:NO];
}



#pragma mark - Parsing URL Requests
/**
 *  Parses arguments from a request.
 *  @return An NSDictionary containing all arguments found in the request
 */
+ (NSDictionary *)queryFromRequest:(NSURLRequest *)aRequest
{
	NSString *queryString = [aRequest.URL query];
	
	/// @todo look in header and body for more arguments
	
	return [self queryFromRequestString:queryString];
}


/**
 *  Parses arguments from a request URL string.
 *  @return An NSDictionary containing all arguments found in the request string
 */
+ (NSDictionary *)queryFromRequestString:(NSString *)aString
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	
	// parse args
	NSArray *params = [aString componentsSeparatedByString:@"&"];
	if ([params count] > 0) {
		for (NSString *param in params) {
			NSArray *hat = [param componentsSeparatedByString:@"="];
			if ([hat count] > 1) {
				NSString *key = [hat objectAtIndex:0];
				hat = [hat mutableCopy];
				[(NSMutableArray *)hat removeObjectAtIndex:0];
				NSString *val = [hat componentsJoinedByString:@"="];	// we split by '=', which SHOULD only occur once, but may occur more than that
				
				[dict setObject:[val stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:key];
			}
		}
	}
	
	return dict;
}


@end
