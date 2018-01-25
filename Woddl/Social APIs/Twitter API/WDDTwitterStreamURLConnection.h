//
//  WDDTwitterStreamURLConnection.h
//  Woddl
//

#import <Foundation/Foundation.h>

typedef void(^WDDTwitterStreamProgressBlock)(id response);
typedef void(^WDDTwitterStreamStallWarningsBlock)(NSString *code, NSString *message, NSUInteger percentFull);
typedef void(^WDDTwitterStreamErrorBlock)(NSError *error);

@interface WDDTwitterStreamURLConnection : NSURLConnection

+ (instancetype)connectionWithRequest:(NSURLRequest*)request delegate:(id <NSURLConnectionDelegate>)delegate;
+ (instancetype)connectionWithRequest:(NSURLRequest*)request delegate:(id <NSURLConnectionDelegate>)delegate startImmediately:(BOOL)startImmediately;
- (instancetype)initWithRequest:(NSURLRequest*)request delegate:(id <NSURLConnectionDelegate>)delegate startImmediately:(BOOL)startImmediately;

@property (nonatomic, copy) WDDTwitterStreamProgressBlock       progressBlock;
@property (nonatomic, copy) WDDTwitterStreamStallWarningsBlock  stallWarningsBlock;
@property (nonatomic, copy) WDDTwitterStreamErrorBlock          errorBlock;
@property (nonatomic, strong) NSString                          *userId;

@end
