//
//  Created by rosborne on 5/17/12.
//

#import <Foundation/Foundation.h>

static NSString *PROGRAM_ACRONYM  = @"acronym";
static NSString *PROGRAM_NAME     = @"name";
static NSString *PROGRAM_REPOURL  = @"repoURL";
static NSString *PROGRAM_KEY      = @"key";
static NSString *PROGRAM_LASTSYNC = @"lastSyncDate";
static NSString *PROGRAM_USERNAME = @"repoUsername";
static NSString *PROGRAM_PASSWORD = @"repoPassword";
static NSString *PROGRAM_BRANCH   = @"repoBranch";
static NSString *PROGRAM_SSHKEY   = @"repoSSHkey";

@interface Program : NSObject <NSCoding>
{
}

- (NSMutableDictionary *)createMutableDictionary;
- (void)encodeWithCoder:(NSCoder *)aCoder;
- (id)initWithCoder:(NSCoder *)aDecoder;
+ (NSString *)makeUUID;

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSDate *lastSyncDate;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *repoBranch;
@property (nonatomic, strong) NSString *repoPassword;
@property (nonatomic, strong) NSString *repoSSHkey;
@property (nonatomic, strong) NSString *repoURL;
@property (nonatomic, strong) NSString *repoUsername;
@property (nonatomic, strong) NSString *acronym;

@end