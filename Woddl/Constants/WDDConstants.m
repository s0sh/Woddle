//
//  WDDConstants.m
//  Woddl
//
//  Created by Sergii Gordiienko on 23.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDConstants.h"

NSString * const kLinkToWoddlOnAppStore = @"https://itunes.apple.com/us/app/woddl-for-facebook-twitter/id785655747?mt=8#";

NSString * const kFirstStartUserDefaultsKey = @"com.ids.woddl.is_not_first_start";

#pragma mark - Link shorter settings

NSString * const kLinkShorterURL = @"http://woddl.it/yourls-api.php";
NSString * const kLinkShorterUsername = @"username";
NSString * const kLinkShorterPassword = @"gMzWvs$%";

NSString * const PostsUpdateStarted = @"com.ids.woddl.posts_update_started";

NSString * const DefaultSposorsSiteURL = @"";
NSString * const kSponsorURLKey = @"com.ids.woddl.sponsor_url";

NSString * const DefaultSposorsLinkTitle = @"";
NSString * const kSponsorLinkTitleKey = @"com.ids.woddl.sponsor_link_title";

#pragma mark - SocialNetworks access info

NSString * kFacebookAccessKey = @"435977526532008";
NSString * kGooglePlusClientID     = @"806795333370.apps.googleusercontent.com";
NSString * kGooglePlusClientSecret = @"Jz3QSxe5Bl6cag9hYO9kTZRW";
NSString * kLinkedInApiKey = @"77hl1mpeqkb41r";
NSString * kLinkedInSecret = @"0CTNmZfswzTyfxVp";
NSString * kTwitterConsumerKey = @"CjcE8qsAvtJ4Nrv2GH9A";
NSString * kTwitterConsumerSecret = @"RrMGMW3qnzKRCef5zg9FmkBztp0WsxaP91PDufS0";
NSString * kFourSquareClientID = @"ARDKCO0HYN15S3CZGUQJBGZ2ACIZEA0L3WTQ2DKT0GQQ4YHV";
NSString * kFourSquareSecret = @"0QRGRTB5VVS3FSEE0SLYBO5BXWLUGDFF3WMZO3OCZGZ1PGQO";
NSString * kInstagrammClientID = @"5b9465bb5f0e40588f464051a8555ad7";
NSString * kInstagrammClientSecret = @"1984512fff414353bc285f0be91908a5";

#pragma mark - Storyboard idenitifiers

//  View Controllers' IDs
NSString * const kStoryboardIDMainScreen                                    = @"MainScreen";
NSString * const kStoryboardIDMainScreenNavigationViewController            = @"MainScreenNavigationController";
NSString * const kStoryboardIDSideMenuScreen                                = @"SideMenu";
NSString * const kStoryboardIDReadLaterScreen                               = @"ReadLaterScreen";
NSString * const kStoryboardIDReadLaterScreenNavigationViewController       = @"ReadLaterScreenNavigationController";
NSString * const kStoryboardIDContactsScreen                                = @"ContactsScreen";
NSString * const kStoryboardIDChatScreen                                    = @"ChatScreen";
NSString * const kStoryboardIDSearchScreen                                  = @"SearchScreen";
NSString * const kStoryboardIDSearchScreenNavigationViewController          = @"SearchScreenNavigationViewController";
NSString * const kStoryboardIDStatusScreen                                  = @"StatusScreen";
NSString * const kStoryboardIDStatusScreenNavigationViewController          = @"StatusScreenNavigationViewController";
NSString * const kStoryboardIDSlidingScreen                                 = @"SlidingViewController";
NSString * const kStoryboardIDLoginScreen                                   = @"LoginScreen";
NSString * const kStoryboardIDPoweredByScreen                               = @"PoweredByScreen";
NSString * const kStoryboardIDTwitterReplyScreen                            = @"TwitterReplyScreen";
NSString * const kStoryboardIDTwitterReplyScreenNavigationViewController    = @"TwitterReplyScreenNavigationViewController";
NSString * const kStoryboardIDWriteCommentScreen                            = @"WriteCommentScreen";
NSString * const kStoryboardIDWriteCommentNavigationViewController          = @"WriteCommentScreenNavigationViewController";
NSString * const kStoryboardIDSNSettingsScreen                              = @"SNSettingsScreen";
NSString * const kStoryboardIDSNSettingsScreenNavigationViewController      = @"SNSettingsScreenNavigationViewController";
NSString * const kStoryboardIDAddNetworkScreen                              = @"AddNetworkScreen";
NSString * const kStoryboardIDAddNetworkNavigationViewController            = @"AddNetworkScreenNavigationViewController";
NSString * const kStoryboardIDStatusSNAccountsViewController                = @"StatusSNAccountsViewController";
NSString * const kStoryboardIDWebViewViewController                         = @"WebViewController";
NSString * const kStoryboardIDWebViewNavigationViewController               = @"WebViewNavigationController";
NSString * const kStoryboardIDWhoLikedViewControllerViewController          = @"WhoLikedViewController";
NSString * const kStoryboardIDAddFriendsViewController                      = @"AddFriendViewController";


//  Segues' IDs
NSString * const kStoryboardSegueIDContacts                         = @"GoToContactsScreenSegue";
NSString * const kStoryboardSegueIDChat                             = @"GoToChatScreenSegue";
NSString * const kStoryboardSegueIDSearch                           = @"GoToSearchScreenSegue";
NSString * const kStoryboardSegueIDStatusScreen                     = @"GoToStatusScreenSegue";
NSString * const kStoryboardSegueIDAddFriendsScreen                 = @"GoToAddFriendScreenSegue";
NSString * const kStoryboardSegueIDLoginScreen                      = @"GoToLoginScreenSegue";
NSString * const kStoryboardSegueIDMainSlidingScreen                = @"GoToMainSlideScreen";
NSString * const kStoryboardSegueIDMainSlidingScreenAfterLogin      = @"GoToMainSlideScreenAfterLoginSegue";
NSString * const kStoryboardSegueIDTwitterReply                     = @"GoToTwitterReplyScreenSegue";
NSString * const kStoryboardSegueIDWriteComment                     = @"GoToWriteCommentSegue";
NSString * const kStoryboardSegueIDSNSettings                       = @"GoToSocialNetworkSettings";
NSString * const kStoryboardSegueIDAddNetworkScreen                 = @"GoToAddNetworkScreen";
NSString * const kStoryboardSegueIDUnwindBackFromSettingsSegue      = @"BackFromProfileSettingsScreenSegue";
NSString * const kStoryboardSegueIDWriteCommentFromSearch           = @"GoToWriteCommentFromSearchSegue";
NSString * const kStoryboardSegueIDWriteCommentFromReadLater        = @"GoToWriteCommentFromReadLaterSegue";
NSString * const kStoryboardSegueIDTwitterReplyFromSearch           = @"GoToTwitterReplyScreenFromSearchSegue";
NSString * const kStoryboardSegueIDWebViewFromSideMenu              = @"GoToWebViewScreenSegue";
NSString * const kStoryboardSegueIDGuideScreenAfterLogin            = @"GoToGuideScreenAfterLoginSegue";
NSString * const kStoryboardSegueIDMainSlidingScreenAfterAfterGuide = @"GoToMainSlideScreenAfterGuideSegue";
NSString * const kStoryboardSegueIDPoweredByViewFromSlideView       = @"BackToPoweredByFromSlideMenu";

// Errors
NSString * const WDDErrorDomain                                     = @"WoddleErrorDomain";

NSString * const kWoddlKeychainGroup                                = nil;//@"WoddlAccounts";

#pragma mark - Coredata

// CoreDate socialnetwork classNames

NSString *snClassName(SocialNetworkType x)
{
    switch(x)
    {
        case kSocialNetworkUnknown:
            assert(NO);
            return nil;
        case kSocialNetworkFacebook:
            return @"FacebookSN";
        case kSocialNetworkTwitter:
            return @"TwitterSN";
        case kSocialNetworkInstagram:
            return @"InstagramSN";
        case kSocialNetworkFoursquare:
            return @"FoursquareSN";
        case kSocialNetworkLinkedIN:
            return @"LinkedinSN";
        case kSocialNetworkGooglePlus:
            return @"GooglePlusSN";
    }
}

//  CoreData fetch request
NSString * const kCoredataFetchRequestAllSocialNetworks                 = @"GetAllSocialNetworks";
NSString * const kCoredataFetchRequestSocialNetworksWithToken           = @"SocialNetworksWithAccessToken";
NSString * const kCoredataFetchRequestSocialNetworksWithTokenPrefix     = @"SocialNetworksWithAccessTokenPrefix";
NSString * const kCoredataFetchRequestSocialNetworksWithProfileUserID   = @"SocialNetworksWithProfileUserID";

//  CoreData feth request keys
NSString * const kCoredataFetchRequestKeyAccessToken                = @"TOKEN";
NSString * const kCoredataFetchRequestKeyAccessTokenPrefix          = @"TOKEN_PREFIX";
NSString * const kCoredataFetchRequestKeyProfileUserID              = @"USER_ID";

#pragma mark - Parse
//  Parse SDK
NSString * const kParseAppID            = @"XwFvurkkyHDfcJtH7LKpLogHVIhugber220yJ8l6";
NSString * const kParseClientKey        = @"ZQzVXWBUhAAEGjHHsyTxkznCOI1QzR3ZLaq2CPZ0";

#pragma mark - Analitycs

NSString * const kFlurryAnalyticsAppKey = @"RWKGQBHP9XCNYRF63GQM";
NSString * const kGoogleAnalyticsTrackingId = @"UA-47309286-1";

#pragma mark - Bug report information
//  Send feedback and bug report
NSString * const kBugReportEmail = @"shout@woddl.com";

//#if IS_TESTFLIGHT_RELEASE == ON
NSString * const kTestflightSDKAppKey = @"c4d5c3f8-78a7-43e4-a5ac-533a32e5853d";
//#endif

#pragma mark - Image names constants

NSString * const kAvatarPlaceholderImageName    = @"Sidebar_avatar_placeholder";
NSString * const kFacebookIconImageName         = @"facebookPostIcon";
NSString * const kTwitterIconImageName          = @"twitterPostIcon";
NSString * const kGoogleIconImageName           = @"googlePostIcon";
NSString * const kLinkedInIconImageName         = @"linkedinPostIcon";
NSString * const kFoursquareIconImageName       = @"foursquarePostIcon";
NSString * const kInstagramIconImageName        = @"instagramPostIcon";
NSString * const kCellBottomShadowImageName     = @"cell_bottom_shadow";
NSString * const kCommentIconImageName          = @"cell_comments_icon";
NSString * const kMediaTriangleImageName        = @"media_triangle";

NSString * const kFacebookLikesIconImageName    = @"cell_fb_likes_icon";
NSString * const kTwitterLikesIconImageName     = @"cell_tw_likes_icon";
NSString * const kGoogleLikesIconImageName      = @"cell_google_likes_icon";
NSString * const kFoursquareLikesIconImageName  = @"cell_fs_likes_icon";
NSString * const kInstagramLikesIconImageName   = @"cell_ig_likes_icon";
NSString * const kLinkedInLikesIconImageName    = @"cell_li_likes_icon";

NSString * const kFacebookCommentsIconImageName     = @"cell_fb_comments_icon";
NSString * const kTwitterCommentsIconImageName      = @"cell_tw_comments_icon";
NSString * const kGoogleCommentsIconImageName       = @"cell_google_comments_icon";
NSString * const kFoursquareCommentsIconImageName   = @"cell_fs_comments_icon";
NSString * const kInstagramCommentsIconImageName    = @"cell_ig_comments_icon";
NSString * const kLinkedInCommentsIconImageName     = @"cell_li_comments_icon";

NSString * const kStatusLocationButtonImageName         = @"status_location_btn";
NSString * const kStatusLocationActiveButtonImageName   = @"status_location_active_btn";
NSString * const kWhiteCheckmarkChecked                 = @"status_white_checkmark_checked";
NSString * const kWhiteCheckmarkUnchecked               = @"status_white_checkmark_unchecked";
NSString * const kWhiteCheckmartInactive                = @"status_white_checkmark_inactive";
NSString * const kAvatarPlaceholder                     = @"Sidebar_avatar_placeholder";
NSString * const kContactsSectionAvatarMask             = @"contacts_sectionAvatarRoundMask";
NSString * const kWebViewTitleAvatarMask                = @"webViewTitleAvatarRoundMask";
NSString * const kContactsSectionBackgroundImageName    = @"contacts_sectionBackground";


NSString * const kBackButtonArrowImageName              = @"back_button";

#pragma mark - Ellipse menu image names

NSString * const kFacebookButtonImageName        = @"FacebookMenuButton";
NSString * const kFoursquareButtonImageName      = @"FoursquareMenuButton";
NSString * const kGooglePlusButtonImageName      = @"GooglePlusMenuButton";
NSString * const kInstagramButtonImageName       = @"InstagramMenuButton";
NSString * const kLinkedInButtonImageName        = @"LinkedInMenuButton";
NSString * const kTwitterButtonImageName         = @"TwitterMenuButton";

//  Twitter network buttons icons
NSString * const kTwitterReplyButtonImageName       = @"TwitterReplyButton";
NSString * const kTwitterRetweetButtonImageName     = @"TwitterRetweetButton";
NSString * const kTwitterQouteButtonImageName       = @"TwitterQuoteButton";
NSString * const kTwitterFavoriteButtonImageName    = @"TwitterFavoriteButton";
NSString * const kTwitterMailButtonImageName        = @"TwitterMailPostButton";
NSString * const kTwitterCopyLinkButtonImageName    = @"TwitterCopyLinkButton";
NSString * const kTwitterBlockButtonImageName       = @"TwitterBlockButton";
NSString * const kTwitterReadLaterButtonImageName   = @"TwitterReadLaterButton";
NSString * const kTwitterSaveImageButtonImageName   = @"TwitterSaveImageButton";

//  Facebook network buttons icons
NSString * const kFacebookLikeButtonImageName       = @"FacebookLikeIcon";
NSString * const kFacebookShareButtonImageName      = @"FacebookShareButton";
NSString * const kFacebookCommentButtonImageName    = @"FacebookCommentButton";
NSString * const kFacebookMailButtonImageName       = @"FacebookMailPostButton";
NSString * const kFacebookCopyLinkButtonImageName   = @"FacebookCopyLinkButton";
NSString * const kFacebookBlockButtonImageName      = @"FacebookBlockButton";
NSString * const kFacebookReadLaterButtonImageName  = @"FacebookReadLaterButton";
NSString * const kFacebookSaveImageButtonImageName  = @"FacebookSaveImageButton";

//  GooglePlus network buttons icnos
NSString * const kGooglePlusLikeButtonImageName         = @"GooglePlusLikeButton";
NSString * const kGooglePlusShareButtonImageName        = @"GooglePlusShareButton";
NSString * const kGooglePlusCommentButtonImageName      = @"GooglePlusCommentButtons";
NSString * const kGooglePlusMailButtonImageName         = @"GooglePlusMailPostButton";
NSString * const kGooglePlusCopyLinkButtonImageName     = @"GooglePlusCopyLinkButton";
NSString * const kGooglePlusBlockButtonImageName        = @"GoogleBlockButton";
NSString * const kGooglePlusReadLaterButtonImageName    = @"GooglePlusReadLaterButton";
NSString * const kGooglePlusSaveImageButtonImageName    = @"GooglePlusSaveImageButton";

//  Instagram network buttons icons
NSString * const kInstagramLikeButtonImageName      = @"InstagramLikeButton";
NSString * const kInstagramCommentButtonImageName   = @"InstagramCommentButton";
NSString * const kInstagramMailButtonImageName      = @"InstagramMailPostButton";
NSString * const kInstagramCopyLinkButtonImageName  = @"InstagramCopyLinkButton";
NSString * const kInstagramBlockButtonImageName     = @"InstagramBlockButton";
NSString * const kInstagramReadLaterButtonImageName = @"InstagramReadLaterButton";
NSString * const kInstagramSaveImageButtonImageName = @"InstagramSaveImageButton";

//  LinkedIn network buttons icons
NSString * const kLinkedInLikeButtonImageName       = @"LinkedInLikeButton";
NSString * const kLinkedInShareButtonImageName      = @"LinkedInShareButton";
NSString * const kLinkedInCommentButtonImageName    = @"LinkedInCommentButton";
NSString * const kLinkedInMailButtonImageName       = @"LinkedInMailPostButton";
NSString * const kLinkedInCopyLinkButtonImageName   = @"LinkedInCopyLinkButton";
NSString * const kLinkedInBlockButtonImageName      = @"LinkedInBlockButton";
NSString * const kLinkedInReadLaterButtonImageName  = @"LinkedInReadLaterButton";
NSString * const kLinkedInSaveImageButtonImageName  = @"LinkedInSaveImageButton";

//  Foursquare network buttons icons
NSString * const kFoursquareLikeButtonImageName         = @"FoursquareLikeButton";
NSString * const kFoursquareShareButtonImageName        = @"FoursquareShareButton";
NSString * const kFoursquareCommentButtonImageName      = @"FoursquareCommentButton";
NSString * const kFoursquareMailButtonImageName         = @"FoursquareMailPostButton";
NSString * const kFoursquareCopyLinkButtonImageName     = @"FoursquareCopyLinkButton";
NSString * const kFoursquareBlockButtonImageName        = @"FoursquareBlockButton";
NSString * const kFoursquareReadLaterButtonImageName    = @"FourSquareReadLaterButton";
NSString * const kFoursquareSaveImageButtonImageName    = @"FoursquareSaveImageButton";

#pragma mark - Notifications
//  Notifications
NSString * const kNotificationInternetNotConnected      = @"com.ids.internetNotConnected";
NSString * const kNotificationDidDownloadNewPots        = @"com.ids.newpostloaded.otification";
NSString * const kNotificationDidDownloadMorePosts      = @"com.ids.morepostloaded.Notification";
NSString * const kNotificationRefetchMainSreenTable     = @"com.ids.reloadMainTableNotification";
NSString * const kNotificationUnreadMessageRecieved     = @"com.ids.unreadMessageRecievedNotification";
NSString * const kNotificationUpdatingStatusChanged     = @"com.ids.updatingStatusChangedNotificaiton";
NSString * const kNotificationParamaterStatus           = @"com.ids.StatusParameter";
NSString * const kNotificationNotificationsDidUpdate    = @"com.ids.didUpdateNotifications";

#pragma mark - URL tags base
NSString * const kTagURLBase = @"tag:";
NSString * const kPlaceURLBase = @"place:";
NSString * const kTwitterNameURLBase = @"twitterName:";
NSString * const kInstagramNameURLBase = @"instagramName:";
NSString * const kShowMoreURLBase = @"showMore:";

const float kPostFontSize = 12.0f;