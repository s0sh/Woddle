//
//  NSDate+fromDate.h
//  Woddl
//
//  Created by Petro Korenev on 12/2/13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    messagesFromYesterday,
    messagesFromLastWeek,
    messagesFromLastMonth,
    messagesFromTimesBeginning
} messagesFromDate;

@interface NSDate (fromDate)

+ (NSDate*)dateFromNow:(messagesFromDate)fromDate;
- (NSString*)timeAgoFromToday;

@end
