//
//  FacebookPictures.m
//  Woddl
//
//  Created by Александр Бородулин on 30.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookPictures.h"

@implementation FacebookPictures

+(NSString*)getAvatarURLWithID:(NSString*) userID
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=large",userID]]];
    
    NSError *error = nil; NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error) {
        return nil;
    }
    NSURL *url = response.URL;
    NSString* urlStr = [url absoluteString];
    return urlStr;
}

@end
