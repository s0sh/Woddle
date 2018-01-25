//
//  WDDTwitterStreamURLConnection.m
//  Woddl
//

#import "WDDTwitterStreamURLConnection.h"

@implementation WDDTwitterStreamURLConnection

+ (instancetype)connectionWithRequest:(NSURLRequest*)request delegate:(id <NSURLConnectionDelegate>)delegate
{
    return [[self alloc] initWithRequest:request delegate:delegate startImmediately:YES];
}

+ (instancetype)connectionWithRequest:(NSURLRequest*)request delegate:(id <NSURLConnectionDelegate>)delegate startImmediately:(BOOL)startImmediately
{
    return [[self alloc] initWithRequest:request delegate:delegate startImmediately:startImmediately];
}

- (instancetype)initWithRequest:(NSURLRequest*)request delegate:(id <NSURLConnectionDelegate>)delegate startImmediately:(BOOL)startImmediately
{
    self = [super initWithRequest:request delegate:delegate startImmediately:startImmediately];
    if (self)
    {
        
    }
    return self;
}

@end
