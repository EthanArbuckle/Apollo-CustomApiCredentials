#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "RedditAPICredentialViewController.h"

static NSString * const kImgurClientID = @"IMGUR_CLIENT_ID_GOES_HERE";
static NSString * const kImgurRapidAPIKey = @"RAPID_API_KEY_GOES_HERE";


__attribute__ ((constructor)) static void init(void) {
	
	if (![[NSUserDefaults standardUserDefaults] valueForKey:@"ApolloRedditAPIClientID"]) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

			UIWindow *mainWindow = ((UIWindowScene *)UIApplication.sharedApplication.connectedScenes.anyObject).windows.firstObject;

			UIWindow *window = [[UIWindow alloc] initWithFrame:mainWindow.frame];
			[window makeKeyAndVisible];
			[mainWindow addSubview:window];
			
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[UIViewController alloc] init]];
			[window addSubview:navController.view];
			
			RedditAPICredentialViewController *viewController = [[RedditAPICredentialViewController alloc] init];
	       	// viewController.modalPresentationStyle = UIModalPresentationFullScreen;
			[navController presentViewController:viewController animated:YES completion:nil];
		});
	}

	Class _RDKOAuthCredential = objc_getClass("RDKOAuthCredential");
	if (_RDKOAuthCredential) {

		Method clientIdMethod = class_getInstanceMethod(_RDKOAuthCredential, sel_registerName("clientIdentifier"));
		IMP replacementImp = imp_implementationWithBlock(^NSString *(id _self) {
			return [[NSUserDefaults standardUserDefaults] valueForKey:@"ApolloRedditAPIClientID"];
		});
		method_setImplementation(clientIdMethod, replacementImp);
	}

	Class _NSURLSessionConfiguration = objc_getClass("NSURLSessionConfiguration");
	Method setHeadersMethod = class_getInstanceMethod(_NSURLSessionConfiguration, sel_registerName("setHTTPAdditionalHeaders:"));
	IMP originalSetHeadersImp = method_getImplementation(setHeadersMethod);
	IMP replacementSetHeadersImp = imp_implementationWithBlock(^void (id _self, NSDictionary *headers) {
		
		if (headers && [headers valueForKey:@"Authorization"]) {
			if ([[headers valueForKey:@"Authorization"] isEqualToString:@"Client-ID 0b596f9aaeef0f4"]) {
				NSMutableDictionary *newHeaders = [headers mutableCopy];
				newHeaders[@"Authorization"] = [NSString stringWithFormat:@"Client-ID %@", kImgurClientID];
				headers = newHeaders;
			}
		}
		
		if (headers && [headers valueForKey:@"X-RapidAPI-Key"]) {
			NSMutableDictionary *newHeaders = [headers mutableCopy];
			newHeaders[@"X-RapidAPI-Key"] = kImgurRapidAPIKey;
			headers = newHeaders;
		}

		((void (*)(id, SEL, id))originalSetHeadersImp)(_self, NSSelectorFromString(@"setHTTPAdditionalHeaders:"), headers);
	});

	method_setImplementation(setHeadersMethod, replacementSetHeadersImp);
}
