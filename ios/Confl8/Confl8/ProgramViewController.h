//
//  ProgramViewController.h
//  Confl8
//
//  Created by Rick Osborne on 05/17/12.
//

#import <UIKit/UIKit.h>

@class Program;

@interface ProgramViewController : UIViewController <UITabBarControllerDelegate>
{
@private
    UITabBarController *tabs;
    Program *_program;
}

- (id)initWithProgram:(Program *)program;

@end
