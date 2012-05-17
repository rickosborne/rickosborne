//
//  ProgramAddViewController.m
//  Confl8
//
//  Created by rosborne on 5/17/12.
//

#import "ProgramAddViewController.h"

// via http://cbconfiguitableview.googlecode.com
#define kCellHeight			25.0
#define kCellLeftOffset		8.0
#define kCellTopOffset		10.0
#define kCellRightOffset    20.0

@implementation ProgramAddViewController
@synthesize delegate;

- (void)saveProgram:(id)sender
{
    // NSLog(@"saveProgram:%@ %@", programName, repoURL);
    if ((programName.length > 0) && (repoURL.length > 0))
    {
        [self.delegate saveProgram:programName withRepoURL:repoURL];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (BOOL)doneEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
    if (textField.tag > 0)
    {
        [self saveProgram:textField];
    }
    return YES;
}

- (void)toggleSaveButton
{
    self.navigationItem.rightBarButtonItem.enabled = ((programName.length > 0) && (repoURL.length > 0));
}

- (void)nameChange:(UITextField *)sender
{
	// NSLog(@"nameChange:%@ %@", sender.placeholder, sender.text);
    programName = sender.text;
    [self toggleSaveButton];
}

- (void)repoChange:(UITextField *)sender
{
	// NSLog(@"repoChange:%@ %@", sender.placeholder, sender.text);
    repoURL = sender.text;
    [self toggleSaveButton];
}

- (id)init
{
   if ((self = [super initWithStyle:UITableViewStyleGrouped]))
   {
       programName = @"";
       repoURL = @"";
       self.title = @"New Program";
       self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveProgram:)];
       [self toggleSaveButton];
   }
	return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    return [self init];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return (section == 0) ? @"Name" : @"Source URL";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [@"ProgramAddCell" stringByAppendingString:((indexPath.section == 0) ? @"Name" : @"Repo")];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
	cell.accessoryType = UITableViewCellAccessoryNone;
    CGRect contentRect = cell.contentView.bounds;
    CGRect textRect = CGRectMake(contentRect.origin.x + kCellLeftOffset, kCellTopOffset, contentRect.size.width - kCellLeftOffset - kCellRightOffset, kCellHeight);
	UITextField *tf = [[UITextField alloc] initWithFrame:textRect];
	tf.autocorrectionType = UITextAutocorrectionTypeNo;
	tf.clearButtonMode = UITextFieldViewModeWhileEditing;
	tf.spellCheckingType = UITextSpellCheckingTypeNo;
    
    // Configure the cell...
	if (indexPath.section == 0)
	{ // name
		tf.placeholder = @"Example Film Program M.S.";
		[tf addTarget:self action:@selector(nameChange:) forControlEvents:UIControlEventEditingChanged];
		tf.autocapitalizationType = UITextAutocapitalizationTypeWords;
		tf.keyboardType = UIKeyboardTypeDefault;
		tf.tag = 0;
		tf.returnKeyType = UIReturnKeyNext;
	}
    else
	{ // repo
		tf.placeholder = @"http://confl8.com/film/";
		[tf addTarget:self action:@selector(repoChange:) forControlEvents:UIControlEventEditingChanged];
        [tf addTarget:self action:@selector(doneEditing:) forControlEvents:UIControlEventEditingDidEndOnExit];
		tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
		tf.keyboardType = UIKeyboardTypeURL;
		tf.tag = 1;
		tf.returnKeyType = UIReturnKeyDone;
	}
	[cell.contentView addSubview:tf];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate
/*
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
}
*/
@end
