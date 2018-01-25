//
//  WDDLog.m
//  Woddl
//

#import "WDDLog.h"

@implementation Log

NSCalendar *cal;

void append(NSString *msg)
{
    // get path to Documents/somefile.txt
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"logfile.txt"];
    // create if needed
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]){
        fprintf(stderr,"Creating file at %s",[path UTF8String]);
        [[NSData data] writeToFile:path atomically:YES];
    }
    // append
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
    [handle truncateFileAtOffset:[handle seekToEndOfFile]];
    [handle writeData:[msg dataUsingEncoding:NSUTF8StringEncoding]];
    [handle closeFile];
}

void _Log(NSString *format,...) 
{
    va_list ap;
    va_start (ap, format);
    format = [format stringByAppendingString:@"\n"];
    NSString *msg = [[NSString alloc] initWithFormat:[NSString stringWithFormat:@"%@ %@",dateStr([NSDate date]), format] arguments:ap];
    va_end (ap);
    fprintf(stderr,"%s", [msg UTF8String]);
    append(msg);
}

NSString* dateStr(NSDate* date)
{
    if (!cal)
    {
        cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    }
    NSDateComponents *comps = [cal components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:date];
    return [NSString stringWithFormat:@"%04d-%02d-%02d %02d:%02d:%02d", comps.year, comps.month, comps.day, comps.hour, comps.minute, comps.second];
}

@end
