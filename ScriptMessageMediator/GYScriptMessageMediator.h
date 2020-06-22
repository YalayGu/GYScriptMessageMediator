//
//  GYScriptMessageMediator.h
//  GYScriptMessageMediator
//
//  Created by Yalay Gu on 2020/6/22.
//  Copyright © 2020 Yalay Gu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

// refer to FBKVOController
NS_ASSUME_NONNULL_BEGIN

typedef void (^GYScriptMessageDidReceiveCompletion)(UIViewController *controller, WKUserContentController *userContentController, WKScriptMessage *message);

@interface GYScriptMessageMediator : NSObject

+ (instancetype)mediatorWithTarget:(UIViewController *)target;

- (instancetype)initWithTarget:(UIViewController *)target targetRetained:(BOOL)targetRetained NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithTarget:(UIViewController *)target;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)new NS_UNAVAILABLE;

@property (nullable, nonatomic, weak, readonly) UIViewController *target;

- (void)addScriptMessageHandler:(WKUserContentController *)userContentController name:(NSString *)name completion:(GYScriptMessageDidReceiveCompletion)completion;

- (void)addScriptMessageHandler:(WKUserContentController *)userContentController name:(NSString *)name action:(SEL)action;

- (void)removeScriptMessageHandler:(WKUserContentController *)userContentController name:(NSString *)name;

- (void)removeAllScriptMessageHandlers:(WKUserContentController *)userContentController;

- (void)removeAllScriptMessageHandlers;

@end

NS_ASSUME_NONNULL_END
