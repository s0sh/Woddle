//
//  NSDate+SocialNetworks.h
//  Woddl
//

#import <Foundation/Foundation.h>
#import "NSDateFormatter+SocialNetworks.h"

@interface NSDate (SocialNetworks)

+ (instancetype)twitterDateFromString:(NSString*)string;
- (NSString*)twitterDateStringRepresentation;

@end
