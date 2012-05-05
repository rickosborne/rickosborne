//
//  CrudView.h
//  Gateways
//
//  Created by rosborne on 4/25/12.
//

#import <UIKit/UIKit.h>
#import "CrudFormView.h"

@class CrudTable;

@protocol CrudTableControllerDelegate <NSObject>

- (void)tableController:(CrudTable *)controller didCollect:(NSDictionary *)data;
- (void)tableController:(CrudTable *)controller shouldRemove:(NSDictionary *)data;
- (int) getItemCount;
- (NSDictionary *) getDataForIndex:(int)index;

@end

@interface CrudTable : UITableViewController <CrudFormViewControllerDelegate>

@property (nonatomic, weak) id <CrudTableControllerDelegate> delegate;

@end


