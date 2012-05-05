//
//  CrudRootView.m
//  Gateways
//
//  Created by rosborne on 4/25/12.
//

#import "CrudRootView.h"
#import "CrudTable.h"

@implementation CrudRootView

- (void)tableController:(CrudTable *)controller shouldRemove:(NSDictionary *)data
{
	NSLog(@"tableController:shouldRemove:%@", data);
	NSString *id = [data objectForKey:@"id"];
	for (NSMutableDictionary *dict in items)
	{
		if ([[dict objectForKey:@"id"] isEqualToString:id])
		{
			[items removeObject:dict];
			return;
		}
	}
}

- (int) getItemCount
{
	return [items count];
}

- (NSDictionary *) getDataForIndex:(int)index
{
	return [items objectAtIndex:index];
}

- (void)tableController:(CrudTable *)controller didCollect:(NSDictionary *)data;
{
	NSLog(@"tableController:didCollect:%@", data);
	NSString *id = [data objectForKey:@"id"];
	for (NSMutableDictionary *dict in items)
	{
		if ([[dict objectForKey:@"id"] isEqualToString:id])
		{
			[dict setValuesForKeysWithDictionary:data];
			return;
		}
	}
	[items addObject:[NSMutableDictionary dictionaryWithDictionary:data]];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		items = [[NSMutableArray alloc] init];
    }
    return self;
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

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
	// This is an ugly hack because we're using a top-level View instead of a Nav
	CGRect frame = [self.view frame];
	CGPoint origin = frame.origin;
	CGSize size = frame.size;
	if ((origin.x != 0) || (origin.y != 0))
	{
		[self.view setFrame:CGRectMake(0, 0, size.width + origin.x, size.height + origin.y)];
	}
	crudTable = [[CrudTable alloc] initWithStyle:UITableViewStylePlain];
	crudTable.delegate = self;
	crudNav = [[UINavigationController alloc] initWithRootViewController:crudTable];
	[self.view addSubview:crudNav.view];
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
