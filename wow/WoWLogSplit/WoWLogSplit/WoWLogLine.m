//
//  WoWLogLine.m
//  WoWLogSplit
//
//  Created by rosborne on 3/18/12.
//

#import "WoWLogLine.h"

@implementation WoWLogLine
@synthesize timestamp;

+ (NSCalendar *) calendar
{
	static NSCalendar *cal = nil;
	if (!cal)
	{
		cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	}
	return cal;
}

+ (NSInteger) startYear
{
	static NSInteger y = 0;
	if (!y)
	{
		y = [[NSCalendarDate date] yearOfCommonEra];
	}
	return y;
}

+ (NSDateComponents *) dateComponents
{
	static NSDateComponents *dc = nil;
	if (!dc)
	{
		dc = [[NSDateComponents alloc] init];
		[dc setYear:[WoWLogLine startYear]];
	}
	return dc;
}

+ (id) fromString:(NSString *) string
{
	NSArray *lineParts = [string componentsSeparatedByString:@" "];
	if ([lineParts count] < 3)
	{
		NSLog(@"Line with bad part count:%lu:%@", [lineParts count], string);
		return nil;
	}
	NSString *dateString = [lineParts objectAtIndex:0];
	NSArray *dateParts = [dateString componentsSeparatedByString:@"/"];
	if ([dateParts count] != 2)
	{
		NSLog(@"Date with bad part count:%lu:%@", [dateParts count], dateString);
		return nil;
	}
	int dateMonth = [[dateParts objectAtIndex:0] intValue];
	int dateDay   = [[dateParts objectAtIndex:1] intValue];
	if ((dateMonth < 1) || (dateMonth > 12) || (dateDay < 1) || (dateDay > 31))
	{
		NSLog(@"Bad date, month:%d day:%d parts:%@", dateMonth, dateDay, dateParts);
		return nil;
	}
	NSString *timeString = [lineParts objectAtIndex:1];
	NSArray *timeParts = [timeString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":."]];
	if ([timeParts count] != 4)
	{
		NSLog(@"Bad time parts:%@", timeParts);
		return nil;
	}
	int timeHour   = [[timeParts objectAtIndex:0] intValue];
	int timeMinute = [[timeParts objectAtIndex:1] intValue];
	int timeSecond = [[timeParts objectAtIndex:2] intValue];
	int timeMS     = [[timeParts objectAtIndex:3] intValue];
	if ((timeHour < 0) || (timeHour > 23) || (timeMinute < 0) || (timeMinute > 59) || (timeSecond < 0) || (timeSecond > 59) || (timeMS < 0) || (timeMS > 999))
	{
		NSLog(@"Bad time, h:%d m:%d s:%d ms:%d parts:%@", timeHour, timeMinute, timeSecond, timeMS, timeParts);
		return nil;
	}
	WoWLogLine *line = [[WoWLogLine alloc] init];
	NSDateComponents *dc = [WoWLogLine dateComponents];
	[dc setMonth:dateMonth];
	[dc setDay:dateDay];
	[dc setHour:timeHour];
	[dc setMinute:timeMinute];
	[dc setSecond:timeSecond];
	NSDate *dateStamp = [[WoWLogLine calendar] dateFromComponents:dc];
	if ([dateStamp timeIntervalSinceReferenceDate] > [NSDate timeIntervalSinceReferenceDate])
	{
		[dc setYear:[WoWLogLine startYear] - 1];
		dateStamp = [[WoWLogLine calendar] dateFromComponents:dc];
	}
	NSTimeInterval ti = [dateStamp timeIntervalSinceReferenceDate] + (timeMS * 0.001);
	[line setTimestamp:ti];
	// NSLog(@"Timestamp interval:%.3f date:%@", ti, dateStamp);
	return line;
}

@end
