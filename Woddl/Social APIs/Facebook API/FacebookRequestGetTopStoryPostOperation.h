//
//  FacebookRequestGetTopStoryPostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 21.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FacebookRequestTypes.h"

@interface FacebookRequestGetTopStoryPostOperation : NSOperation

@property (nonatomic,strong) ComplationGetFBPostBlock completionBlock;
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSDictionary* dataDict;

-(id)initFacebookRequestGetTopStoryPostOperationWithToken:(NSString*)token_ andDictionary:(NSDictionary*)data withComplationBlock:(ComplationGetFBPostBlock)complationBlock_;

@end
