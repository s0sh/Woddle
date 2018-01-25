//
//  FacebookPublishing.m
//  Woddl
//
//  Created by Александр Бородулин on 29.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookPublishing.h"

@implementation FacebookPublishing
@synthesize token;

-(void)publishOnMyWallWithMessage:(NSString*)message
{
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://graph.facebook.com/me/feed"]];
    
    [request setHTTPBody:[[NSString stringWithFormat:@"access_token=%@&message=%@",token,message] dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];
    
    NSError *error = nil; NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error) {
        DLog(@"Error:%@", error.localizedDescription);
    }
    else {
        //success
    }
}

-(void)setCommentWithToken:(NSString*)accessToken
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/569452279735328_753973497949871/comments"]]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"access_token=%@&message=%@",accessToken,@"It is very gooooood!"] dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error = nil; NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error)
    {
        DLog(@"Error: %@", [error localizedDescription]);
    }
}

@end
