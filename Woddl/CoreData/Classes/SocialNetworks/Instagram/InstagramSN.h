//
//  InstagramSN.h
//  Woddl
//
//  Created by Sergii Gordiienko on 04.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SocialNetwork.h"


@interface InstagramSN : SocialNetwork

@property (nonatomic, strong) ComplationPostBlock postCompletionBlock;
@property (nonatomic, strong) completionSearchPostsBlock searchPostBlock;

@end
