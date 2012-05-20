//
//  ProgramDetailViewController.h
//  Confl8
//
//  Created by Rick Osborne on 05/17/12.
//

#import "ProgramGateway.h"
@class Program;


@interface ProgramDetailViewController : UITableViewController
{
@private;
    Program *_program;
	NSMutableDictionary *_details;
	id<ProgramGateway> _gateway;
}

- (id)initWithProgram:(Program *)program;

@end
