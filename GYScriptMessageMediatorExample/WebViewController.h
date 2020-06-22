//
//  WebViewController.h
//  GYScriptMessageMediatorExample
//
//  Created by Aaron on 2020/6/6.
//  Copyright © 2020 Guyalay. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class WKWebView;
@interface WebViewController : UIViewController

@property (nonatomic, weak, readonly) WKWebView *webView;

- (instancetype)initWithURL:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
