//
//  PullLoadPrevTableView.m
//  Woddl
//
//  Created by Oleg Komaristov on 12.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "PullLoadPrevTableView.h"
#import "EGOLoadPreviousTableHeaderView.h"

@implementation PullLoadPrevTableView

- (void)config
{
    /* Message interceptor to intercept scrollView delegate messages */
    delegateInterceptor = [[MessageInterceptor alloc] init];
    delegateInterceptor.middleMan = self;
    delegateInterceptor.receiver = self.delegate;
    
    IMP setDelegateImp = [[self.superclass superclass] instanceMethodForSelector:@selector(setDelegate:)];
    setDelegateImp(self, @selector(setDelegate:), (id)delegateInterceptor);
    
    /* Status Properties */
    pullTableIsRefreshing = NO;
    pullTableIsLoadingMore = NO;
    
    /* Refresh View */
    refreshView = [[EGOLoadPreviousTableHeaderView alloc] initWithFrame:CGRectMake(0, -self.bounds.size.height, self.bounds.size.width, self.bounds.size.height)];
    refreshView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    refreshView.delegate = self;
    if ([self.subviews indexOfObject:refreshView] == NSNotFound)
    {
        [self addSubview:refreshView];
    }    
    
    /* Load more view init */
    loadMoreView = [[LoadMoreTableFooterView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height, self.bounds.size.width, self.bounds.size.height)];
    loadMoreView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    loadMoreView.delegate = self;
    if ([self.subviews indexOfObject:loadMoreView] == NSNotFound)
    {
        [self addSubview:loadMoreView];
    }
}

@end
