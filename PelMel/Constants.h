//
//  Constants.h
//  PelMel
//
//  Created by Christophe Fondacci on 07/01/13.
//  Copyright (c) 2013 Christophe Fondacci. All rights reserved.
//

#ifndef togayther_Constants_h
#define togayther_Constants_h

#define PML_CHECKIN_DISTANCE 200000

#define PML_PROP_INTRO_DONE @"intro.done"
#define PML_PROP_PUSH_ENABLED @"pushEnabled"
#define PML_PROP_DEVICE_TOKEN @"deviceToken"
#define PML_PROP_USER_LAST_TOKEN @"pmlUserLastToken"
#define PML_PROP_USER_ANONYMOUS_TOKEN @"pmlUserAnonymousToken"
#define PML_PROP_USER_ANONYMOUS_ITEMKEY @"pmlUserAnonymousItemKey"


#define PML_NOTIFICATION_PUSH_RECEIVED @"pmlPushReceived"
#define PML_NOTIFICATION_PAYMENT_DONE @"pmlPaymentDone"
#define PML_NOTIFICATION_PAYMENT_FAILED @"pmlPaymentFailed"
#define PML_NOTIFICATION_PRODUCTS_LOADED @"pmlProductsLoaded"  // Products definition loaded from App Store

#define VIEW_INDEX_PLACES 0
#define VIEW_INDEX_MAP 1
#define VIEW_INDEX_EVENTS 2
#define VIEW_INDEX_CHAT 3
#define VIEW_INDEX_SETTINGS 4

#define SPECIAL_TYPE_OPENING @"OPENING"
#define SPECIAL_TYPE_HAPPY @"HAPPY_HOUR"
#define SPECIAL_TYPE_THEME @"THEME"

#define SB_ID_DETAIL_CONTROLLER @"detailViewController"
//#define SB_ID_SNIPPET_CONTROLLER @"snippetViewController"
#define SB_ID_SNIPPET_CONTROLLER @"snippetTableViewController"
#define SB_ID_FILTERS_CONTROLLER @"rearMenu"
#define SB_ID_THUMBS_CONTROLLER @"thumbTableController"
#define SB_LOGIN_CONTROLLER @"userLogin"
#define SB_ID_GALLERY @"imageGallery"
#define SB_ID_FILTERS_MENU @"filtersMenu"
#define SB_ID_MESSAGES @"messageView"
#define SB_ID_MESSAGES_TABLE @"messageTableView"
#define SB_ID_MYACCOUNT @"myAccount"
#define SB_ID_MENU_MANAGER @"menuManager"
#define SB_ID_PHOTO_GALLERY @"photoPreview"
#define SB_ID_PHOTO_PICKER_PREVIEW @"photoPickerPreview"
#define SB_ID_WEBVIEW @"webview"
#define SB_ID_ACTIVITY_STAT @"activityStats"
#define SB_ID_ACTIVITY_DETAILS @"activityDetails"
#define SB_ID_PHOTOS_COLLECTION @"photosCollectionView"
#define SB_ID_BANNER_EDITOR @"bannerEditor"
#define SB_ID_ITEM_SELECTION @"itemSelector"
#define SB_ID_BANNER_LIST @"bannersList"
#define SB_ID_NETWORK @"networkController"
#define SB_ID_NETWORK_CHECKINS @"networkCheckins"
#define SB_ID_PURCHASE @"purchaseController"
#define SB_ID_REPORTING @"reportController"
#define SB_ID_USE_DEAL @"useDealController"
#define SB_ID_LIST_DEALS @"listDealsController"
#define SB_ID_MSG_AUDIENCE @"msgAudience"

#define BACKGROUND_COLOR UIColorFromRGB(0x272a2e)


#define PML_PROP_SERVER @"url.server"
#define PML_PROP_LEFTHANDED @"settings.leftHanded"

#define kPMLKeyLastLatitude @"lastLatitude"
#define kPMLKeyLastLongitude @"lastLongitude"


#define MAP_HACK_TAG 24681357


#define PML_HELP_ADDCONTENT @"PMLaddcontent"
#define PML_HELP_FILTERS @"PMLfilters"
#define PML_HELP_FILTERS_MULTI @"PMLfiltersMulti"
#define PML_HELP_LOCALIZE @"PMLlocalize"
#define PML_HELP_REFRESH @"PMLrefresh"
#define PML_HELP_REFRESH_TIMER @"PMLrefreshTimer"
#define PML_HELP_SEARCH @"PMLsearch"
#define PML_HELP_CHECKIN @"PMLcheckin"
#define PML_HELP_CHECKIN_CLOSE @"PMLcheckinclose"
#define PML_HELP_EDIT @"PMLedit"
#define PML_HELP_BADGE @"PMLbadge"
#define PML_HELP_SNIPPET @"PMLsnippet"
#define PML_HELP_SNIPPET_EVENTS @"PMLsnippetEvents"

#define METERS_PER_MILE 1609.344f

// Property codes
#define PML_PROPERTY_CODE_PHONE @"phone"
#define PML_PROPERTY_CODE_WEBSITE @"website"


#define PML_ACTIVITY_PRIORITY @[@"I_PLAC",@"I_USER",@"K_PLAC",@"MDIA_CREATION",@"R_USER",@"I_EVNT",@"EVNT_CREATION",@"PLAC_CREATION",@"O_PLAC"]


// Store product identifiers
#define kPMLProductBanner1000 @"com.fgp.pelmel.banner1000"
#define kPMLProductBanner2500 @"com.fgp.pelmel.banner2500"
#define kPMLProductBanner6000 @"com.fgp.pelmel.banner6000"
#define kPMLProductBannerPrefix @"com.fgp.pelmel.banner"
#define kPMLProductClaim30 @"com.fgp.pelmel.claim30"
#define kPMLProductClaimPrefix @"com.fgp.pelmel.claim"
#define kPMLProductPremium30 @"com.fgp.pelmel.userPremium30"
#define kPMLProductPremiumPrefix @"com.fgp.pelmel.userPremium"

// Advertising
#define kPMLBannerMilesRadius 10.0f
#define kPMLBannerStatusReady @"READY"
#define kPMLBannerStatusPendingPayment @"PENDING_PAYMENT"
#define kPMLBannerStatusPaused @"PAUSED"
#define kPMLBannerStatusDeleted @"DELETED"

#define kPMLBannerCycleTimeSeconds 10


// Deals
#define DEAL_STATUS_RUNNING @"RUNNING"
#define DEAL_STATUS_PAUSED @"PAUSED"
#define PML_DEAL_MIN_REUSE_SECONDS 86400


// Terms
#define kPMLUrlTerms @"%@/terms-agreement"


#endif
