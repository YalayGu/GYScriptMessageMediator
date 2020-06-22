//
//  UIViewController+ScriptMediator.h
//  GYScriptMessageMediator
//
//  Created by Yalay Gu on 2020/6/22.
//  Copyright © 2020 Yalay Gu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GYScriptMessageMediator.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (ScriptMediator)

@property (nonatomic, strong) GYScriptMessageMediator *ScriptMediator;

@property (nonatomic, strong) GYScriptMessageMediator *ScriptMediatorNonRetaining;

@end

NS_ASSUME_NONNULL_END
