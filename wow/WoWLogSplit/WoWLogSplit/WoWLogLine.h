//
//  WoWLogLine.h
//  WoWLogSplit
//
//  Created by rosborne on 3/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WoWLogLine : NSObject
{
}

@property NSTimeInterval timestamp;
//@property (strong) NSString *event;
//@property (strong) NSString *sourceID;
//@property (strong) NSString *sourceName;
//@property (strong) NSInteger *sourceFlags;
//@property (strong) NSString *targetID;
//@property (strong) NSString *targetName;
//@property (strong) NSInteger *targetFlags;

+ (id) fromString:(NSString *) string;

@end
