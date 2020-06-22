//
//  UIViewController+ScriptMediator.m
//  GYScriptMessageMediator
//
//  Created by Yalay Gu on 2020/6/22.
//  Copyright © 2020 Yalay Gu. All rights reserved.
//

#import "UIViewController+ScriptMediator.h"
#import <objc/runtime.h>

#if !__has_feature(objc_arc)
#error This file must be compiled with ARC. Convert your project to ARC or specify the -fobjc-arc flag.
#endif

static void *WebViewScriptMediatorKey = &WebViewScriptMediatorKey;
static void *WebViewScriptMediatorKeyNonRetainingKey = &WebViewScriptMediatorKeyNonRetainingKey;

@implementation UIViewController (ScriptMediator)

- (GYScriptMessageMediator *)ScriptMediator
{
    id mediator = objc_getAssociatedObject(self, WebViewScriptMediatorKey);
    if (!mediator) {
        mediator = [GYScriptMessageMediator mediatorWithTarget:self];
        self.ScriptMediator = mediator;
    }
    return mediator;
}

- (void)setScriptMediator:(GYScriptMessageMediator *)ScriptMediator
{
    objc_setAssociatedObject(self, WebViewScriptMediatorKey, ScriptMediator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (GYScriptMessageMediator *)ScriptMediatorNonRetaining
{
    id mediator = objc_getAssociatedObject(self, WebViewScriptMediatorKeyNonRetainingKey);
    if (!mediator) {
        mediator = [[GYScriptMessageMediator alloc] initWithTarget:self targetRetained:NO];
        self.ScriptMediatorNonRetaining= mediator;
    }
    return mediator;
}

- (void)setScriptMediatorNonRetaining:(GYScriptMessageMediator *)ScriptMediatorNonRetaining
{
    objc_setAssociatedObject(self, WebViewScriptMediatorKeyNonRetainingKey, ScriptMediatorNonRetaining, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
