//
//  NSString+MD5.m
//  Woddl
//

#import "NSString+MD5.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSString (MD5)

- (NSString*)MD5
{
    const char *cStr = self.UTF8String;
    if (!cStr) cStr = [self cStringUsingEncoding:NSUTF16StringEncoding];
    if (!cStr) return self;
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, strlen(cStr), digest );
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return  output;
}

@end
