//
//  Created by rosborne on 5/17/12.
//

#import <Foundation/Foundation.h>

@interface Program : NSObject
{
}

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSDate *lastSyncDate;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *repoBranch;
@property (nonatomic, strong) NSString *repoPassword;
@property (nonatomic, strong) NSString *repoSSHkey;
@property (nonatomic, strong) NSString *repoURL;
@property (nonatomic, strong) NSString *repoUsername;

@end