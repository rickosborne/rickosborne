//
//  Created by rosborne on 5/17/12.
//

#import "Program.h"
#import "Foundation/Foundation.h"

@implementation Program

@synthesize key, lastSyncDate, name, repoURL, repoBranch, repoSSHkey, repoPassword, repoUsername;

- (NSString *)makeUUID
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *s = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return s;
}

- (id)init
{
    if ((self = [super init]))
    {
        self.lastSyncDate = [NSDate date];
        self.key = [self makeUUID];
    }
    return self;
}

@end