//
//  FacebookPostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 19.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookPostOperation.h"
#import "Post.h"
#import "Group.h"
#import "FacebookRequest.h"
#import "UserProfile.h"
#import "SocialNetwork.h"
#import "WDDConstants.h"
#import "Media.h"

@interface FacebookPostOperation ()

@property (nonatomic, strong) Group *group;

@end

@implementation FacebookPostOperation

@synthesize token;
@synthesize message;
@synthesize link;
@synthesize title;
@synthesize description;
@synthesize picture;

- (id)initFacebookPostOperationWithToken:(NSString *)token_
                              andMessage:(NSString *)message_
                                 andPost:(Post *)post
                                 toGroup:(Group *)group
                            withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        self.group = group;
        
        token = token_;
        message = message_;
        delegate = delegate_;
        if(post)
        {
            link = post.linkURLString;
            description = post.text;
            NSSet* mediaSet = post.media;
            if(post.subscribedBy.socialNetwork.type.intValue != kSocialNetworkGooglePlus)
            {
                picture = post.author.avatarRemoteURL;
            }
            if(post.subscribedBy.socialNetwork.type.intValue==kSocialNetworkLinkedIN)
            {
                description = [NSString stringWithFormat:@"%@ %@",post.author.name,post.text];
            }
            else if(post.subscribedBy.socialNetwork.type.intValue==kSocialNetworkTwitter)
            {
                description = [NSString stringWithFormat:@" "];
            }
            else if(post.subscribedBy.socialNetwork.type.intValue == kSocialNetworkFoursquare)
            {
                title = post.author.name;
            }
            else if(post.subscribedBy.socialNetwork.type.intValue == kSocialNetworkInstagram)
            {
                title = post.author.name;
            }

            for(Media * mediaItem in mediaSet)
            {
                if(mediaItem.type.intValue==kMediaPhoto)
                {
                    if(mediaItem.mediaURLString)
                    {
                        picture = mediaItem.mediaURLString;
                    }
                    else if(mediaItem.previewURLString)
                    {
                        picture = mediaItem.previewURLString;
                    }
                }
            }
        }
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    FacebookRequest* request = [[FacebookRequest alloc] init];
    if([request addPostToWallWithToken:token andMessage:message andLink:link andName:title withDescription:description andImageURL:picture toGroupWithID:self.group.groupID])
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookPostDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
    }
    else
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookPostDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
}

@end
