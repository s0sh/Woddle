

#import "Semaphor.h"

@implementation Semaphor

-(id)init
{
    self = [super init];
    if (self != nil)
    {
        flags = [NSMutableDictionary dictionaryWithCapacity:10];
    }
    return self;
}

-(void)dealloc
{
    flags = nil;
}

-(BOOL)isLifted:(NSString*)key
{
    return [flags objectForKey:key]!=nil;
}

-(void)lift:(NSString*)key
{
    [flags setObject:@"YES" forKey: key];
}

-(void)waitForKey:(NSString*)key
{
    BOOL keepRunning = YES;
    while (keepRunning && [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]]) {
        keepRunning = ![self isLifted: key];
    }

}

@end
