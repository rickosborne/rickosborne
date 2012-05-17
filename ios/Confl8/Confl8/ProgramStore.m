//
//  ProgramStore.m
//  Confl8
//
//  Created by rosborne on 5/17/12.
//

#import "ProgramStore.h"
#import "Program.h"

static ProgramStore *defaultStore = nil;

@implementation ProgramStore

+ (ProgramStore *)defaultStore
{
    if (!defaultStore)
    {
        defaultStore = (ProgramStore *) [[super allocWithZone:NULL] init];
    }
    return defaultStore;
}

- (NSArray *)allPrograms
{
    return allPrograms;
}

- (Program *)createProgram
{
    Program *p = [[Program alloc] init];
    [allPrograms addObject:p];
    return p;
}

- (NSUInteger)count
{
    return [allPrograms count];
}

- (Program *)programAtIndex:(NSUInteger)index
{
    return [allPrograms objectAtIndex:index];
}


+ (id)allocWithZone:(NSZone *)zone
{ // singleton paranoia magic
    return [self defaultStore];
}

- (id)init
{
    if (defaultStore)
    {
        return defaultStore;
    }
    self = [super init];
    if (self)
    {
        allPrograms = [[NSMutableArray alloc] init];
    }
    return self;
}
/*
- (id)retain
{
    return self;
}

- (void)release
{
    // I am a singleton.  I have no release.
}

- (NSUInteger)retainCount
{
    return NSUIntegerMax;
}
*/
@end
