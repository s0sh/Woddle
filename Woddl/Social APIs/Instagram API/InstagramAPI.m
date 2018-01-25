//
//  InstagramAPI.m
//  Woddl
//
//  Created by Александр Бородулин on 01.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "InstagramAPI.h"
#import "InstagramViewController.h"

@interface InstagramAPI ()<InstagramViewControllerDelegate>

@end

@implementation InstagramAPI

static InstagramAPI* myInstagram = nil;

#pragma mark - Initialization

+(InstagramAPI*)Instance
{
    static dispatch_once_t pred;
    dispatch_once(&pred,^{
        myInstagram = [[super allocWithZone:NULL] init];
    });
    return myInstagram;
}

- (id) init
{
    if (self = [super init])
    {
    }
    return self;
}

#pragma mark - Login

-(void)loginWithDelegate:(id<InstagramAPIDelegate>)delegate_
{
    InstagramViewController *instagramController  = [[InstagramViewController alloc] init];
    instagramController.delegate = self;
    delegate = delegate_;
    if(delegate)
        [delegate loginInstagramViewController:instagramController];
}

#pragma mark - Delegate

-(void)loginCencel
{
    if(delegate)
        [delegate loginInstagramFailed];
    delegate = nil;
}

-(void)loginFail
{
    if(delegate)
        [delegate loginInstagramFailed];
    delegate = nil;
}

-(void)loginInstagramSuccessWithToken:(NSString *)token andUserID:(NSString *)userID andScreenName:(NSString *)name andImageURL:(NSString *)imageURL andProfileURL:(NSString *)profileURLString
{
    if(delegate)
        [delegate loginInstagramSuccessWithToken:token andUserID:userID andScreenName:name andImageURL:imageURL andProfileURL:profileURLString];
    delegate = nil;
}

-(void)getMediaWithID:(NSString*)userID andToken:(NSString*)token
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.instagram.com/v1/media/579530509874422629_625011079?access_token=%@",token]]];
    
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        DLog(@"json = %@",json);
    }
}

@end
