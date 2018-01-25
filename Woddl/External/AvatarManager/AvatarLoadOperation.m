//
//  AvatarLoadOperation.m
//  Woddl
//
//  Created by Oleg Komaristov on 26.02.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "AvatarLoadOperation.h"
#import "AvatarManager+Internal.h"

#import "UIImage+ResizeAdditions.h"

NSString * const AvatarManagementErrorDomain = @"AvatarManagementErrorDomain";

@interface AvatarLoadOperation ()

@property (nonatomic, strong) NSURL *avatarURL;
@property (nonatomic, copy) AvatarLoadedBlock loadedBlock;

@end


@implementation AvatarLoadOperation


+ (instancetype)operationWithURL:(NSURL *)avatarURL complitionBlock:(AvatarLoadedBlock)loadedBlock
{
    if (!avatarURL)
    {
        return nil;
    }
    
    AvatarLoadOperation *operation = [[AvatarLoadOperation alloc] init];
    operation.avatarURL = avatarURL;
    operation.loadedBlock = loadedBlock;
    
    return operation;
}

+ (instancetype)operationWithURL:(NSURL *)avatarURL
{
    return [self operationWithURL:avatarURL complitionBlock:nil];
}

- (UIImageView *)imageView
{
    return [[AvatarManager sharedManager] imageViewAssociatedWithURL:self.avatarURL];
}

- (void)main
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.avatarURL];
    if (!request)
    {
        if (self.loadedBlock)
        {
            NSError *error = [NSError errorWithDomain:AvatarManagementErrorDomain
                                                 code:AMWrongURL
                                             userInfo:@{NSLocalizedDescriptionKey : @"Wrong avatare URL"}];
            self.loadedBlock(self.avatarURL, nil, self.imageView, error);
        }
        
        [[AvatarManager sharedManager] loadingOperationFinished:self];
        return;
    }
    
    
    NSHTTPURLResponse *response = nil;
    NSError *requestError = nil;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                 returningResponse:&response
                                                             error:&requestError];
    if (requestError)
    {
        if (self.loadedBlock)
        {
            self.loadedBlock(self.avatarURL, nil, self.imageView, requestError);
        }
        
        [[AvatarManager sharedManager] loadingOperationFinished:self];
        return;
    }
    
    if (response.statusCode < 200 || response.statusCode > 299)
    {
        if (self.loadedBlock)
        {
            NSError *error = [NSError errorWithDomain:AvatarManagementErrorDomain
                                                 code:AMWrongResponse
                                             userInfo:@{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Server response with code: %ld", (long)response.statusCode]}];
            self.loadedBlock(self.avatarURL, nil, self.imageView, error);
        }
        
        [[AvatarManager sharedManager] loadingOperationFinished:self];
        return;
    }
    
    if (!responseData)
    {
        if (self.loadedBlock)
        {
            NSError *error = [NSError errorWithDomain:AvatarManagementErrorDomain
                                                 code:AMWrongResponse
                                             userInfo:@{NSLocalizedDescriptionKey : @"Empty server response"}];
            self.loadedBlock(self.avatarURL, nil, self.imageView, error);
        }
        
        [[AvatarManager sharedManager] loadingOperationFinished:self];
        return;
    }
    
    UIImage *image = [UIImage imageWithData:responseData];
    
    if (!image)
    {
        if (self.loadedBlock)
        {
            NSError *error = [NSError errorWithDomain:AvatarManagementErrorDomain
                                                 code:AMWrongResponse
                                             userInfo:@{NSLocalizedDescriptionKey : @"Response data not a image"}];
            self.loadedBlock(self.avatarURL, nil, self.imageView, error);
        }
        
        [[AvatarManager sharedManager] loadingOperationFinished:self];
        return;
    }
    
    UIImage *resizedImage = [image thumbnailImage:[AvatarManager sharedManager].sideSize * [UIScreen mainScreen].scale
                                transparentBorder:0.0f
                                     cornerRadius:[AvatarManager sharedManager].cornerRadius
                             interpolationQuality:kCGInterpolationDefault];
    
    [[AvatarManager sharedManager] registerImage:(resizedImage ? resizedImage : image) forURL:self.avatarURL];
    
    if (self.imageView)
    {
        dispatch_async(dispatch_get_main_queue(), ^{

            self.imageView.image = resizedImage ? : image;
        });
    }
    
    if (self.loadedBlock)
    {
        self.loadedBlock(self.avatarURL, nil, self.imageView, nil);
    }
    
    [[AvatarManager sharedManager] loadingOperationFinished:self];
}

@end
