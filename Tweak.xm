#import <UIKit/UIKit.h>
#import "ReadItLaterLite.h"
#import "UIProgressHUD.h"
#import <UIKit/UITableViewController.h>

//extend ActionSheet.
__attribute__((visibility("hidden")))
@interface WebViewController : UIViewController <UIActionSheetDelegate,UIWebViewDelegate,ReadItLaterDelegate> {
}
- (NSURL*)currentRequestURL;
@end

__attribute__((visibility("hidden")))
@interface HBLetPopoverViewController : UIViewController <UIActionSheetDelegate,UIWebViewDelegate,ReadItLaterDelegate> {
}
- (id) targetURL;
@end

__attribute__((visibility("hidden")))
@interface HBWebViewController : UIViewController <UIActionSheetDelegate,UIWebViewDelegate,ReadItLaterDelegate> {
}
@end

NSString *globalTitle;
UIProgressHUD *progressHUD;

@interface UIViewController (HatebuPatcher) @end

@implementation UIViewController (HatebuPatcher)

- (void)readItLaterSaveFinished:(NSString *)stringResponse error:(NSString *)errorString
{
	if (progressHUD) {
		if (stringResponse != nil) {
			[progressHUD done];
			[progressHUD setText:@"Success!"];
			[self performSelector:@selector(progressHUDAffineToRemove) withObject:nil afterDelay:0.05];
		} else {
		[progressHUD setText:@"Error!"];
		[NSTimer scheduledTimerWithTimeInterval:1.0
																		 target:self
																	 selector:@selector(endTimer:)
																	 userInfo:nil
																		repeats:NO];
		}
	}
}

- (void)progressHUDAffineToRemove
{
		[UIView beginAnimations: nil context: NULL];
		[UIView setAnimationDuration: 0.3];
		[progressHUD setAlpha:0.0f];
		CGAffineTransform affine = CGAffineTransformMakeScale (1.5, 1.5);
		[progressHUD setTransform: affine];
		[UIView commitAnimations];

		[NSTimer scheduledTimerWithTimeInterval:0.3
																		 target:self
																	 selector:@selector(endTimer:)
																	 userInfo:nil
																		repeats:NO];
}

- (void)endTimer:(NSTimer*)timer
{
	[progressHUD hide];
	[progressHUD release];
	progressHUD = nil;	
}
@end

%group iPhoneHook

%hook BookmarkEntry

- (NSString *)title{
	globalTitle = %orig;
	//NSLog(@"---------title:%@", globalTitle);
	return globalTitle;
}
%end

%hook WebViewController

- (void)openButonPushed:(id)pushed
{	
	UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:nil
																											delegate:self
												 										 cancelButtonTitle:@"Cancel"
																				destructiveButtonTitle:nil
																						 otherButtonTitles:@"Safariで開く", @"Twitter for iPhone", @"Read It Later", nil]
													autorelease];
	[sheet setAlertSheetStyle:2];
	[sheet showInView:self.view];
}

-(void)actionSheet:(UIActionSheet*)sheet clickedButtonAtIndex:(int)index
{
	%orig;
	NSMutableString *string = [[NSMutableString alloc] initWithString:@"tweetie://post?message="];
	[string appendFormat:@"%@%@%@%@%@", @"%22", [globalTitle stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], @"%22", @"%20", [self currentRequestURL]];

/*----Evernote
	NSMutableString *evernoteString = [[NSMutableString alloc] initWithString:@"evernote:newnote:title="];
	[evernoteString appendFormat:@"%@&tagName=HatebuClip&sourceURL=%@", title, URL];
*/
	if (index == 1)
	{
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:string]];
	}
	else if (index == 2)
	{
		NSDictionary *prefsDict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/jp.r-plus.hatebupatcher.plist"];
		NSString *RILUser= [prefsDict objectForKey:@"RILUser"];
		NSString *RILPassword= [prefsDict objectForKey:@"RILPassword"];

		[ReadItLater save:[self currentRequestURL] title:globalTitle delegate:self username:RILUser password:RILPassword];
		
		CGFloat w = self.view.frame.size.width - 200.0f;
		CGFloat h = self.view.frame.size.height - 180.0f;
		progressHUD = [[UIProgressHUD alloc] initWithFrame:CGRectMake(w / 2, h / 2, 200, 120)];
		[progressHUD setText:@"Processing..."];
		[progressHUD showInView:self.view];
		[progressHUD setAlpha:0.0f];
		CGAffineTransform affine = CGAffineTransformMakeScale (0.3, 0.3);
		[progressHUD setTransform: affine];
		[UIView beginAnimations: nil context: NULL];
		[UIView setAnimationDuration: 0.3];
		[progressHUD setAlpha:1.0f];
		affine = CGAffineTransformMakeScale (1.0, 1.0);
		[progressHUD setTransform: affine];
		[UIView commitAnimations];
	}
	[string release];
}


%end
%end //iPhoneHook

%group iPadHook

%hook HBWebViewController

- (id)setTitle:(id)title
{
	globalTitle = title;
	return %orig;
}
%end

%hook HBLetPopoverViewController

- (void)openInSafari:(NSURL*)URL
{
	UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:nil
																											delegate:self
												 										 cancelButtonTitle:@"Cancel"
																				destructiveButtonTitle:nil
																						 otherButtonTitles:@"Safariで開く", @"Twitter for iPhone", @"Read It Later", nil]
													autorelease];
	[sheet setAlertSheetStyle:2];
	[sheet showInView:self.view];
}

%new(v@:)
-(void)actionSheet:(UIActionSheet*)sheet clickedButtonAtIndex:(int)index
{
	NSMutableString *string = [[NSMutableString alloc] initWithString:@"tweetie://post?message="];
	[string appendFormat:@"%@%@%@%@%@", @"%22", [globalTitle stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], @"%22", @"%20", [self targetURL]];
/*----Evernote
	NSMutableString *evernoteString = [[NSMutableString alloc] initWithString:@"evernote:newnote:title="];
	[evernoteString appendFormat:@"%@&tagName=HatebuClip&sourceURL=%@", title, URL];
*/
	if (index == 0)
	{
		[[UIApplication sharedApplication] openURL:[self targetURL]];		
	}	
	else if (index == 1)
	{
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:string]];
	}
	else if (index == 2)
	{
		NSDictionary *prefsDict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/jp.r-plus.hatebupatcher.plist"];
		NSString *RILUser= [prefsDict objectForKey:@"RILUser"];
		NSString *RILPassword= [prefsDict objectForKey:@"RILPassword"];

		[ReadItLater save:[self targetURL] title:globalTitle delegate:self username:RILUser password:RILPassword];
		
		CGFloat w = self.view.frame.size.width - 200.0f;
		CGFloat h = self.view.frame.size.height - 180.0f;
		progressHUD = [[UIProgressHUD alloc] initWithFrame:CGRectMake(w / 2, h / 2, 200, 120)];
		[progressHUD setText:@"Processing..."];
		[progressHUD showInView:self.view];
		[progressHUD setAlpha:0.0f];
		CGAffineTransform affine = CGAffineTransformMakeScale (0.3, 0.3);
		[progressHUD setTransform: affine];
		[UIView beginAnimations: nil context: NULL];
		[UIView setAnimationDuration: 0.3];
		[progressHUD setAlpha:1.0f];
		affine = CGAffineTransformMakeScale (1.0, 1.0);
		[progressHUD setTransform: affine];
		[UIView commitAnimations];
	}
	[string release];
}

%end
%end //iPadHook

//  ReadItLaterLite.m
//  ReadItLaterAPI
//  Version 1.0
//
//  Created by Nathan Weiner on 5/9/09.
//  Copyright 2009 Idea Shower. All rights reserved.
//


@implementation ReadItLater

static NSString *apikey = @"";			//Enter your apikey here : get one at http://readitlaterlist.com/api/ 
static NSString *nameOfYourApp = @"HatebuPatcher";		//Enter the name of your application here (optional - for user-agent string)
		



@synthesize delegate, method, apiResponse, requestData, stringResponse;

/* -----------------
 
	SEE THE ReadItLaterLite.h FILE FOR COMMENTS/DOCUMENTATION
	ADDITIONAL DOCUMENTATION, SCREENSHOTS, EXAMPLES ARE AVAILABLE AT:
	http://readitlaterlist.com/api_iphone/
 
-------------------- */

- (void)dealloc {
	[method release];
	[apiResponse release];
	[requestData release];
	[stringResponse release];
    [super dealloc];
}


/* ----------------------------------- */

// Saving Methods, see ReadItLaterLite.h for comments/documentation

+(void)save:(NSURL *)url title:(NSString *)title delegate:(id)delegate {
	
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	[ReadItLater save:url title:title delegate:delegate username:[prefs objectForKey:@"ReadItLaterUsername"] password:[prefs objectForKey:@"ReadItLaterPassword"]];

	
}
+(void)save:(NSURL *)url title:(NSString *)title delegate:(id)delegate username:(NSString *)username password:(NSString *)password {
	
	ReadItLater *readItLater = [[ReadItLater alloc] init];
	readItLater.delegate = delegate;
	[readItLater sendRequest:@"add" username:username password:password params:[NSString stringWithFormat:@"url=%@&title=%@", [ReadItLater encode:[url.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]], [ReadItLater encode:[title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] ]];
	
	
}



/* ----------------------------------- */



// --- LOGIN/SETUP METHODS --- //
// see ReadItLaterLite.h for comments/documentation

+(void)authWithUsername:(NSString *)username password:(NSString *)password delegate:(id)delegate {
	
	ReadItLater *readItLater = [[ReadItLater alloc] init];
	readItLater.delegate = delegate;
	[readItLater sendRequest:@"auth" username:username password:password params:nil];
	
}

+(void)signupWithUsername:(NSString *)username password:(NSString *)password delegate:(id)delegate {
	
	ReadItLater *readItLater = [[ReadItLater alloc] init];
	readItLater.delegate = delegate;
	[readItLater sendRequest:@"signup" username:username password:password params:nil];
	
}



@end




/* ----- The following methods are used by the simple/auto methods listed above, you should not implement these --- */


@implementation ReadItLater (Private)

	
// -- //
	

-(void)sendRequest:(NSString *)newMethod username:(NSString *)username password:(NSString *)password params:(NSString *)additionalParams {
	
	self.method = newMethod;
	requestData = [[NSMutableData alloc] initWithLength:0];
	
	// Create Request
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://readitlaterlist.com/v2/%@", method]];
	NSMutableURLRequest *request =  [ [NSMutableURLRequest alloc] initWithURL:url
												  cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
											  timeoutInterval:90];
	

	// Setup Request Data/Params
	NSMutableString *params = [NSMutableString stringWithFormat:@"apikey=%@&username=%@&password=%@", apikey, [ReadItLater encode:username], [ReadItLater encode:password]];
	if (additionalParams != nil) {
		[params appendFormat:@"&%@", additionalParams];
	}
	NSData *paramsData = [ NSData dataWithBytes:[params UTF8String] length:[params length] ];
	
	// Fill Request
	[request setHTTPMethod:@"POST"];
	[request setValue:nameOfYourApp!=nil?nameOfYourApp:@"RIL API iPhone Library v2.0" forHTTPHeaderField:@"User-Agent"];
	[request setHTTPBody:paramsData];
	

	// Start Connection
	[[NSURLConnection alloc]
	 initWithRequest:request
	 delegate:self
	 startImmediately:YES];
	
	[request release];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	
	self.apiResponse = [[response allHeaderFields] mutableCopy];
	[apiResponse setObject:[NSString stringWithFormat:@"%i", [response statusCode]] forKey:@"statusCode"];
	[apiResponse release];
	
	[requestData setLength:0];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[requestData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

	self.stringResponse = [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding];
	[self.stringResponse release];
	
	[self finishConnection];
	[connection release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	self.apiResponse = [NSDictionary dictionaryWithObjectsAndKeys:@"X-Error",[error localizedDescription],nil];
	[self finishConnection];
	[connection release];	
}

-(void)finishConnection {
	// Determine Result
	NSString *statusCode = [apiResponse objectForKey:@"statusCode"];
	int success = (statusCode != nil && [statusCode isEqualToString:@"200"]);
	NSString *error = !success ? [apiResponse objectForKey:@"X-Error"] : nil;
	
	
	// Send to delegate
	/*
	SEL selector;
	selector = nil;
	
	if ([method isEqualToString:@"auth"]) 
	{
		selector = @selector(readItLaterLoginFinished:error:);
	}
	else if ([method isEqualToString:@"signup"]) 
	{
		selector = @selector(readItLaterSignupFinished:error:);
	}
	else if ([method isEqualToString:@"add"]) 
	{
		selector = @selector(readItLaterSaveFinished:error:);
	}
	*/
	SEL selector = @selector(readItLaterSaveFinished:error:);
	
	if ([delegate respondsToSelector:selector]) {
		[delegate performSelector:selector withObject:stringResponse withObject:error];
	}
	
	[self done];
	
}

-(void)done {
	[self release];
}


/* --- */

+(NSString *)encode:(NSString *)string {
	CFStringRef encoded = CFURLCreateStringByAddingPercentEscapes(
															  kCFAllocatorDefault, 
															  (CFStringRef) string, 
															  nil, 
															  (CFStringRef)@"&#38;+", 
															  kCFStringEncodingUTF8);  
	return [((NSString*) encoded) autorelease];
}

@end

__attribute__((constructor)) static void init()
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"jp.ne.hatena"]){
		%init(iPhoneHook);
	}	else {
		%init(iPadHook);
	}
		
  [pool release];
}
