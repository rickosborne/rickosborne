//
//  ProgramDetailViewController.m
//  Confl8
//
//  Created by Rick Osborne on 05/17/12.
//

#import "ProgramDetailViewController.h"
#import "ProgramGatewayCouch.h"
#import "Program.h"

@implementation ProgramDetailViewController

static NSArray *programDetailLabels = nil;
static NSArray *programDetailKeys = nil;
static NSString *PROGRAM_DETAIL_DOCS = @"docs";
static NSString *PROGRAM_DETAIL_DISKSIZE = @"diskSize";
static NSString *PROGRAM_DETAIL_STATUS = @"status";

- (void)onDatabaseFailure:(NSString *)message
{
	NSLog(@"onDatabaseFailure:%@", message);
	[_details setValue:message forKey:PROGRAM_DETAIL_STATUS];
	[self.tableView reloadData];
}

- (void)onDatabaseReply:(NSDictionary *)reply
{
	NSLog(@"onDatabaseReply:%@", reply);
	[_details setValue:@"OK" forKey:PROGRAM_DETAIL_STATUS];
	NSNumber *docCount = [reply objectForKey:@"doc_count"];
	NSNumber *diskSize = [reply objectForKey:@"disk_size"];
	[_details setValue:[docCount stringValue] forKey:PROGRAM_DETAIL_DOCS];
	[_details setValue:[diskSize stringValue] forKey:PROGRAM_DETAIL_DISKSIZE];
	[self.tableView reloadData];
}

- (id)initWithProgram:(Program *)program
{
    if ((self = [super initWithStyle:UITableViewStylePlain]))
    {
        _program = program;
        self.title = @"About";
		programDetailLabels = [NSArray arrayWithObjects:@"Name", @"Docs", @"Size", @"Source", @"Username", @"Status", nil];
		programDetailKeys = [NSArray arrayWithObjects:PROGRAM_NAME, PROGRAM_DETAIL_DOCS, PROGRAM_DETAIL_DISKSIZE, PROGRAM_REPOURL, PROGRAM_USERNAME, PROGRAM_DETAIL_STATUS, nil];
		_details = [program createMutableDictionary];
		[_details setValue:@"?"	forKey:PROGRAM_DETAIL_DOCS];
		[_details setValue:@"?"	forKey:PROGRAM_DETAIL_DISKSIZE];
		[_details setValue:@"Loading ..." forKey:PROGRAM_DETAIL_STATUS];
		_gateway = [[ProgramGatewayCouch alloc] initWithUrl:program.repoURL username:program.repoUsername password:program.repoPassword];
    }
    return self;
}
/*
- (id)initWithStyle:(UITableViewStyle)style
{
    return [self initWithProgram:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithProgram:nil];
}
*/
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [programDetailLabels count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ProgramDetailCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:CellIdentifier];
    }
	cell.accessoryType = UITableViewCellAccessoryNone;
	cell.textLabel.text = [programDetailLabels objectAtIndex:indexPath.row];
	cell.detailTextLabel.text = [_details objectForKey:[programDetailKeys objectAtIndex:indexPath.row]];
    return cell;
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
	[_gateway authenticateWithDelegate:self onSuccess:@"onDatabaseReply:" onFailure:@"onDatabaseFailure:"];
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
