//
//  CrudFormView.m
//  Gateways
//
//  formd by rosborne on 4/26/12.
//

#import "CrudFormView.h"

@implementation CrudFormView

@synthesize delegate;

- (void)setData:(NSDictionary *)dictionary
{
	data = [NSMutableDictionary dictionaryWithDictionary:dictionary];
}

- (void)removeItem:(UIButton *)button
{
	NSLog(@"removeItem:%@ data:%@", button, data);
	[self.delegate formViewController:self shouldRemove:data];
}

- (void)collectData:(UIButton *)button
{
	NSLog(@"collectData:%@ data:%@", button, data);
	[self.delegate formViewController:self didCollect:data];
}

- (void)textFieldChanged:(UITextField *)textField
{
	NSString *key = [keyForTag objectForKey:[NSString stringWithFormat:@"%d", textField.tag]];
	NSString *value = textField.text;
	NSMutableString *destination = (NSMutableString*)[data objectForKey:key];
	[destination setString:value];
	NSLog(@"textFieldChanged:%@:%@", key, destination);
}

- (int) getYforLine:(int)line
{
	return ((line - 1) * 31) + (line * 20);
}

- (void) addFormLabel:(NSString*)labelText forLine:(int)line
{
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, [self getYforLine:line], 80, 31)];
	label.text = labelText;
	label.textAlignment = UITextAlignmentRight;
	[self.view addSubview:label];
}

- (void) addFormInput:(NSString*)key withTag:(int)tag forLine:(int)line
{
	UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(120, [self getYforLine:line], 180, 31)];
	field.borderStyle = UITextBorderStyleRoundedRect;
	field.autocorrectionType = UITextAutocorrectionTypeNo;
	field.autocapitalizationType = UITextAutocapitalizationTypeNone;
	field.returnKeyType = UIReturnKeyNext;
	field.tag = tag;
	field.clearButtonMode = UITextFieldViewModeWhileEditing;
	field.rightViewMode = UITextFieldViewModeWhileEditing;
	[field addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingDidEndOnExit];
	[field addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
	NSString *tagKey = [NSString stringWithFormat:@"%d", line];
	[keyForTag setObject:key forKey:tagKey];
	NSString *value = [data objectForKey:key];
	if (value != nil)
	{
		field.text = value;
	}
	else
	{
		[data setValue:[NSMutableString stringWithString:@""] forKey:key];
	}
	[self.view addSubview:field];
}

- (void)addFormInput:(NSString*)key withLabel:(NSString*)label forLine:(int)line
{
	[self addFormLabel:label forLine:line];
	[self addFormInput:key withTag:line forLine:line];
}

- (void)addFormButton:(NSString *)label forLine:(int)line withAction:(SEL)action
{
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	button.frame = CGRectMake(20, [self getYforLine:line], 280, 31);
	button.tag = line;
	[button setTitle:label forState:UIControlStateNormal];
	[button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:button];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.view setBackgroundColor:[UIColor whiteColor]];
	[self addFormInput:@"id" withLabel:@"id:" forLine:FormInputId];
	[self addFormInput:@"value" withLabel:@"value:" forLine:FormInputValue];
	[self addFormButton:@"Save Item" forLine:FormInputSubmit withAction:@selector(collectData:)];
	if ([[data objectForKey:@"id"] length])
	{
		[self addFormButton:@"Delete Item" forLine:FormInputDelete withAction:@selector(removeItem:)];
	}
	// focus the first field
	for (UIView *view in [self.view subviews]) {
		if ([view isKindOfClass:[UITextField class]]) {
			[(UITextField *)view becomeFirstResponder];
			break;
		}
	}
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Create Item";
		data = [[NSMutableDictionary alloc] init];
		keyForTag = [[NSMutableDictionary alloc] init];
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
 // Implement loadView to form a view hierarchy programmatically, without using a nib.
 - (void)loadView
 {
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
