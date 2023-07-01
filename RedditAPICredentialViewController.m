#import "RedditAPICredentialViewController.h"

@implementation RedditAPICredentialViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor lightGrayColor];

    // If an account is already signed in to reddit, attempting to navigate to the developer apps page will redirect to the mobile homepage.
    // Work around this by signing out of reddit
    [[WKWebsiteDataStore defaultDataStore] fetchDataRecordsOfTypes:[WKWebsiteDataStore allWebsiteDataTypes] completionHandler:^(NSArray<WKWebsiteDataRecord *> * __nonnull records) {
        for (WKWebsiteDataRecord *record in records) {
            if ([record.displayName containsString:@"reddit"]) {
                [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:record.dataTypes forDataRecords:@[record] completionHandler:^void {}];
            }
        }
    }];

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, self.view.frame.size.width, 25)];
    self.statusLabel.text = @"Log in and create API credentials";
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:self.statusLabel];

    CGRect webviewFrame = self.view.frame;
    webviewFrame.size.height -= 80;
    webviewFrame.origin.y = 80;

    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKWebView *webView = [[WKWebView alloc] initWithFrame:webviewFrame configuration:config];
    webView.navigationDelegate = self;
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.reddit.com/prefs/apps"]]];
    [self.view addSubview:webView];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {

    if (![webView.URL.absoluteString containsString:@"https://www.reddit.com/prefs/apps"]) {
        return;
    }

    // Inspect contents of the developer apps page -- looking for a client id
    [self pageDidUpdate:webView];
}

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {

    // User clicked the "create app" button
    if ([navigationAction.request.URL.absoluteString isEqualToString:@"navigation://create-app"]) {

        // Cancel the dummy navigation
        decisionHandler(WKNavigationActionPolicyCancel);

        // Wait a bit for the request to complete and then check the page contents for a client id
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self pageDidUpdate:webView];
        });

        return;
    }

    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)pageDidUpdate:(WKWebView *)webView {

    // Grab the page's source
    [webView evaluateJavaScript:@"document.body.innerHTML" completionHandler:^(id _Nullable value, NSError * _Nullable error) {
        if (error) {
            NSLog(@"eval js error: %@", error);
            return;
        }

        NSString *pageSource = (NSString *)value;

        // Look for existing app with the correct redirect_uri
        NSString *redirectURI = @"apollo://reddit-oauth";
        if ([pageSource containsString:redirectURI] && [pageSource containsString:@"installed app"]) {

            // Found an app. Trim down to the client_id
            NSString *trimmedPageSource = [pageSource substringFromIndex:[pageSource rangeOfString:redirectURI].location];
            NSRange clientIDRange = [trimmedPageSource rangeOfString:@"name=\"client_id\" value=\""];
            trimmedPageSource = [trimmedPageSource substringFromIndex:clientIDRange.location + clientIDRange.length];

            NSString *clientID = [trimmedPageSource substringToIndex:[trimmedPageSource rangeOfString:@"\""].location];
            [[NSUserDefaults standardUserDefaults] setValue:clientID forKey:@"ApolloRedditAPIClientID"];
            self.statusLabel.text = [NSString stringWithFormat:@"client id: %@", clientID];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

                if (self.presentingViewController.view.superview) {
                    UIWindow *containingWindow = (UIWindow *)self.presentingViewController.view.superview;
                    [self dismissViewControllerAnimated:YES completion:nil];
                    [containingWindow setHidden:YES];
                }
            });
    
        }
        else {

            // An app needs to be created

            // Detect when the (last step) "create app" button is clicked in the webview.
            // Accomplished by adding another click listener to the element that navigates to a fake url. This navigation is caught (and cancelled) by a WKWebView delegate method
            [webView evaluateJavaScript:@"function notifyAppButtonClicked() { window.location.href = \"navigation://create-app\"; } Array.from(document.getElementsByTagName('BUTTON')).slice(-1)[0].addEventListener('click', notifyAppButtonClicked, false);" completionHandler:nil];

            // Open the App Creation form
            [webView evaluateJavaScript:@"document.getElementById('create-app-button').click();" completionHandler:^(id _Nullable arg1, NSError * _Nullable error) {

                // Populate all the fields
                NSString *prefillFormJS = [NSString stringWithFormat:@"document.getElementById('app_type_installed').checked = true; \
                                            Array.from(document.getElementsByName('description')).slice(-1)[0].value = \"i'm a fun reddit app\"; \
                                            Array.from(document.getElementsByName('about_url')).slice(-1)[0].value = \"https://google.com\"; \
                                            document.getElementById('redirect_uri').value = \"apollo://reddit-oauth\"; \
                                            Array.from(document.getElementsByName('name')).slice(-1)[0].value = \"Some app %@\";", [[NSProcessInfo processInfo] globallyUniqueString]];
                [webView evaluateJavaScript:prefillFormJS completionHandler:nil];
            }];

            self.statusLabel.text = @"select \"create app\"";
        }
    }];
}

@end
