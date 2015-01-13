//
//  ViewController.h
//  tonafm-led
//
//  Created by gao chao on 15/1/9.
//  Copyright (c) 2015年 sensory media. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>

@interface PlayerViewController : UIViewController<SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate,UITableViewDataSource,UITableViewDelegate>

-(void)handleNewSession:(SPTSession *)session;

@end
