#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@interface RedditAPICredentialViewController : UIViewController <WKNavigationDelegate>

@property (nonatomic, retain) UILabel *statusLabel;
@property (nonatomic, retain) WKWebView *webView;
@property (nonatomic, retain) NSString *lastLoadedURL;

@end

