//
//  WDDLinkShorterViewController.h
//  Woddl
//
//  Created by Oleg Komaristov on 21.02.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum tagLinkProcessingOptions
{
    ProcessLinksAtLastPosition = 1
    
} LinkProcessingOptions;

@interface WDDLinkShorterViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *inputTextview;

- (NSMutableAttributedString *)processLinksInText:(NSMutableAttributedString *)text
                                      withOptions:(LinkProcessingOptions)options
                                       complition:(void(^)(BOOL isChanged, NSAttributedString *text))complition;
- (void)updateCounter;
- (void)textViewDidChange:(UITextView *)textView;


@end
