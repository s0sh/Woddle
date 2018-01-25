//
//  EGOLoadPreviousTableHeaderView.m
//  Woddl
//
//  Created by Oleg Komaristov on 12.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "EGOLoadPreviousTableHeaderView.h"

@implementation EGOLoadPreviousTableHeaderView

- (void)setState:(EGOPullState)aState{
	
	switch (aState) {
		case EGOOPullPulling:
			
			_statusLabel.text = NSLocalizedStringFromTable(@"Release to load previous...",@"PullTableViewLan", @"Release to refresh status");
			[CATransaction begin];
			[CATransaction setAnimationDuration:FLIP_ANIMATION_DURATION];
			_arrowImage.transform = CATransform3DMakeRotation((M_PI / 180.0) * 180.0f, 0.0f, 0.0f, 1.0f);
			[CATransaction commit];
			
			break;
		case EGOOPullNormal:
			
			if (_state == EGOOPullPulling) {
				[CATransaction begin];
				[CATransaction setAnimationDuration:FLIP_ANIMATION_DURATION];
				_arrowImage.transform = CATransform3DIdentity;
				[CATransaction commit];
			}
			
			_statusLabel.text = NSLocalizedStringFromTable(@"Pull down to load previous...",@"PullTableViewLan", @"Pull down to refresh status");
			[_activityView stopAnimating];
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
			_arrowImage.hidden = NO;
			_arrowImage.transform = CATransform3DIdentity;
			[CATransaction commit];
			
			[self refreshLastUpdatedDate];
			
			break;
		case EGOOPullLoading:
			
			_statusLabel.text = NSLocalizedStringFromTable(@"Loading...",@"PullTableViewLan", @"Loading Status");
			[_activityView startAnimating];
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
			_arrowImage.hidden = YES;
			[CATransaction commit];
			
			break;
		default:
			break;
	}
	
	_state = aState;
}

@end
