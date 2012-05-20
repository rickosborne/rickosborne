//
//  ProgramViewController.m
//  Confl8
//
//  Created by Rick Osborne on 05/17/12.
//

#import "ProgramViewController.h"
#import "ProgramDetailViewController.h"
#import "ProgramCoursesViewController.h"
#import "Program.h"

@implementation ProgramViewController

- (id)initWithProgram:(Program *)program
{
    if ((self = [super initWithNibName:nil bundle:nil]))
    {
        _program = program;
        tabs = [[UITabBarController alloc] init];
        tabs.view.frame = self.view.bounds;
        [tabs setViewControllers:[NSArray arrayWithObjects:
            [[ProgramDetailViewController alloc] initWithProgram:program],
            [[ProgramCoursesViewController alloc] initWithProgram:program],
            nil
        ]];
        [self.view addSubview:tabs.view];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithProgram:nil];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (_program && _program.acronym && _program.acronym.length)
    {
        self.title = _program.acronym;
    }
    else
    {
        self.title = @"[Program]";
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
