//
//  NSDate+SocialNetworks.m
//  Woddl
//

#import "NSDate+SocialNetworks.h"

@implementation NSDate (SocialNetworks)

+ (instancetype)twitterDateFromString:(NSString*)string
{
    return [[NSDateFormatter twitterDateFormatter] dateFromString:string];
}

- (NSString*)twitterDateStringRepresentation
{
    return [[NSDateFormatter twitterDateFormatter] stringFromDate:self];
}

@end
