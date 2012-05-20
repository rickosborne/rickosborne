//
//  ProgramGatewayCouch.h
//  Confl8
//
//  Created by rosborne on 5/19/12.
//

#import <Foundation/Foundation.h>
#import "ProgramGateway.h"

@interface ProgramGatewayCouch : NSObject <ProgramGateway, NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
@private
	NSString *_url;
	NSString *_username;
	NSString *_password;
	NSMutableDictionary *_targets;
}

- (ProgramGatewayCouch *)initWithUrl:(NSString *)url username:(NSString *)username password:(NSString *)password;

@end
