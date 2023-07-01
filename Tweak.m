#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString * const kRedditClientID = @"CLIENT_ID_GOES_HERE";
static NSString * const kImgurClientID = @"IMGUR_CLIENT_ID_GOES_HERE";
static NSString * const kImgurRapidAPIKey = @"RAPID_API_KEY_GOES_HERE";


__attribute__ ((constructor)) static void init(void) {
	
	Class _RDKOAuthCredential = objc_getClass("RDKOAuthCredential");
	if (_RDKOAuthCredential) {

		Method clientIdMethod = class_getInstanceMethod(_RDKOAuthCredential, sel_registerName("clientIdentifier"));
		IMP replacementImp = imp_implementationWithBlock(^NSString *(id _self) {
			return kRedditClientID;
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
