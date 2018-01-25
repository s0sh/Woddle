//
//  FacebookPublishing.h
//  Woddl
//
//  Created by Александр Бородулин on 29.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FacebookPublishing : NSObject

@property(nonatomic,strong) NSString* token;

-(void)publishOnMyWallWithMessage:(NSString*)message;
-(void)setCommentWithToken:(NSString*)accessToken;
@end
