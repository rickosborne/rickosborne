//
//  WoWLogTableView.h
//  WoWLogSplit
//
//  Created by rosborne on 3/18/12.
//

#import <Foundation/Foundation.h>

@interface WoWLogTableView : NSObject <NSTableViewDataSource>
{
	NSMutableArray *allItems;
}

- (void) addItemWithStart:(NSString *) start duration:(NSString *) duration mobCount:(NSString *) mobs;
- (void) clearAllItems;

@end
