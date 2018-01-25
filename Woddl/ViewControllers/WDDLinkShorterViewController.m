//
//  WDDLinkShorterViewController.m
//  Woddl
//
//  Created by Oleg Komaristov on 21.02.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "WDDLinkShorterViewController.h"

#import "WDDURLShorter.h"
#import "Link+Additions.h"

@interface WDDLinkShorterViewController ()

@end

@implementation WDDLinkShorterViewController

- (NSMutableAttributedString *)processLinksInText:(NSMutableAttributedString *)text
                                      withOptions:(LinkProcessingOptions)options
                                       complition:(void(^)(BOOL isChanged, NSAttributedString *text))complition
{
    
    
    NSMutableAttributedString *processedText = text;
    
    static NSDataDetector *dataDetector = nil;
    if (!dataDetector)
    {
        dataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink
                                                       error:nil];
        
    }
    __block NSInteger requestsCount = 0;
    
    [dataDetector enumerateMatchesInString:text.string
                                   options:NSMatchingReportCompletion
                                     range:NSMakeRange(0, text.length)
                                usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                    
                                    if (result.resultType == NSTextCheckingTypeLink)
                                    {
                                        BOOL shouldProcessLink = NO;
                                        NSString *linkString = [text.string substringWithRange:result.range];
                                        
                                        if ((result.range.location + result.range.length) < text.string.length)
                                        {
                                            NSString *nextCharachter = [text.string substringWithRange:NSMakeRange(result.range.location + result.range.length, 1)];
                                            shouldProcessLink = ([nextCharachter rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound);
                                        }
                                        else if ((result.range.location + result.range.length) == text.string.length && options == ProcessLinksAtLastPosition)
                                        {
                                            shouldProcessLink = YES;
                                        }
                                        
                                        if (!shouldProcessLink)
                                        {
                                            return;
                                        }
                                        
                                        if (![Link isURLStringShort:linkString])
                                        {
                                            NSURL *linkURL = [NSURL URLWithString:linkString];
                                            NSURL *cachedLink = [[WDDURLShorter defaultShorter] cachedLinkForURL:linkURL];
                                            
                                            if (cachedLink)
                                            {
                                                [processedText.mutableString replaceOccurrencesOfString:linkString
                                                                                             withString:cachedLink.absoluteString
                                                                                                options:NSCaseInsensitiveSearch
                                                                                                  range:NSMakeRange(0, processedText.mutableString.length)];
                                            }
                                            else
                                            {
                                                __weak WDDLinkShorterViewController *wSelf = self;
                                                ++requestsCount;
                                                
                                                [[WDDURLShorter defaultShorter] getLinkForURL:linkURL
                                                                                 withCallback:^(NSURL *resultURL) {
                                                                                     
                                                                                     if (resultURL)
                                                                                     {
                                                                                         NSMutableAttributedString *string = [wSelf.inputTextview.attributedText mutableCopy];
                                                                                         [string.mutableString replaceOccurrencesOfString:linkString
                                                                                                                               withString:resultURL.absoluteString
                                                                                                                                  options:NSCaseInsensitiveSearch
                                                                                                                                    range:NSMakeRange(0, string.mutableString.length)];
                                                                                         
                                                                                         NSInteger distance = wSelf.inputTextview.attributedText.string.length - string.string.length;
                                                                                         if (distance != 0)
                                                                                         {
                                                                                             NSRange selectedRange = wSelf.inputTextview.selectedRange;
                                                                                             selectedRange.location -= distance;
                                                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                 
                                                                                                 wSelf.inputTextview.attributedText = string;
                                                                                                 wSelf.inputTextview.selectedRange = selectedRange;
                                                                                                 [self updateCounter];
                                                                                             });
                                                                                         }
                                                                                         
                                                                                         if (!--requestsCount && complition)
                                                                                         {
                                                                                             complition(YES, string);
                                                                                         }
                                                                                         
                                                                                     }
                                                                                 }];
                                            }
                                        }
                                    }
                                }];
    if (!requestsCount && complition)
    {
        complition(![text isEqual:processedText], processedText);
    }
    
    return processedText;
}

- (void)textViewDidChange:(UITextView *)textView
{
    //  Save cursor position - prevent jumping cursor after highlighting tags and usernames
    NSRange cursorPostion = textView.selectedRange;
    
    NSAttributedString *processedText = [self processLinksInText:textView.attributedText.mutableCopy withOptions:0 complition:nil];
    NSInteger distance = self.inputTextview.attributedText.string.length - processedText.string.length;
    if (distance != 0)
    {
        NSRange selectedRange = self.inputTextview.selectedRange;
        selectedRange.location -= distance;
        self.inputTextview.attributedText = processedText;
        [self updateCounter];
        
        cursorPostion = selectedRange;
    }
    
    [self updateCounter];
    
    textView.selectedRange = cursorPostion;
}

- (void)updateCounter
{
    NSAssert([self class] == [WDDLinkShorterViewController class], @"WDDLinkShorterViewController class is abstract and have to be subclassed!");
}

@end
