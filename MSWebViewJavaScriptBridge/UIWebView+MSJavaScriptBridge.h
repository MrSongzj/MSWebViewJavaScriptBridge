//
//  UIWebView+MSJavaScriptBridge.h
//  Demo
//
//  Created by MrSong on 2017/4/25.
//  Copyright © 2017年 MrSong. All rights reserved.
//

/*
 OC 类型对应 JS 类型。详情可参考 JSValue 的头文件。
 
  Objective-C type  |   JavaScript type
--------------------+---------------------
        nil         |     undefined
       NSNull       |        null
      NSString      |       string
      NSNumber      |   number, boolean
    NSDictionary    |   Object object
      NSArray       |    Array object
       NSDate       |     Date object
      NSBlock (1)   |   Function object (1)
         id (2)     |   Wrapper object (2)
       Class (3)    | Constructor object (3)
 */

#import <UIKit/UIKit.h>

typedef void (^MSJSBCallback)(id responseData);
typedef void (^MSJSBHandler)(id data, MSJSBCallback callback);

@interface UIWebView (MSJavaScriptBridge)

/**
 注册方法让 JS 调用。
 如果需要回调 JS 方法，不指定 callbackName 时，callback 默认回调 JS 的 [handlerName]Callback 方法。
 */
- (void)ms_registerHandler:(NSString*)handlerName handler:(MSJSBHandler)handler;
- (void)ms_registerHandler:(NSString*)handlerName callbackName:(NSString *)callbackName handler:(MSJSBHandler)handler;


/**
 调用 JS 方法。
 如果需要回调 OC 方法，不指定 callbackName 时，JS 应该回调 [handlerName]Callback 方法。
 */
- (void)ms_callHandler:(NSString *)handlerName;
- (void)ms_callHandler:(NSString *)handlerName data:(id)data;
- (void)ms_callHandler:(NSString *)handlerName data:(id)data callback:(MSJSBCallback)callback;
- (void)ms_callHandler:(NSString *)handlerName data:(id)data callbackName:(NSString *)callbackName callback:(MSJSBCallback)callback;

/**
 移除已经注册的方法。
 */
- (void)ms_removeHandler:(NSString *)handlerName;

@end
