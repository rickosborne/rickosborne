//
//  CrudRootView.h
//  Gateways
//
//  Created by rosborne on 4/25/12.
//

#import <UIKit/UIKit.h>
#import "CrudTable.h"

@interface CrudRootView : UIViewController <CrudTableControllerDelegate>
{
	CrudTable *crudTable;
	UINavigationController *crudNav;
//	UIBarButtonItem *createButton;
	UIBarButtonItem *updateButton;
	UIBarButtonItem *deleteButton;
	@private
	NSMutableArray *items;
}


@end
