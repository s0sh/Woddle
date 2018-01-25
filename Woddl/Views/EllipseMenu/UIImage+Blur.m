//
//  UIImage+Blur.m
//  ElipseMenu
//
//  Created by Sergii Gordiienko on 14.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "UIImage+Blur.h"
#import <Accelerate/Accelerate.h>

@implementation UIImage (Blur)

+ (UIImage *)blurredImageForView:(UIView *)view
{
    UIImage *image = [UIImage imageWithView:view];
    
    return [UIImage blurredImageWithImage:image];
}

+ (UIImage *)blurredImageWithImage:(UIImage *)image
{
    NSData *imageData = UIImageJPEGRepresentation(image, 1); // convert to jpeg
    UIImage *newImage = [UIImage imageWithData:imageData];
    return [newImage boxblurImageWithBlur:0.2f];
}

+ (UIImage *)imageWithView:(UIView *)view
{
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
    {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, 0.0);
    }
    else
    {
        UIGraphicsBeginImageContext(view.bounds.size);
    }
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    [view.layer renderInContext:c];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

-(UIImage *)boxblurImageWithBlur:(CGFloat)blur
{
    if (blur < 0.f || blur > 1.f)
    {
        blur = 0.5f;
    }
    NSInteger boxSize = (int)(blur * 50);
    boxSize = boxSize - (boxSize % 2) + 1;
    
    CGImageRef img = self.CGImage;
    
    vImage_Buffer inBuffer, outBuffer;
    
    vImage_Error error;
    
    void *pixelBuffer;
    
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    
    if(pixelBuffer == NULL)
    {
    DLog(@"No pixelbuffer");
    }

    
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    
    if (error)
    {
        DLog(@"JFDepthView: error from convolution %ld", error);
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    free(pixelBuffer);
    CFRelease(inBitmapData);
    
    CGImageRelease(imageRef);
    
    return returnImage;
}

- (UIImage *)cropImageWithRect:(CGRect)rect
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], rect);
    UIImage *cropedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return cropedImage;
}

@end
