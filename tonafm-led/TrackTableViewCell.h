//
//  TrackTableViewCell.h
//  tonafm-led
//
//  Created by gao chao on 15/1/10.
//  Copyright (c) 2015年 sensory media. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Spotify/Spotify.h>

@protocol TrackTableViewCellDelegate <NSObject>
@end

@interface TrackTableViewCell : UITableViewCell
@property (nonatomic, weak) id <TrackTableViewCellDelegate> delegate;

-(void)setContent:(SPTPlaylistTrack *)track;
@end
