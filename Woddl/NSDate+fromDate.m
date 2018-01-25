//
//  NSDate+fromDate.m
//  Woddl
//
//  Created by Petro Korenev on 12/2/13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "NSDate+fromDate.h"

@implementation NSDate (fromDate)

+ (NSDate*)dateFromNow:(messagesFromDate)fromDate
{
    switch (fromDate) {
        case messagesFromYesterday:
            return [NSDate dateWithTimeIntervalSinceNow:-24 * 60 * 60];
        case messagesFromLastWeek:
            return [NSDate dateWithTimeIntervalSinceNow:-7 * 24 * 60 * 60];
        case messagesFromLastMonth:
            return [NSDate dateWithTimeIntervalSinceNow:-30 * 24 * 60 * 60];
        case messagesFromTimesBeginning:
        default:
            return [NSDate dateWithTimeIntervalSince1970:0];
    }
}

- (NSString*)timeAgoFromToday
{
    NSDate *now = [NSDate date];
    double deltaSeconds = fabs([self timeIntervalSinceDate:now]);
    double deltaMinutes = deltaSeconds / 60.0f;
    
    NSInteger minutes;
    
    if (deltaMinutes < (24 * 60))
    {
        NSDateComponents *componentsNowDate = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:now];
        NSDateComponents *componentsDate = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:self];
        
        NSInteger dayNow    = [componentsNowDate day];
        NSInteger dayOfDate = [componentsDate day];
        
        if (dayNow == dayOfDate)
        {
            NSString * todayText = NSLocalizedString(@"lskTodayText", @"Today");
            return todayText;
        }
        else
        {
            NSString * yesterdayText = NSLocalizedString(@"lskYesterdayText", @"Yesterday");
            return yesterdayText;
        }
    }
    else if (deltaMinutes < (24 * 60 * 2))
    {
        NSString * yesterdayText = NSLocalizedString(@"lskYesterdayText", @"Yesterday");
        return yesterdayText;
    }
    else if (deltaMinutes < (24 * 60 * 7))
    {
        minutes = (int)floor(deltaMinutes/(60 * 24));
        NSString * daysAgoText = NSLocalizedString(@"lskDaysAgoText", @"daysAgoText");
        return [NSString stringWithFormat:@"%i %@", minutes, daysAgoText];
    }
    else if (deltaMinutes < (24 * 60 * 14))
    {
        NSString * lastWeekText = NSLocalizedString(@"lskLastWeekText", @"Last week");
        return lastWeekText;
    }
    else if (deltaMinutes < (24 * 60 * 31))
    {
        minutes = (int)floor(deltaMinutes/(60 * 24 * 7));
        NSString * weeksAgoText = NSLocalizedString(@"lskWeeksAgoText", @"weeks ago");
        return [NSString stringWithFormat:@"%i %@", minutes, weeksAgoText];
    }
    else if (deltaMinutes < (24 * 60 * 61))
    {
        NSString * lastMonthText = NSLocalizedString(@"lskLastMonthText", @"Last month");
        return lastMonthText;
    }
    else if (deltaMinutes < (24 * 60 * 365.25))
    {
        minutes = (int)floor(deltaMinutes/(60 * 24 * 30));
        NSString * monthAgoText = NSLocalizedString(@"lskMonthsAgoText", @"months ago");
        return [NSString stringWithFormat:@"%i %@", minutes, monthAgoText];
    }
    else if (deltaMinutes < (24 * 60 * 731))
    {
        NSString * lastYearText = NSLocalizedString(@"lskLastYearText", @"Last year");
        return lastYearText;
    }
    
    minutes = (int)floor(deltaMinutes/(60 * 24 * 365));
    NSString * yearsAgoText = NSLocalizedString(@"lskYearsAgoText", @"years ago");
    return [NSString stringWithFormat:@"%i %@", minutes, yearsAgoText];
}

@end
