//
//  ProgramCoursesViewController.h
//  Confl8
//
//  Created by Rick Osborne on 05/19/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Program;

@interface ProgramCoursesViewController : UITableViewController
{
@private
    Program *_program;
}

- (id)initWithProgram:(Program *)program;

@end
