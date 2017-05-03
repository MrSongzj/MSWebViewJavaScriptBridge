//
//  UIWebView+MSJavaScriptBridge.m
//  Demo
//
//  Created by MrSong on 2017/4/25.
//  Copyright © 2017年 MrSong. All rights reserved.
//

#import "UIWebView+MSJavaScriptBridge.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <objc/runtime.h>

NSString *const MSJSBJSContextDidCreateNotification = @"MS_JSBJSContextDidCreateNotification";
NSString *const MSJSBCallbackSuffix = @"Callback";
NSString *const MSJSBJSContextKeyPath = @"documentView.webView.mainFrame.javaScriptContext";

void callHandlerByJSContext(JSContext *jsContext, NSString *handlerName, id args)
{
    JSValue *callHandler = jsContext[handlerName];
    NSMutableArray *allArgs = [NSMutableArray arrayWithObjects:callHandler, @0, nil];
    if (args) {
        if ([args isKindOfClass:[NSArray class]]) {
            [allArgs addObjectsFromArray:args];
        } else {
            [allArgs addObject:args];
        }
    }
    [callHandler.context[@"setTimeout"] callWithArguments:allArgs];
}

void registerHandlerForJSContext(JSContext *jsContext, NSString *handlerName, NSString *callbackName, MSJSBHandler handler)
{
    jsContext[handlerName] = ^{
        NSArray *arguments = [JSContext currentArguments];
        id jsArgs;
        if (arguments.count > 1) {
            jsArgs = [NSMutableArray arrayWithCapacity:arguments.count];
            for (NSUInteger i = 0; i < arguments.count; i ++) {
                JSValue *value = arguments[i];
                id obj = value.toObject;
                if (obj) {
                    [jsArgs addObject:obj];
                } else {
                    [jsArgs addObject:[NSNull null]];
                    NSLog(@"MSJSB: handler [%@] receive the arguments of undefined type at index %lu", handlerName, i);
                }
            }
        } else {
            JSValue *value = [arguments firstObject];
            if (value.isUndefined) {
                NSLog(@"MSJSB: handler [%@] receive the arguments of undefined type", handlerName);
            } else {
                jsArgs = value.toObject;
            }
        }
        void (^callback)(id args);
        if (callbackName.length > 0) {
            JSContext *currentContext = [JSContext currentContext];
            callback = ^(id args) {
                callHandlerByJSContext(currentContext, callbackName, args);
            };
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(jsArgs, callback);
        });
    };
}

NSString *wholeNameOfCallback(NSString *callbackName)
{
    return [callbackName stringByAppendingString:MSJSBCallbackSuffix];
}

@implementation NSObject (MSJSContextTrace)

- (void)webView:(id)webView didCreateJavaScriptContext:(JSContext *)ctx forFrame:(id)frame {
    [[NSNotificationCenter defaultCenter] postNotificationName:MSJSBJSContextDidCreateNotification object:nil];
}

@end

@interface UIWebView ()

@property (nonatomic, assign) BOOL ms_isRegistered;
@property (nonatomic, strong) JSContext *ms_jsContext;
@property (nonatomic, strong, readonly) NSMutableDictionary *ms_registerHandlers;
@property (nonatomic, strong, readonly) NSMutableDictionary *ms_jsCallbacks;

@end

@implementation UIWebView (MSJavaScriptBridge)

#pragma mark - 注册方法让 JS 调用

- (void)ms_registerHandler:(NSString *)handlerName handler:(MSJSBHandler)handler
{
    NSString *callbackName = wholeNameOfCallback(handlerName);
    [self ms_registerHandler:handlerName callbackName:callbackName handler:handler];
}

- (void)ms_registerHandler:(NSString *)handlerName callbackName:(NSString *)callbackName handler:(MSJSBHandler)handler
{
    if ((handlerName.length == 0) || (handler == nil)) {
        return;
    }
    if (self.ms_isRegistered == NO) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ms_jsContextDidCreate:) name:MSJSBJSContextDidCreateNotification object:nil];
        self.ms_isRegistered = YES;
    }
    // 保存方法和回调
    [self.ms_registerHandlers setObject:[handler copy] forKey:handlerName];
    if (callbackName.length > 0) {
        [self.ms_jsCallbacks setObject:callbackName forKey:handlerName];
    }
    JSContext *jsContext = self.ms_jsContext;
    if (jsContext) {
        // 注册方法
        registerHandlerForJSContext(jsContext, handlerName, callbackName, handler);
    }
}

#pragma mark - 调用 JS 的方法

- (void)ms_callHandler:(NSString *)handlerName
{
    [self ms_callHandler:handlerName data:nil callbackName:nil callback:nil];
}

- (void)ms_callHandler:(NSString *)handlerName data:(id)data
{
    [self ms_callHandler:handlerName data:data callbackName:nil callback:nil];
}

- (void)ms_callHandler:(NSString *)handlerName data:(id)data callback:(MSJSBCallback)callback
{
    NSString *callbackName = wholeNameOfCallback(handlerName);
    [self ms_callHandler:handlerName data:data callbackName:callbackName callback:callback];
}

- (void)ms_callHandler:(NSString *)handlerName data:(id)data callbackName:(NSString *)callbackName callback:(MSJSBCallback)jsCallback
{
    if (handlerName.length == 0) {
        return;
    }
    JSContext *jsContext = [self valueForKeyPath:MSJSBJSContextKeyPath];
    if (jsContext) {
        if ((callbackName.length > 0) && jsCallback) {
            // 注册回调
            [self ms_registerHandler:callbackName callbackName:nil handler:^(id args, MSJSBCallback callback) {
                jsCallback(args);
            }];
        }
        
        // 调 JS 的方法
        callHandlerByJSContext(jsContext, handlerName, data);
    }
}

#pragma mark - 移除注册的方法

- (void)ms_removeHandler:(NSString *)handlerName
{
    if (handlerName.length == 0) {
        return;
    }
    id handler = self.ms_registerHandlers[handlerName];
    if (handler) {
        [self.ms_registerHandlers removeObjectForKey:handlerName];
        JSContext *jsContext = [self valueForKeyPath:MSJSBJSContextKeyPath];
        if (jsContext) {
            jsContext[handlerName] = nil;
        }
    }
}

#pragma mark - Notification

- (void)ms_jsContextDidCreate:(NSNotification *)notification
{
    self.ms_jsContext = [self valueForKeyPath:MSJSBJSContextKeyPath];
}

- (void)dealloc
{
    if (self.ms_isRegistered) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:MSJSBJSContextDidCreateNotification object:nil];
    }
}

#pragma mark - Getter And Setter

- (BOOL)ms_isRegistered
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setMs_isRegistered:(BOOL)ms_isRegistered
{
    objc_setAssociatedObject(self, @selector(ms_isRegistered), @(ms_isRegistered), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (JSContext *)ms_jsContext
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setMs_jsContext:(JSContext *)ms_jsContext
{
    if (self.ms_jsContext == ms_jsContext) {
        return;
    }
    if (ms_jsContext) {
        NSDictionary *registerHandlers = self.ms_registerHandlers;
        NSDictionary *jsCallbacks = self.ms_jsCallbacks;
        for (NSString *handlerName in registerHandlers) {
            MSJSBHandler handler = registerHandlers[handlerName];
            NSString *callbackName = jsCallbacks[handlerName];
            registerHandlerForJSContext(ms_jsContext, handlerName, callbackName, handler);
        }
    }
    objc_setAssociatedObject(self, @selector(ms_jsContext), ms_jsContext, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)ms_registerHandlers
{
    NSMutableDictionary *dic = objc_getAssociatedObject(self, _cmd);
    if (dic == nil) {
        dic = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, _cmd, dic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dic;
}

- (NSMutableDictionary *)ms_jsCallbacks
{
    NSMutableDictionary *dic = objc_getAssociatedObject(self, _cmd);
    if (dic == nil) {
        dic = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, _cmd, dic, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dic;
}

@end
