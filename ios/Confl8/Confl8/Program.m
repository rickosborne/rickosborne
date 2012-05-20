//
//  Created by rosborne on 5/17/12.
//

#import "Program.h"
#import "Foundation/Foundation.h"

@implementation Program

@synthesize key, lastSyncDate, name, repoURL, repoBranch, repoSSHkey, repoPassword, repoUsername, acronym;

static NSArray *programKeys = nil;

- (NSMutableDictionary *)createMutableDictionary
{
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	id val;
	for (NSString *s in programKeys)
	{
		if ((val = [self valueForKey:s]))
		{
			[d setObject:val forKey:s];
		}
	}
	return d;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	for (NSString *s in programKeys)
	{
		[coder encodeObject:[self valueForKey:s] forKey:s];
	}
}

+ (void)initProgramKeys
{
	if (!programKeys)
	{
		programKeys = [NSArray arrayWithObjects:
					   PROGRAM_KEY,
					   PROGRAM_LASTSYNC,
					   PROGRAM_NAME,
					   PROGRAM_REPOURL,
					   PROGRAM_BRANCH,
					   PROGRAM_SSHKEY,
					   PROGRAM_PASSWORD,
					   PROGRAM_USERNAME,
					   PROGRAM_ACRONYM,
					   nil];
	}
}

- (id)initWithCoder:(NSCoder *)decoder
{
	[Program initProgramKeys];
	if (self != nil)
	{
		for (NSString *s in programKeys)
		{
			[self setValue:[decoder decodeObjectForKey:s] forKey:s];
		}
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
	[Program initProgramKeys];
    if ((self = [super init]))
    {
        self.lastSyncDate = [NSDate date];
        self.key = [Program makeUUID];
    }
    return self;
}

@end