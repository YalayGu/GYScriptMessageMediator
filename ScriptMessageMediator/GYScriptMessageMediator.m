//
//  GYScriptMessageMediator.m
//  GYScriptMessageMediator
//
//  Created by Yalay Gu on 2020/6/22.
//  Copyright © 2020 Yalay Gu. All rights reserved.
//

#import "GYScriptMessageMediator.h"
#import <pthread/pthread.h>

#pragma mark - GYScriptMessageInfo

typedef NS_ENUM(uint8_t, GYScriptMessageInfoState) {
    GYScriptMessageInfoStateInitial = 0,
    GYScriptMessageInfoStateAdd,
    GYScriptMessageInfoStateNotAdd
};

@interface GYScriptMessageInfo : NSObject

@end

@implementation GYScriptMessageInfo
{
@public
    __weak GYScriptMessageMediator *_mediator;
    NSString *_name;
    SEL _action;
    GYScriptMessageDidReceiveCompletion _completion;
    GYScriptMessageInfoState _state;
}

- (instancetype)initWithMediator:(GYScriptMessageMediator *)mediator name:(NSString *)name completion:(GYScriptMessageDidReceiveCompletion)completion action:(SEL)action
{
    self = [super init];
    if (nil != self) {
        _mediator = mediator;
        _name = name.copy;
        _completion = [completion copy];
        _action = action;
    }
    return self;
}

- (instancetype)initWithMediator:(GYScriptMessageMediator *)mediator name:(NSString *)name completion:(GYScriptMessageDidReceiveCompletion)completion
{
    return [self initWithMediator:mediator name:name completion:completion action:NULL];
}

- (instancetype)initWithMediator:(GYScriptMessageMediator *)mediator name:(NSString *)name action:(SEL)action
{
    return [self initWithMediator:mediator name:name completion:NULL action:action];
}

- (NSUInteger)hash
{
    return [_name hash];
}

- (BOOL)isEqual:(id)object
{
    if (nil == object) {
        return NO;
    }
    if (self == object) {
        return YES;
    }
    if (![object isKindOfClass:[self class]]) {
        return NO;
    }
    return [_name isEqualToString:((GYScriptMessageInfo *)object)->_name];
}

@end


#pragma mark GYScriptMessageMediatorCenter

@interface GYScriptMessageMediatorCenter : NSObject<WKScriptMessageHandler>

+ (instancetype)sharedCenter;

- (void)addScriptMessageHandler:(WKUserContentController *)userContentController info:(GYScriptMessageInfo *)info;

- (void)removeScriptMessageHandler:(WKUserContentController *)userContentController info:(GYScriptMessageInfo *)info;

- (void)removeScriptMessageHandler:(WKUserContentController *)userContentController infos:(NSSet<GYScriptMessageInfo *> *)infos;

@end

@implementation GYScriptMessageMediatorCenter
{
    NSHashTable<GYScriptMessageInfo *> *_infos;
    pthread_mutex_t _mutex;
}

+ (instancetype)sharedCenter
{
    static GYScriptMessageMediatorCenter *center = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        center = [[GYScriptMessageMediatorCenter alloc] init];
    });
    return center;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSHashTable *infos = [NSHashTable alloc];
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
        _infos = [infos initWithOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsObjectPersonality capacity:0];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
        if ([NSHashTable respondsToSelector:@selector(weakObjectsHashTable)]) {
            _infos = [infos initWithOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsObjectPersonality capacity:0];
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            _infos = [infos initWithOptions:NSPointerFunctionsZeroingWeakMemory|NSPointerFunctionsObjectPersonality capacity:0];
#pragma clang diagnostic pop
        }
        
#endif
        pthread_mutex_init(&_mutex, NULL);
    }
    return self;
}

- (void)dealloc
{
    pthread_mutex_destroy(&_mutex);
}

- (void)addScriptMessageHandler:(WKUserContentController *)userContentController info:(GYScriptMessageInfo *)info
{
    if (!info) {
        return;
    }
    
    pthread_mutex_lock(&_mutex);
    [_infos addObject:info];
    pthread_mutex_unlock(&_mutex);
    
    [userContentController addScriptMessageHandler:self name:info->_name];
    
    if (info->_state == GYScriptMessageInfoStateInitial) {
        info->_state = GYScriptMessageInfoStateAdd;
    } else if (info->_state == GYScriptMessageInfoStateNotAdd) {
        [userContentController removeScriptMessageHandlerForName:info->_name];
    }
}

- (void)removeScriptMessageHandler:(WKUserContentController *)userContentController info:(GYScriptMessageInfo *)info
{
    if (!info) {
        return;
    }
    
    pthread_mutex_lock(&_mutex);
    [_infos removeObject:info];
    pthread_mutex_unlock(&_mutex);
    
    if (info->_state == GYScriptMessageInfoStateAdd) {
        [userContentController removeScriptMessageHandlerForName:info->_name];
    }
    info->_state = GYScriptMessageInfoStateNotAdd;
}

- (void)removeScriptMessageHandler:(WKUserContentController *)userContentController infos:(NSSet<GYScriptMessageInfo *> *)infos
{
    if (!infos.count) {
        return;
    }
    
    pthread_mutex_lock(&_mutex);
    for (GYScriptMessageInfo *info in infos) {
        [_infos removeObject:info];
    }
    pthread_mutex_unlock(&_mutex);
    
    for (GYScriptMessageInfo *info in infos) {
        if (info->_state == GYScriptMessageInfoStateAdd) {
            [userContentController removeScriptMessageHandlerForName:info->_name];
        }
        info->_state = GYScriptMessageInfoStateNotAdd;
    }
}


#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    GYScriptMessageInfo *info = [[GYScriptMessageInfo alloc] initWithMediator:NULL name:message.name completion:NULL];
    
    pthread_mutex_lock(&_mutex);
    info = [_infos member:info];
    pthread_mutex_unlock(&_mutex);
    
    if (info) {
        GYScriptMessageMediator *mediator = info->_mediator;
        if (mediator) {
            id target = mediator.target;
            if (target) {
                if (info->_completion) {
                    info->_completion(target, userContentController, message);
                } else if (info->_action) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    [target performSelector:info->_action withObject:message withObject:userContentController];
#pragma clang diagnostic pop
                } else {
                    [target userContentController:userContentController didReceiveScriptMessage:message];
                }
            }
        }
    }
}

@end


#pragma mark - GYScriptMessageMediator

@implementation GYScriptMessageMediator
{
    NSMapTable<WKUserContentController *, NSMutableSet<GYScriptMessageInfo *> *> *_objectInfosMap;
    pthread_mutex_t _lock;
}

+ (instancetype)mediatorWithTarget:(UIViewController *)target
{
    return [[self alloc] initWithTarget:target];
}

- (instancetype)initWithTarget:(UIViewController *)target targetRetained:(BOOL)targetRetained
{
    self = [super init];
    if (self) {
        _target = target;
        NSPointerFunctionsOptions keyOptions = targetRetained ? NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPointerPersonality : NSPointerFunctionsWeakMemory|NSPointerFunctionsObjectPointerPersonality;
        _objectInfosMap = [[NSMapTable alloc] initWithKeyOptions:keyOptions valueOptions:NSPointerFunctionsStrongMemory|NSPointerFunctionsObjectPersonality capacity:0];
        pthread_mutex_init(&_lock, NULL);
    }
    return self;
}

- (instancetype)initWithTarget:(UIViewController *)target
{
    return [self initWithTarget:target targetRetained:NO];
}

- (void)dealloc
{
    [self _removeAllScriptMessageHandlers];
    pthread_mutex_destroy(&_lock);
}

- (void)addScriptMessageHandler:(WKUserContentController *)userContentController name:(NSString *)name completion:(GYScriptMessageDidReceiveCompletion)completion
{
    GYScriptMessageInfo *info = [[GYScriptMessageInfo alloc] initWithMediator:self name:name completion:completion];
    [self _addScriptMessageHandler:userContentController info:info];
}

- (void)addScriptMessageHandler:(WKUserContentController *)userContentController name:(NSString *)name action:(SEL)action
{
    GYScriptMessageInfo *info = [[GYScriptMessageInfo alloc] initWithMediator:self name:name action:action];
    [self _addScriptMessageHandler:userContentController info:info];
}

- (void)removeScriptMessageHandler:(WKUserContentController *)userContentController name:(NSString *)name
{
    GYScriptMessageInfo *info = [[GYScriptMessageInfo alloc] initWithMediator:self name:name completion:NULL];
    [self _removeScriptMessageHandler:userContentController info:info];
}

- (void)removeAllScriptMessageHandlers:(WKUserContentController *)userContentController
{
    [self _removeAllScriptMessageHandlersForController:userContentController];
}

- (void)removeAllScriptMessageHandlers
{
    [self _removeAllScriptMessageHandlers];
}


#pragma mark Utilities -

- (void)_addScriptMessageHandler:(WKUserContentController *)userContentController info:(GYScriptMessageInfo *)info
{
    pthread_mutex_lock(&_lock);
    NSMutableSet *infos = [_objectInfosMap objectForKey:userContentController];
    GYScriptMessageInfo *existingInfo = [infos member:info];
    if (existingInfo) {
        pthread_mutex_unlock(&_lock);
        return;
    }
    if (!infos) {
        infos = [NSMutableSet set];
        [_objectInfosMap setObject:infos forKey:userContentController];
    }
    [infos addObject:info];
    pthread_mutex_unlock(&_lock);
    
    [[GYScriptMessageMediatorCenter sharedCenter] addScriptMessageHandler:userContentController info:info];
}

- (void)_removeScriptMessageHandler:(WKUserContentController *)userContentController info:(GYScriptMessageInfo *)info
{
    pthread_mutex_lock(&_lock);
    NSMutableSet *infos = [_objectInfosMap objectForKey:userContentController];
    GYScriptMessageInfo *registeredInfo = [infos member:info];
    if (registeredInfo) {
        [infos removeObject:registeredInfo];
        if (!infos.count) {
            [_objectInfosMap removeObjectForKey:userContentController];
        }
    }
    pthread_mutex_unlock(&_lock);
    
    [[GYScriptMessageMediatorCenter sharedCenter] removeScriptMessageHandler:userContentController info:registeredInfo];
}

- (void)_removeAllScriptMessageHandlersForController:(WKUserContentController *)controller
{
    pthread_mutex_lock(&_lock);
    NSMutableSet *infos = [_objectInfosMap objectForKey:controller];
    [_objectInfosMap removeObjectForKey:controller];
    pthread_mutex_unlock(&_lock);
    
    [[GYScriptMessageMediatorCenter sharedCenter] removeScriptMessageHandler:controller infos:infos];
}

- (void)_removeAllScriptMessageHandlers
{
    pthread_mutex_lock(&_lock);
    NSMapTable *objectInfoMaps = [_objectInfosMap copy];
    [_objectInfosMap removeAllObjects];
    pthread_mutex_unlock(&_lock);
    
    GYScriptMessageMediatorCenter *shareCenter = [GYScriptMessageMediatorCenter sharedCenter];
    for (id object in objectInfoMaps) {
        NSSet *infos = [objectInfoMaps objectForKey:object];
        [shareCenter removeScriptMessageHandler:object infos:infos];
    }
}

@end
