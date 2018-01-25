//
//  FoursquareCommentOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 26.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FoursquareCommentOperation.h"
#import "FoursquareRequest.h"

@implementation FoursquareCommentOperation

@synthesize token;
@synthesize objectID;
@synthesize message;

-(id)initFoursquareCommentOperationWithMesage:(NSString*)message_ andToken:(NSString*)token_ andPostID:(NSString*)postID withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        token = token_;
        objectID = postID;
        message = message_;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    FoursquareRequest* request = [[FoursquareRequest alloc] init];
    NSDictionary* reply = [request addCommentOnObjectID:objectID withToken:token andMessage:message];
    if(reply)
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(foursquareCommentDidFinishWithDictionary:) withObject:reply waitUntilDone:YES];
    }
    else
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(foursquareCommentDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
}

@end
