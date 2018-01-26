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

#import "NSAttributedString+Attributes.h"
#import "NSTextCheckingResult+ExtendedURL.h"
#import "OHAttributedLabel.h"
#import "OHParagraphStyle.h"
#import "OHTouchesGestureRecognizer.h"
#import "OHASBasicHTMLParser.h"
#import "OHASBasicMarkupParser.h"
#import "OHASMarkupParserBase.h"

FOUNDATION_EXPORT double OHAttributedLabelVersionNumber;
FOUNDATION_EXPORT const unsigned char OHAttributedLabelVersionString[];

