//
//  WDDConstants.h
//
//
//  Created by Sergii Gordiienko on 23.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDErrorConstants.h"

#pragma mark - Settings

#define ON 1
#define OFF 0

#define FB_GROUPS_SUPPORT ON
#define FB_EVENTS_SUPPORT OFF
#define LINKEDIN_GROUPS_SUPPORT OFF
#define IGNORE_GOOGLE ON

extern NSString * const kLinkToWoddlOnAppStore;

extern NSString * const kFirstStartUserDefaultsKey;

#pragma mark - Link shorter settings

extern NSString * const kLinkShorterURL;
extern NSString * const kLinkShorterUsername;
extern NSString * const kLinkShorterPassword;

extern NSString * const PostsUpdateStarted;

extern NSString * const DefaultSposorsSiteURL;
extern NSString * const kSponsorURLKey;

extern NSString * const DefaultSposorsLinkTitle;
extern NSString * const kSponsorLinkTitleKey;

#pragma mark - Debug settings



#pragma mark - SocialNetworks access info

extern NSString * kFacebookAccessKey;
extern NSString * kGooglePlusClientID;
extern NSString * kGooglePlusClientSecret;
extern NSString * kLinkedInApiKey;
extern NSString * kLinkedInSecret;
extern NSString * kTwitterConsumerKey;
extern NSString * kTwitterConsumerSecret;
extern NSString * kFourSquareClientID;
extern NSString * kFourSquareSecret;
extern NSString * kInstagrammClientID;
extern NSString * kInstagrammClientSecret;

#pragma mark - Storyboard idenitifiers

//  View Controllers' IDs
extern NSString * const kStoryboardIDMainScreen;
extern NSString * const kStoryboardIDMainScreenNavigationViewController;
extern NSString * const kStoryboardIDSideMenuScreen;
extern NSString * const kStoryboardIDReadLaterScreen;
extern NSString * const kStoryboardIDReadLaterScreenNavigationViewController;
extern NSString * const kStoryboardIDContactsScreen;
extern NSString * const kStoryboardIDChatScreen;
extern NSString * const kStoryboardIDSearchScreen;
extern NSString * const kStoryboardIDSearchScreenNavigationViewController;
extern NSString * const kStoryboardIDStatusScreen;
extern NSString * const kStoryboardIDStatusScreenNavigationViewController;
extern NSString * const kStoryboardIDSlidingScreen;
extern NSString * const kStoryboardIDLoginScreen;
extern NSString * const kStoryboardIDPoweredByScreen;
extern NSString * const kStoryboardIDTwitterReplyScreen;
extern NSString * const kStoryboardIDTwitterReplyScreenNavigationViewController;
extern NSString * const kStoryboardIDWriteCommentScreen;
extern NSString * const kStoryboardIDWriteCommentNavigationViewController;
extern NSString * const kStoryboardIDSNSettingsScreen;
extern NSString * const kStoryboardIDSNSettingsScreenNavigationViewController;
extern NSString * const kStoryboardIDAddNetworkScreen;
extern NSString * const kStoryboardIDAddNetworkNavigationViewController;
extern NSString * const kStoryboardIDStatusSNAccountsViewController;
extern NSString * const kStoryboardIDWebViewViewController;
extern NSString * const kStoryboardIDWebViewNavigationViewController;
extern NSString * const kStoryboardIDWhoLikedViewControllerViewController;
extern NSString * const kStoryboardSegueIDGuideScreenAfterLogin;
extern NSString * const kStoryboardSegueIDMainSlidingScreenAfterAfterGuide;

//  Segues' IDs
extern NSString * const kStoryboardSegueIDContacts;
extern NSString * const kStoryboardSegueIDChat;
extern NSString * const kStoryboardSegueIDSearch;
extern NSString * const kStoryboardSegueIDStatusScreen;
extern NSString * const kStoryboardSegueIDAddFriendsScreen;
extern NSString * const kStoryboardSegueIDLoginScreen;
extern NSString * const kStoryboardSegueIDMainSlidingScreen;
extern NSString * const kStoryboardSegueIDMainSlidingScreenAfterLogin;
extern NSString * const kStoryboardSegueIDTwitterReply;
extern NSString * const kStoryboardSegueIDWriteComment;
extern NSString * const kStoryboardSegueIDSNSettings;
extern NSString * const kStoryboardSegueIDAddNetworkScreen;
extern NSString * const kStoryboardSegueIDUnwindBackFromSettingsSegue;
extern NSString * const kStoryboardSegueIDWriteCommentFromSearch;
extern NSString * const kStoryboardSegueIDWriteCommentFromReadLater;
extern NSString * const kStoryboardSegueIDTwitterReplyFromSearch;
extern NSString * const kStoryboardSegueIDWebViewFromSideMenu;
extern NSString * const kStoryboardIDAddFriendsViewController;
extern NSString * const kStoryboardSegueIDPoweredByViewFromSlideView;

// Errors
extern NSString * const WDDErrorDomain;

// Keychain gruop
extern NSString * const kWoddlKeychainGroup;

#pragma mark - Coredata

//  CoreData fetch request
extern NSString * const kCoredataFetchRequestAllSocialNetworks;
extern NSString * const kCoredataFetchRequestSocialNetworksWithToken;
extern NSString * const kCoredataFetchRequestSocialNetworksWithTokenPrefix;
extern NSString * const kCoredataFetchRequestSocialNetworksWithProfileUserID;

//  CoreData feth request keys
extern NSString * const kCoredataFetchRequestKeyAccessToken;
extern NSString * const kCoredataFetchRequestKeyAccessTokenPrefix;
extern NSString * const kCoredataFetchRequestKeyProfileUserID;

#pragma mark - Parse

//  Parse SDK
extern NSString * const kParseAppID;
extern NSString * const kParseClientKey;

#pragma mark - Bug report information
//  Send feedback and bug report
extern NSString * const kBugReportEmail;

#pragma mark - Analytics

extern NSString * const kFlurryAnalyticsAppKey;
extern NSString * const kGoogleAnalyticsTrackingId;

#pragma mark - Testflight

//#if IS_TESTFLIGHT_RELEASE == ON
extern NSString * const kTestflightSDKAppKey;
//#endif


#pragma mark - Image names constants

extern NSString * const kAvatarPlaceholderImageName;
extern NSString * const kFacebookIconImageName;
extern NSString * const kTwitterIconImageName;
extern NSString * const kGoogleIconImageName;
extern NSString * const kLinkedInIconImageName;
extern NSString * const kFoursquareIconImageName;
extern NSString * const kInstagramIconImageName;
extern NSString * const kCellBottomShadowImageName;
extern NSString * const kCommentIconImageName;
extern NSString * const kMediaTriangleImageName;

extern NSString * const kFacebookLikesIconImageName;
extern NSString * const kTwitterLikesIconImageName;
extern NSString * const kGoogleLikesIconImageName;
extern NSString * const kFoursquareLikesIconImageName;
extern NSString * const kInstagramLikesIconImageName;
extern NSString * const kLinkedInLikesIconImageName;

extern NSString * const kFacebookCommentsIconImageName;
extern NSString * const kTwitterCommentsIconImageName;
extern NSString * const kGoogleCommentsIconImageName;
extern NSString * const kFoursquareCommentsIconImageName;
extern NSString * const kInstagramCommentsIconImageName;
extern NSString * const kLinkedInCommentsIconImageName;

extern NSString * const kTwitterSaveImageButtonImageName;
extern NSString * const kFacebookSaveImageButtonImageName;
extern NSString * const kGooglePlusSaveImageButtonImageName;
extern NSString * const kInstagramSaveImageButtonImageName;
extern NSString * const kLinkedInSaveImageButtonImageName;
extern NSString * const kFoursquareSaveImageButtonImageName;

extern NSString * const kStatusLocationButtonImageName;
extern NSString * const kStatusLocationActiveButtonImageName;
extern NSString * const kWhiteCheckmarkChecked;
extern NSString * const kWhiteCheckmarkUnchecked;
extern NSString * const kWhiteCheckmartInactive;
extern NSString * const kAvatarPlaceholder;
extern NSString * const kContactsSectionAvatarMask;
extern NSString * const kContactsSectionBackgroundImageName;
extern NSString * const kWebViewTitleAvatarMask;
extern NSString * const kBackButtonArrowImageName;

#pragma mark - Social network tags

typedef NS_ENUM(NSInteger, SocialNetworkType) {
    kSocialNetworkUnknown                     = 0,
    kSocialNetworkFacebook                    = 1 << 0,
    kSocialNetworkTwitter                     = 1 << 1,
    kSocialNetworkLinkedIN                    = 1 << 2,
    kSocialNetworkGooglePlus                  = 1 << 3,
    kSocialNetworkInstagram                   = 1 << 4,
    kSocialNetworkFoursquare                  = 1 << 5
};

extern NSString * snClassName(SocialNetworkType x);
#define SOCIAL_NETWORK_CLASSNAME_FROM_ENUM(x) snClassName(x)

#pragma mark - Ellipse menu

typedef NS_ENUM(NSInteger, EllipseMenuLeftButtonTags)
{
    kEllipseMenuLikeButtonTag = 1000,
    kEllipseMenuShareButtonTag,
    kEllipseMenuCommentButtonTag,
    kEllipseMenuMailButtonTag,
    kEllipseMenuCopyLinkButtonTag,
    kEllipseMenuTwitterReplyButtonTag,
    kEllipseMenuTwitterRetweetButtonTag,
    kEllipseMenuTwitterQouteButtonTag,
    kEllipseMenuBlockButtonTag,
    kEllipseMenuReadLaterButtonTag,
    kEllipseMenuSaveImageButtonTag
};

//  Social networks buttons icons
extern NSString * const kFacebookButtonImageName;
extern NSString * const kFoursquareButtonImageName;
extern NSString * const kGooglePlusButtonImageName;
extern NSString * const kInstagramButtonImageName;
extern NSString * const kLinkedInButtonImageName;
extern NSString * const kTwitterButtonImageName;

//  Twitter network buttons icons
extern NSString * const kTwitterReplyButtonImageName;
extern NSString * const kTwitterRetweetButtonImageName;
extern NSString * const kTwitterQouteButtonImageName;
extern NSString * const kTwitterFavoriteButtonImageName;
extern NSString * const kTwitterMailButtonImageName;
extern NSString * const kTwitterCopyLinkButtonImageName;
extern NSString * const kTwitterBlockButtonImageName;
extern NSString * const kTwitterReadLaterButtonImageName;

//  Facebook network buttons icons
extern NSString * const kFacebookLikeButtonImageName;
extern NSString * const kFacebookShareButtonImageName;
extern NSString * const kFacebookCommentButtonImageName;
extern NSString * const kFacebookMailButtonImageName;
extern NSString * const kFacebookCopyLinkButtonImageName;
extern NSString * const kFacebookBlockButtonImageName;
extern NSString * const kFacebookReadLaterButtonImageName;

//  GooglePlus network buttons icnos
extern NSString * const kGooglePlusLikeButtonImageName;
extern NSString * const kGooglePlusShareButtonImageName;
extern NSString * const kGooglePlusCommentButtonImageName;
extern NSString * const kGooglePlusMailButtonImageName;
extern NSString * const kGooglePlusCopyLinkButtonImageName;
extern NSString * const kGooglePlusBlockButtonImageName;
extern NSString * const kGooglePlusReadLaterButtonImageName;

//  Instagram network buttons icons
extern NSString * const kInstagramLikeButtonImageName;
extern NSString * const kInstagramCommentButtonImageName;
extern NSString * const kInstagramMailButtonImageName;
extern NSString * const kInstagramCopyLinkButtonImageName;
extern NSString * const kInstagramBlockButtonImageName;
extern NSString * const kInstagramReadLaterButtonImageName;

//  LinkedIn network buttons icons
extern NSString * const kLinkedInLikeButtonImageName;
extern NSString * const kLinkedInShareButtonImageName;
extern NSString * const kLinkedInCommentButtonImageName;
extern NSString * const kLinkedInMailButtonImageName;
extern NSString * const kLinkedInCopyLinkButtonImageName;
extern NSString * const kLinkedInBlockButtonImageName;
extern NSString * const kLinkedInReadLaterButtonImageName;

//  Foursquare network buttons icons
extern NSString * const kFoursquareLikeButtonImageName;
extern NSString * const kFoursquareShareButtonImageName;
extern NSString * const kFoursquareCommentButtonImageName;
extern NSString * const kFoursquareMailButtonImageName;
extern NSString * const kFoursquareCopyLinkButtonImageName;
extern NSString * const kFoursquareBlockButtonImageName;
extern NSString * const kFoursquareReadLaterButtonImageName;

#pragma mark - Notifications
//  Notifications
extern NSString * const kNotificationInternetNotConnected;
extern NSString * const kNotificationDidDownloadNewPots;
extern NSString * const kNotificationRefetchMainSreenTable;
extern NSString * const kNotificationUnreadMessageRecieved;
extern NSString * const kNotificationUpdatingStatusChanged;
extern NSString * const kNotificationParamaterStatus;
extern NSString * const kNotificationNotificationsDidUpdate;

#pragma mark - URL tags base
extern NSString * const kTagURLBase;
extern NSString * const kPlaceURLBase;
extern NSString * const kTwitterNameURLBase;
extern NSString * const kInstagramNameURLBase;
extern NSString * const kShowMoreURLBase;

extern const float kPostFontSize;