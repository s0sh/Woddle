//
//  UITapGestureRecognizer+MediaInfo.h
//  Woddl
//
//  Created by Oleg Komaristov on 16.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITapGestureRecognizer (MediaInfo)

@property (nonatomic, strong) NSURL *previewURL;
@property (nonatomic, strong) NSURL *mediaURL;
@property (nonatomic, strong) NSNumber *mediaType;

@end
