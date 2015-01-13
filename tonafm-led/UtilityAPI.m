//
//  UtilityAPI.m
//  myFirst
//
//  Created by gao chao on 13-8-31.
//  Copyright (c) 2013年 me. All rights reserved.
//

#import "UtilityAPI.h"
#import "AppDelegate.h"

@interface UtilityAPI ()
@end

@implementation UtilityAPI

/**
 * Singleton methods
 */

+ (UtilityAPI *)sharedInstance
{
    static UtilityAPI *sharedInstance = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
                      sharedInstance = [[self alloc] init
                                       ];
                  });

    return sharedInstance;
}

+ (Boolean)isAnEmptyString:(NSString *)string
{
    if((string == nil) || [string isEqualToString:@""])
    {
        return true;
    }

    return false;
}

+(NSURL *)getEchoNestUrlForTrackProfileFromTrack:(SPTPlaylistTrack *)track
{
    NSString *urlStr = [NSString stringWithFormat:@"http://developer.echonest.com/api/v4/track/profile?api_key=FN4BJ47AOVKURTC84&format=json&id=spotify:track:%@&bucket=audio_summary",track.identifier];
    return [NSURL URLWithString:urlStr];
}

@end
