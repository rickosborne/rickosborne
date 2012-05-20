//
//  Created by rosborne on 5/17/12.
//

#import "Program.h"
#import "Foundation/Foundation.h"

@implementation Program

@synthesize key, lastSyncDate, name, repoURL, repoBranch, repoSSHkey, repoPassword, repoUsername, acronym;

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:key forKey:@"key"];
	[coder encodeObject:lastSyncDate forKey:@"lastSyncDate"];
	[coder encodeObject:name forKey:@"name"];
	[coder encodeObject:repoURL forKey:@"repoURL"];
	[coder encodeObject:repoBranch forKey:@"repoBranch"];
	[coder encodeObject:repoSSHkey forKey:@"repoSSHkey"];
	[coder encodeObject:repoPassword forKey:@"repoPassword"];
	[coder encodeObject:repoUsername forKey:@"repoUsername"];
	[coder encodeObject:acronym forKey:@"acronym"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	if ((self = [super init]))
	{
		[self setKey:[decoder decodeObjectForKey:@"key"]];
		[self setLastSyncDate:[decoder decodeObjectForKey:@"lastSyncDate"]];
		[self setName:[decoder decodeObjectForKey:@"name"]];
		[self setRepoURL:[decoder decodeObjectForKey:@"repoURL"]];
		[self setRepoBranch:[decoder decodeObjectForKey:@"repoBranch"]];
		[self setRepoSSHkey:[decoder decodeObjectForKey:@"repoSSHkey"]];
		[self setRepoPassword:[decoder decodeObjectForKey:@"repoPassword"]];
		[self setRepoUsername:[decoder decodeObjectForKey:@"repoUsername"]];
		[self setAcronym:[decoder decodeObjectForKey:@"acronym"]];
	}
	return self;
}

+ (NSString *)makeUUID
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
        self.key = [Program makeUUID];
    }
    return self;
}

@end