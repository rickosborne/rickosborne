//
//  ProgramAddViewController.h
//  Confl8
//
//  Created by rosborne on 5/17/12.
//

#import <UIKit/UIKit.h>

@class ProgramListViewController;

@protocol ProgramAddDelegate <NSObject>
@required
- (void)saveProgram:(NSString *)name withRepoURL:(NSString *)repoURL withAcronym:(NSString*)acronym;
@end

@interface ProgramAddViewController : UITableViewController
{
@private
	NSString *programAcronym;
    NSString *programName;
    NSString *repoURL;
	NSArray *labels;
}
@property (nonatomic, assign) id<ProgramAddDelegate> delegate;

@end
