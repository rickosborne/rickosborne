//
//  WLSAppDelegate.m
//  WoWLogSplit
//
//  Created by rosborne on 3/17/12.
//

#import "WLSAppDelegate.h"
#import "FileReader.h"
#import "WoWLogLine.h"
#import "WoWLogTableView.h"

@implementation WLSAppDelegate

@synthesize window = _window;
@synthesize spinner = _spinner;
@synthesize splitButton = _splitButton;
@synthesize archiveButton = _archiveButton;
@synthesize findButton = _findButton;
@synthesize logScrollView = _logScrollView;
@synthesize logTableView = _logTableView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	targetLogFilePath = @"/Applications/World of Warcraft/Logs/WoWCombatLog.txt";
	minimumElapsedTime = 5 * 60;
	tableViewData = [[WoWLogTableView alloc] init];
	[_logTableView setDataSource:tableViewData];
}

- (IBAction)splitLogFile:(id)sender {
	NSLog(@"splitLogFile sender:%@ self:%@", sender, self);
	FileReader *reader = [[FileReader alloc] initWithFilePath:targetLogFilePath];
	NSString *line = nil;
	NSTimeInterval previousTimestamp = 0;
	NSFileHandle *out = nil;
	NSString *outputPath = [targetLogFilePath stringByDeletingLastPathComponent];
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"yyyyMMdd-HHmm"];
	while ((line = [reader readLine]))
	{
		WoWLogLine *data = [WoWLogLine fromString:line];
//		NSLog(@"Data:%@", data);
		if (!data)
			continue;
		NSTimeInterval currentTimestamp = [data timestamp];
		NSTimeInterval elapsed = currentTimestamp - previousTimestamp;
		if (elapsed >= minimumElapsedTime)
		{
			NSLog(@"Break: prev:%.2f cur:%.2f elapsed:%.2f", previousTimestamp, currentTimestamp, elapsed);
			[tableViewData addItemWithStart:[dateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:currentTimestamp]] duration:@"" mobCount:@""];
			[_logTableView reloadData];
			if (out)
			{
				[out closeFile];
				out = nil;
			}
		}
		previousTimestamp = currentTimestamp;
		if (!out)
		{
			NSString *datePart = [dateFormat stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:currentTimestamp]];
			NSString *fileName = [outputPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@ WoWCombatLog.txt", datePart]];
			NSLog(@"File:%@ (%@)", fileName, datePart);
			[[NSFileManager defaultManager] createFileAtPath:fileName contents:nil attributes:nil];
			out = [NSFileHandle fileHandleForWritingAtPath:fileName];
		}
		[out writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
	}
	[out closeFile];
}

- (IBAction)archiveSplitLogs:(id)sender {
	NSLog(@"archiveSplitLogs sender:%@ self:%@", sender, self);
}

- (IBAction)findLogFile:(id)sender {
	NSLog(@"findLogFile sender:%@ self:%@", sender, self);
}

- (void)dealloc
{
    [super dealloc];
}

@end
