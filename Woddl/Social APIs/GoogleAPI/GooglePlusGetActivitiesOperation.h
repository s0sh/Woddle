//
//  GooglePlusGetActivitiesOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 26.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^complationGetActivitiesBlock)(NSArray* statuses);
@interface GooglePlusGetActivitiesOperation : NSOperation

@property (nonatomic,strong) complationGetActivitiesBlock completionBlock;
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* personID;

-(id)initGooglePlusRequestGetActivitiesOperationWithToken:(NSString*)token_
                                              andPersonID:(NSDictionary*)personID
                                                    count:(NSInteger)count
                                      withComplationBlock:(complationGetActivitiesBlock)complationBlock_;

@end
