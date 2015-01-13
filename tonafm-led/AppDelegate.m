//
//  AppDelegate.m
//  tonafm-led
//
//  Created by gao chao on 15/1/9.
//  Copyright (c) 2015年 sensory media. All rights reserved.
//

#import "AppDelegate.h"
#import <Spotify/Spotify.h>
#import "Config.h"
#import "PlayerViewController.h"

@interface AppDelegate ()
@property (nonatomic, strong) SPTSession *session;
@property (nonatomic, strong) SPTAudioStreamingController *player;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    id sessionData = [[NSUserDefaults standardUserDefaults] objectForKey:kSessionUserDefaultsKey];
    SPTSession *session = sessionData ?[NSKeyedUnarchiver unarchiveObjectWithData:sessionData] : nil;

    NSString *refreshUrl = kTokenRefreshServiceURL;

    if(session)
    {
        // We have a session stored.
        if([session isValid])
        {
            // It's still valid, enable playback.
            [self enableAudioPlaybackWithSession:session];
        }
        else
        {
            // Oh noes, the token has expired.
            // If we're not using a backend token service we need to prompt the user to sign in again here.
            if((refreshUrl == nil)|| [refreshUrl isEqualToString:@""])
            {
                [self openLoginPage];
            }
            else
            {
                [self renewTokenAndEnablePlayback];
            }
        }
    }
    else
    {
        // We don't have an session, prompt the user to sign in.
        [self openLoginPage];
    }

    return YES;
}

// Handle auth callback
-(BOOL)application:(UIApplication *)application
    openURL:(NSURL *)url
    sourceApplication:(NSString *)sourceApplication
    annotation:(id)annotation
{
    SPTAuthCallback authCallback = ^(NSError *error, SPTSession *session) {
        // This is the callback that'll be triggered when auth is completed (or fails).

        if(error != nil)
        {
            NSLog(@"*** Auth error: %@", error);
            return;
        }

        NSData *sessionData = [NSKeyedArchiver archivedDataWithRootObject:session];
        [[NSUserDefaults standardUserDefaults] setObject:sessionData
         forKey:kSessionUserDefaultsKey];
        [self enableAudioPlaybackWithSession:session];
    };

    /*
       STEP 2: Handle the callback from the authentication service. -[SPAuth -canHandleURL:withDeclaredRedirectURL:]
       helps us filter out URLs that aren't authentication URLs (i.e., URLs you use elsewhere in your application).
     */

    NSString *swapUrl = kTokenSwapServiceURL;
    if([[SPTAuth defaultInstance] canHandleURL:url withDeclaredRedirectURL:[NSURL URLWithString:kCallbackURL]])
    {
        if((swapUrl == nil)|| [swapUrl isEqualToString:@""])
        {
            // If we don't have a token exchange service, we'll just handle the implicit token response directly.
            [[SPTAuth defaultInstance] handleAuthCallbackWithTriggeredAuthURL:url callback:authCallback];
        }
        else
        {
            // If we have a token exchange service, we'll call it and get the token.
            [[SPTAuth defaultInstance] handleAuthCallbackWithTriggeredAuthURL:url
             tokenSwapServiceEndpointAtURL:[NSURL URLWithString:swapUrl]
             callback:authCallback];
        }
        return YES;
    }

    return NO;
}

-(void)playUsingSession:(SPTSession *)session
{
    // Create a new player if needed
    if(self.player == nil)
    {
        self.player = [[SPTAudioStreamingController alloc] initWithClientId:kClientId];
    }

    [self.player loginWithSession:session callback:^(NSError *error) {
         if(error != nil)
         {
             NSLog(@"*** Enabling playback got error: %@", error);
             return;
         }

         [SPTRequest requestItemAtURI:[NSURL URLWithString:@"spotify:album:4L1HDyfdGIkACuygktO7T7"]
          withSession:nil
          callback:^(NSError *error, SPTAlbum *album) {
              if(error != nil)
              {
                  NSLog(@"*** Album lookup got error %@", error);
                  return;
              }
              [self.player playTrackProvider:album callback:nil];
          }];
     }];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark -- xx
-(void)enableAudioPlaybackWithSession:(SPTSession *)session
{
    NSData *sessionData = [NSKeyedArchiver archivedDataWithRootObject:session];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:sessionData forKey:kSessionUserDefaultsKey];
    [userDefaults synchronize];
    PlayerViewController *playerViewController = (PlayerViewController *)self.window.rootViewController;
    [playerViewController handleNewSession:session];
}

- (void)openLoginPage
{
    SPTAuth *auth = [SPTAuth defaultInstance];

    NSString *swapUrl = kTokenSwapServiceURL;
    NSURL *loginURL;
    if((swapUrl == nil)|| [swapUrl isEqualToString:@""])
    {
        // If we don't have a token exchange service, we need to request the token response type.
        loginURL = [auth loginURLForClientId:kClientId
                    declaredRedirectURL:[NSURL URLWithString:kCallbackURL]
                    scopes:@[SPTAuthStreamingScope]
                    withResponseType:@"token"];
    }
    else
    {
        loginURL = [auth loginURLForClientId:kClientId
                    declaredRedirectURL:[NSURL URLWithString:kCallbackURL]
                    scopes:@[SPTAuthStreamingScope]];
    }
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                       // If you open a URL during application:didFinishLaunchingWithOptions:, you
                       // seem to get into a weird state.
                       [[UIApplication sharedApplication] openURL:loginURL];
                   });
}

- (void)renewTokenAndEnablePlayback
{
    id sessionData = [[NSUserDefaults standardUserDefaults] objectForKey:kSessionUserDefaultsKey];
    SPTSession *session = sessionData ?[NSKeyedUnarchiver unarchiveObjectWithData:sessionData] : nil;
    SPTAuth *auth = [SPTAuth defaultInstance];

    [auth renewSession:session withServiceEndpointAtURL:[NSURL URLWithString:kTokenRefreshServiceURL] callback:^(NSError *error, SPTSession *session) {
         if(error)
         {
             NSLog(@"*** Error renewing session: %@", error);
             return;
         }

         [self enableAudioPlaybackWithSession:session];
     }];
}

@end
