//
//  WLSAppDelegate.h
//  WoWLogSplit
//
//  Created by rosborne on 3/17/12.
//

#import <Cocoa/Cocoa.h>

@class WoWLogTableView;

@interface WLSAppDelegate : NSObject <NSApplicationDelegate>
{
	NSString *targetLogFilePath;
	NSTimeInterval minimumElapsedTime;
	IBOutlet WoWLogTableView *tableViewData;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSProgressIndicator *spinner;
@property (assign) IBOutlet NSButton *splitButton;
@property (assign) IBOutlet NSButton *archiveButton;
@property (assign) IBOutlet NSButton *findButton;
@property (assign) IBOutlet NSScrollView *logScrollView;
@property (assign) IBOutlet NSTableView *logTableView;

- (IBAction)splitLogFile:(id)sender;
- (IBAction)archiveSplitLogs:(id)sender;
- (IBAction)findLogFile:(id)sender;


@end
