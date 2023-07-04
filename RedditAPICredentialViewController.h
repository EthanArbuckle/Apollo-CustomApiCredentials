#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>

#define RANDSTRING  [[NSProcessInfo processInfo] globallyUniqueString]
#define RANDINT (arc4random() % 9) + 1

@interface RedditAPICredentialViewController : UIViewController <WKNavigationDelegate>

@property (nonatomic, retain) UILabel *statusLabel;
@property (nonatomic, retain) WKWebView *webView;
@property (nonatomic, retain) NSString *lastLoadedURL;

@end

