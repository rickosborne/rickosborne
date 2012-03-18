//
//  WoWLogTableView.m
//  WoWLogSplit
//
//  Created by rosborne on 3/18/12.
//

#import "WoWLogTableView.h"

@implementation WoWLogTableView

- (id)init
{
	if ((self = [super init]))
	{
		allItems = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	int colIndex = 0;
	NSString *colName = [tableColumn identifier];
	if ([colName isEqualToString:@"duration"])
		colIndex = 1;
	else if ([colName isEqualToString:@"mobs"])
		colIndex = 2;
	return [[allItems objectAtIndex:row] objectAtIndex:colIndex];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
	return [allItems count];
}

- (void) addItemWithStart:(NSString *) start duration:(NSString *) duration mobCount:(NSString *) mobs
{
	[allItems addObject:[NSArray arrayWithObjects:start, duration, mobs, nil]];
}

- (void) clearAllItems
{
	[allItems removeAllObjects];
}

@end
