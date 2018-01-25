//
//  FacebookPictures.h
//  Woddl
//
//  Created by Александр Бородулин on 30.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FacebookPictures : NSObject
+(NSString*)getAvatarURLWithID:(NSString*) userID;
@end
