//
//  TwitterImagesLoader.m
//  Woddl
//
//  Created by Александр Бородулин on 31.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "TwitterImagesLoader.h"
#import "TwitterDefault.h"

@implementation TwitterImagesLoader

static TwitterImagesLoader* myLoader = nil;

+(TwitterImagesLoader*)Instance
{
    static dispatch_once_t pred;
    dispatch_once(&pred,^{
        myLoader = [[super allocWithZone:NULL] init];
    });
    return myLoader;
}

- (id) init
{
    if (self = [super init])
    {
        BOOL isDir;
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:TMPFOLDER isDirectory:&isDir];
        if (exists) {
            /* file exists */
            if (isDir) {
                /* file is a directory */
            }
        }
        else
        {
            NSError* error;
            [[NSFileManager defaultManager] createDirectoryAtPath:TMPFOLDER withIntermediateDirectories:NO attributes:nil error:&error];
        }
    }
    return self;
}

- (NSString*) cacheAvatarWithScreenNameUser: (NSString *) screenName andImage:(UIImage*)image
{
    NSString *uniquePath = nil;
    if(screenName)
    {
        if(screenName.length>0)
        {
            NSString *filename = [NSString stringWithFormat:@"/Avatar_%@.png",screenName];
            
            uniquePath = [TMPFOLDER stringByAppendingPathComponent: filename];
            
            // Check for file existence
            if(![[NSFileManager defaultManager] fileExistsAtPath: uniquePath])
            {
                NSError* error = nil;
                //NSData *data = [NSData dataWithContentsOfURL:ImageURL options:NSDataReadingUncached error:&error];
                NSData *data = UIImagePNGRepresentation(image);
                if(!error)
                    [data writeToFile:uniquePath atomically:NO];
                else
                    return nil;
            }
        }
    }
    return uniquePath;
}

@end
