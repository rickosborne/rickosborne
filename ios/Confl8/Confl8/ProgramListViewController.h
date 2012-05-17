//
//  ProgramListViewController.h
//  Confl8
//
//  Created by rosborne on 5/16/12.
//

#import <UIKit/UIKit.h>
#import "ProgramAddViewController.h"

@interface ProgramListViewController : UITableViewController <ProgramAddDelegate>

- (void)addProgram:(id)sender;

@end
