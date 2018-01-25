//
//  FoursquareSN.h
//  Woddl
//
//  Created by Sergii Gordiienko on 04.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SocialNetwork.h"


@interface FoursquareSN : SocialNetwork

@property (nonatomic,strong) completionAddStatusBlock addStatusCompletionBlock;
@property (nonatomic,strong) ComplationPostBlock postCompletionBlock;
@property (nonatomic,strong) ComplationGetPostBlock getPostsComplationBlock;

@end
