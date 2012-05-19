//
//  ProgramDetailViewController.h
//  Confl8
//
//  Created by Rick Osborne on 05/17/12.
//

@class Program;

@interface ProgramDetailViewController : UIViewController
{
@private;
    Program *_program;
}

- (id)initWithProgram:(Program *)program;

@end
