//
//  ViewController.m
//  Demo
//
//  Created by MrSong on 2017/4/25.
//  Copyright © 2017年 MrSong. All rights reserved.
//

#import "ViewController.h"
#import "UIWebView+MSJavaScriptBridge.h"

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UIWebView *wv;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // JS 渲染过程中调用 OC 方法
    [self.wv ms_registerHandler:@"log" handler:^(id data, MSJSBCallback callback) {
        NSLog(@"网页加载过程中，调用 OC 方法");
    }];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"html"];
    [self.wv loadRequest:[NSURLRequest requestWithURL:url]];
    
    // 默认获取 JS 那边的 takePhotoCallback 回调
    [self.wv ms_registerHandler:@"takePhoto" handler:^(NSString *data, MSJSBCallback callback) {
        NSLog(@"take photo done");
        callback(@"photo");
    }];
    
    // 指定获取 JS 那边的 payResult 回调
    __weak typeof(self) weakSelf = self;
    [self.wv ms_registerHandler:@"pay" callbackName:@"payResult" handler:^(NSDictionary *data, MSJSBCallback callback) {
        [weakSelf pay:data callbacck:callback];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pay:(NSDictionary *)goodsInfo callbacck:(MSJSBCallback)callback
{
    NSLog(@"goods info:%@", goodsInfo);
    UIActivityIndicatorView *indicatorV = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicatorV.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    indicatorV.center = self.view.center;
    [indicatorV startAnimating];
    [self.view addSubview:indicatorV];
    dispatch_queue_t queue = dispatch_queue_create("并发队列", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        NSLog(@"支付中...");
        sleep(2);
        dispatch_async(dispatch_get_main_queue(), ^{
            [indicatorV removeFromSuperview];
            callback(@0);
        });
    });
}

- (IBAction)callJSHandler
{
    // JS 那边默认回调 showAlertCallback
    [self.wv ms_callHandler:@"showAlert" data:@"oc call js handler" callback:^(id responseData) {
        NSLog(@"%@", responseData);
    }];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"shouldStart");
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    NSLog(@"didStart");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"didFinish");
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"didFail");
}

@end
