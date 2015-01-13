//
//  UtilityAPI.h
//  myFirst
//
//  Created by gao chao on 13-8-31.
//  Copyright (c) 2013年 me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>

@interface UtilityAPI : NSObject

+ (UtilityAPI *)sharedInstance;

//判断一个string是否是nil或者@""
+ (Boolean)isAnEmptyString:(NSString *)string;

+(NSURL *)getEchoNestUrlForTrackProfileFromTrack:(SPTPlaylistTrack *)track;
@end
