//
//  AvatarManagerTypes.h
//  Woddl
//
//  Created by Oleg Komaristov on 26.02.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#ifndef Woddl_AvatarManagerTypes_h
#define Woddl_AvatarManagerTypes_h

// Errors

extern NSString * const AvatarManagementErrorDomain;
typedef enum tagAvatarManagememtErrors
{
    AMWrongURL,
    AMWrongResponse
} AvatarManagememtErrors;


// Types

typedef void (^AvatarLoadedBlock)(NSURL *avatarURL, UIImage *image, UIImageView *associatedImageView, NSError *error);

#endif
