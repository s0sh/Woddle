//
//  WDDLog.h
//  Woddl
//

#import <Foundation/Foundation.h>

#define DLog(args...) _Log(args);

@interface Log : NSObject

void _Log(NSString *format,...);

@end
