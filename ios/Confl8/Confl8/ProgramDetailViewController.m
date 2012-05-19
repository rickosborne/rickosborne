//
//  ProgramDetailViewController.m
//  Confl8
//
//  Created by Rick Osborne on 05/17/12.
//

#import "ProgramDetailViewController.h"
#import "Program.h"

@implementation ProgramDetailViewController

- (id)initWithProgram:(Program *)program
{
    if ((self = [super initWithNibName:nil bundle:nil]))
    {
        _program = program;
        self.title = @"About";
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:self.view.frame];
        titleLabel.text = _program.repoURL;
        [self.view addSubview:titleLabel];
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

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

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
