//
//  PMLWebViewController.h
//  PelMel
//
//  Created by Christophe Fondacci on 16/04/2015.
//  Copyright (c) 2015 Christophe Fondacci. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PMLWebViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIWebView *webview;
@property (copy, nonatomic) NSString *url;
@end
