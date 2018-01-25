//
//  NSDateFormatter+SocialNetworks.m
//  Woddl
//

#import "NSDateFormatter+SocialNetworks.h"

@implementation NSDateFormatter (SocialNetworks)

+ (NSDateFormatter*)twitterDateFormatter
{
    static NSDateFormatter *df;
    if(!df)
    {
        df = [[NSDateFormatter alloc] init];
        [df setLocale:[NSLocale localeWithLocaleIdentifier:@"En_us"]];
        [df setDateFormat:@"eee MMM dd HH:mm:ss ZZZZ yyyy"];
    }
    return df;
}

@end
