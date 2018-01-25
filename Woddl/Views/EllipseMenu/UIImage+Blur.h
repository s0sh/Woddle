//
//  UIImage+Blur.h
//  ElipseMenu
//
//  Created by Sergii Gordiienko on 14.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Blur)
+ (UIImage *)imageWithView:(UIView *)view;
+ (UIImage *)blurredImageForView:(UIView *)view;
+ (UIImage *)blurredImageWithImage:(UIImage *)image;

- (UIImage *)boxblurImageWithBlur:(CGFloat)blur;
- (UIImage *)cropImageWithRect:(CGRect)rect;
@end
