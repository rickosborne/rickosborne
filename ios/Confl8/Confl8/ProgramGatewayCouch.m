//
//  ProgramGatewayCouch.m
//  Confl8
//
//  Created by rosborne on 5/19/12.
//

#import "ProgramGatewayCouch.h"

const float COUCH_REQUEST_TIMEOUT = 3.0f;
static const NSString *COUCH_TARGET_ID = @"target";
static const NSString *COUCH_TARGET_SUCCESS = @"success";
static const NSString *COUCH_TARGET_FAILURE = @"failure";
static const NSString *COUCH_TARGET_DATA = @"data";
static const NSString *COUCH_ERROR_NOCONN = @"Could not connect";
static const NSString *COUCH_ERROR_BADAUTH = @"Bad username or password";

@implementation ProgramGatewayCouch

- (void)sendSuccessForConnection:(NSURLConnection *)conn
{
	NSDictionary *d = [_targets objectForKey:[conn description]];
	id target = [d objectForKey:COUCH_TARGET_ID];
	NSData *data = [d objectForKey:COUCH_TARGET_DATA];
	NSError *error = nil;
	NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
	NSString *success = [d objectForKey:COUCH_TARGET_SUCCESS];
	NSString *failure = [d objectForKey:COUCH_TARGET_FAILURE];
	[_targets removeObjectForKey:d];
	if (error)
	{
		[target performSelector:NSSelectorFromString(failure) withObject:error.localizedDescription];
	}
	else
	{
		[target performSelector:NSSelectorFromString(success) withObject:json];
	}
}

- (void)sendErrorMessage:(NSString *)message forConnection:(NSURLConnection *)conn
{
	NSDictionary *d = [_targets objectForKey:[conn description]];
	id target = [d objectForKey:COUCH_TARGET_ID];
	NSString *failure = [d objectForKey:COUCH_TARGET_FAILURE];
	[_targets removeObjectForKey:d];
	[target performSelector:NSSelectorFromString(failure) withObject:message];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if (challenge.previousFailureCount == 0)
	{
		NSURLCredential *cred = [NSURLCredential credentialWithUser:_username password:_password persistence:NSURLCredentialPersistenceNone];
		[challenge.sender useCredential:cred forAuthenticationChallenge:challenge];
	}
	else
	{
		[challenge.sender cancelAuthenticationChallenge:challenge];
		[self sendErrorMessage:(NSString*)COUCH_ERROR_BADAUTH forConnection:[connection description]];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	[(NSMutableData *)[(NSDictionary *)[_targets objectForKey:[connection description]] objectForKey:COUCH_TARGET_DATA] setLength:0];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[self sendErrorMessage:error.localizedDescription forConnection:[connection description]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[(NSMutableData *)[(NSDictionary *)[_targets objectForKey:[connection description]] objectForKey:COUCH_TARGET_DATA] appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self sendSuccessForConnection:connection];
}

- (void)authenticateWithDelegate:(id)target onSuccess:(NSString *)success onFailure:(NSString *)failure
{
	NSMutableURLRequest *req = [NSURLRequest requestWithURL:[[NSURL alloc] initWithString:_url] cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:COUCH_REQUEST_TIMEOUT];
	NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:NO];
	if (conn)
	{
		[_targets setObject:[NSDictionary dictionaryWithObjectsAndKeys:
			target,  COUCH_TARGET_ID,
			success, COUCH_TARGET_SUCCESS,
			failure, COUCH_TARGET_FAILURE,
			[NSMutableData data], COUCH_TARGET_DATA,
			nil] forKey:[conn description]];
		[conn start];
	}
	else
	{
		[target performSelector:NSSelectorFromString(failure) withObject:COUCH_ERROR_NOCONN];
	}
}

- (ProgramGatewayCouch *)initWithUrl:(NSString *)url username:(NSString *)username password:(NSString *)password
{
	if ((self = [super init]))
	{
		_url = [url copy];
		_username = [username copy];
		_password = [password copy];
		_targets = [NSMutableDictionary dictionary];
	}
	return self;
}

@end
