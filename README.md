# MSWebViewJavaScriptBridge
对 UIWebView 的接口进行扩展，让 UIWebView 和 JavaScript 可以方便地进行交互。类似 http 请求的交互方式。

与著名的 [WebViewJavaScript](https://github.com/marcuswestin/WebViewJavascriptBridge) 相比：

* 优点：
	* 对 JS 代码没有任何要求，可以方便的适配 iOS 和 Android
	* 是 UIWebView 的分类，而且对 UIWebView 的其他功能没有任何侵入，所以使用起来更加简单
* 缺点：
	* 需要指定回调方法的名称
	* 目前只支持 UIWebView

填了几个坑：

* 在主队列中调用 JS 的方法弹窗会出现无响应的问题
* 在 block 中使用 JSContext 导致循环引用的问题
* 在网页没有加载完成之前 JS 调用 OC 方法的问题
* 网页切换之后 JSContext 变化需要重新注册方法的问题

## 系统要求

* `iOS7` 及以上。
* Automatic Reference Counting(ARC)

## 安装

#### CocoaPods
1. 在 Podfile 中添加 `pod 'MSWebViewJavaScriptBridge'`。
2. 执行 `pod install` 或 `pod update`。
3. 导入头文件：`#import <UIWebView+MSJavaScriptBridge.h>`。

#### 手动安装
1. 下载 MSWebViewJavaScriptBridge 项目。
2. 将 `MSWebViewJavaScriptBridge ` 文件夹中的源文件拽入项目中。
3. 导入头文件：`#import "UIWebView+MSJavaScriptBridge.h"`。

## 使用

#### JS 调用 OC 方法

```
// 默认回调 JS 那边的 payCallback 方法
[webView ms_registerHandler:@"pay" handler:^(NSString *data, MSJSBCallback callback) {
    callback(data);
}];
    
// 指定回调 JS 那边 payResult 方法
[webView ms_registerHandler:@"pay" callbackName:@"payResult" handler:^(NSDictionary *data, MSJSBCallback callback) {
    callback(data);
}];
```

#### OC 调用 JS 的方法

```
// 调用 JS 那边的 jsHandler 方法
[webView ms_callHandler:@"jsHanlder"];

// 调用 JS 那边的 jsHandler 方法，需要传递参数
[webView ms_callHandler:@"jsHanlder" data:data];

// 调用 JS 那边的 jsHandler 方法，JS 默认回调 jsHandlerCallback 方法
[webView ms_callHandler:@"jsHanlder" data:nil callback:^(id responseData) {
    NSLog(@"%@", responseData);
}];

// 调用 JS 那边的 jsHandler 方法，JS 指定回调 xxxx 方法
[webView ms_callHandler:@"jsHanlder" data:nil callbackName:@"xxxx" callback:^(id responseData) {
    NSLog(@"%@", responseData);
}];
```

## 许可证

MSWebViewJavaScriptBridge 使用 MIT 许可证，详情见 LICENSE 文件。

## 期待

如果在使用过程中遇到 BUG 或者对项目有任何的想法，希望你能 issues 我，谢谢！