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

- (NSString *)getDocPath:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsPath = [paths objectAtIndex:0];
    return [docsPath stringByAppendingPathComponent:fileName];
}

- (void)saveStore
{
	NSLog(@"saveStore:%@ %@", storeFileName, allPrograms);
	NSMutableDictionary *root = [NSMutableDictionary dictionary];
	[root setObject:allPrograms forKey:@"programs"];
	[NSKeyedArchiver archiveRootObject:root toFile:storeFileName];
//    [allPrograms writeToFile:storeFileName atomically:YES];
}

- (void)loadStore
{
//    allPrograms = [[NSMutableArray alloc] initWithContentsOfFile:storeFileName];
	NSDictionary *root = [NSKeyedUnarchiver unarchiveObjectWithFile:storeFileName];
	if (root)
	{
		allPrograms = [root objectForKey:@"programs"];
	}
	else
	{
		allPrograms = [[NSMutableArray alloc] init];
	}
}

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

//- (Program *)createProgram
//{
//    Program *p = [[Program alloc] init];
//    [allPrograms addObject:p];
//    return p;
//}

- (void)reorderPrograms
{
    NSSortDescriptor *nameSort = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *nameSorts = [[NSArray alloc] initWithObjects:nameSort, nil];
    [allPrograms sortUsingDescriptors:nameSorts];
}

- (Program *)createProgram:(NSString *)name withRepoURL:(NSString *)repoURL withAcronym:(NSString *)acronym;
{
    Program *p = [[Program alloc] init];
    p.name = [name copy];
    p.repoURL = [repoURL copy];
	p.acronym = [acronym copy];
	[allPrograms addObject:p];
    [self reorderPrograms];
    [self saveStore];
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
        storeFileName = [self getDocPath:@"programs.plist"];
        [self loadStore];
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
