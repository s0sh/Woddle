//
//  WDDErrorConstants.m
//  Woddl
//
//  Created by Sergii Gordiienko on 03.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "WDDErrorConstants.h"

NSString * const kErrorDomain = @"woodlDomain";

const NSUInteger kErrorCodeUnlikeFailed = 100;
const NSUInteger kErrorCodeLikeFailed = 101;
const NSUInteger kErrorCodeTwitterCommentFailed = 1000;
const NSUInteger kErrorCodeReTwittFailed = 1001;

NSString * const kErrorDescriptionTwitterCommentFailed = @"Failed to post comment";
NSString * const kErrorFailureReasonTwitterInvalidTweetLength = @"Invalid tweet length";