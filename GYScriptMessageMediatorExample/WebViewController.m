//
//  WebViewController.m
//  GYScriptMessageMediatorExample
//
//  Created by Aaron on 2020/6/6.
//  Copyright © 2020 Guyalay. All rights reserved.
//

#import "WebViewController.h"

#import "UIViewController+ScriptMediator.h"

@interface WebViewController ()<WKUIDelegate, WKNavigationDelegate>

@property (nonatomic, strong) NSURL *URL;

@end

@implementation WebViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    _URL = [NSURL URLWithString:@"https://www.baidu.com"];
    return self;
}

- (instancetype)initWithURL:(NSURL *)URL
{
    self = [super init];
    if (self) {
        _URL = URL;
    }
    return self;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.backgroundColor = UIColor.whiteColor;
    self.view = view;
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
           
    WKPreferences *preference = [[WKPreferences alloc]init];
    preference.javaScriptCanOpenWindowsAutomatically = YES;
    configuration.preferences = preference;
    configuration.allowsInlineMediaPlayback = YES;

    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    [self.ScriptMediator addScriptMessageHandler:wkUController name:@"nativeLogin" completion:^(UIViewController * _Nonnull controller, WKUserContentController * _Nonnull userContentController, WKScriptMessage * _Nonnull message) {
        NSLog(@"-(void)%@(%@)\n", message.name, message.body);
    }];
    
    [self.ScriptMediator addScriptMessageHandler:wkUController name:@"nativeRegister" completion:^(UIViewController * _Nonnull controller, WKUserContentController * _Nonnull userContentController, WKScriptMessage * _Nonnull message) {
        NSLog(@"-(void)%@(%@)\n", message.name, message.body);
    }];
    configuration.userContentController = wkUController;

    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    webView.UIDelegate = self;
    webView.navigationDelegate = self;
    webView.allowsBackForwardNavigationGestures = YES;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.URL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:8];
    [webView loadRequest:request];
    [self.view addSubview:webView];
    _webView = webView;
}

#pragma mark - Override
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *test = [NSString stringWithFormat:@"window.webkit.messageHandlers.%@.postMessage(%@)", @"nativeLogin", @"{token:123456}"];
        [self.webView evaluateJavaScript:test completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            NSLog(@"error = %@", error);
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSString *test = [NSString stringWithFormat:@"window.webkit.messageHandlers.%@.postMessage(%@)", @"nativeRegister", @"{token:123456}"];
            [self.webView evaluateJavaScript:test completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                NSLog(@"error = %@", error);
            }];
        });
    });
    
}

- (void)dealloc
{
    NSLog(@"already release!\n");
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {

}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    decisionHandler(WKNavigationResponsePolicyAllow);
}

//- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
//    //用户身份信息
//    NSURLCredential * newCred = [[NSURLCredential alloc] initWithUser:@"user123" password:@"123" persistence:NSURLCredentialPersistenceNone];
//    //为 challenge 的发送方提供 credential
//    [challenge.sender useCredential:newCred forAuthenticationChallenge:challenge];
//    completionHandler(NSURLSessionAuthChallengeUseCredential,newCred);
//}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView{
    
}

#pragma mark - WKUIDelegate

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"HTML" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

@end
