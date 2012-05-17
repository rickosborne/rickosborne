//
//  ProgramStore.h
//  Confl8
//
//  Created by rosborne on 5/17/12.
//

#import <Foundation/Foundation.h>

@class Program;

@interface ProgramStore : NSObject
{
@private
    NSMutableArray *allPrograms;
}

+ (ProgramStore *)defaultStore;

- (NSArray *)allPrograms;
- (Program *)createProgram;
- (Program *)createProgram:(NSString *)name withRepoURL:(NSString *)repoURL;
- (NSUInteger)count;
- (Program *)programAtIndex:(NSUInteger)index;

@end
