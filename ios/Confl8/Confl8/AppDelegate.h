//
//  AppDelegate.h
//  Confl8
//
//  Created by rosborne on 5/16/12.
//

#import <UIKit/UIKit.h>

@class ProgramListViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
@private
	__strong UINavigationController *nc;
	__strong ProgramListViewController *plvc;
}

@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
