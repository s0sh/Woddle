#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "UIDevice-Capabilities.h"
#import "UIDevice-Hardware.h"
#import "UIDevice-Orientation.h"
#import "UIDevice-Reachability.h"

FOUNDATION_EXPORT double uidevice_extensionVersionNumber;
FOUNDATION_EXPORT const unsigned char uidevice_extensionVersionString[];

