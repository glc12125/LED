//
//  TrackTableViewCell.m
//  tonafm-led
//
//  Created by gao chao on 15/1/10.
//  Copyright (c) 2015年 sensory media. All rights reserved.
//

#import "TrackTableViewCell.h"

@interface TrackTableViewCell ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UIImageView *trackImageView;
@property (weak, nonatomic) IBOutlet UILabel *trackTitleLabel;
@property (nonatomic, strong) SPTPlaylistTrack *track;
@end

@implementation TrackTableViewCell

- (void)awakeFromNib
{
    // Initialization code
    [self setup];
}

-(void)setup
{
    [self.contentView setBackgroundColor:[UIColor clearColor]];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    //圆角矩形
//    [UtilityAPI setViewToRound:self.unreadCountTextField withBorderColor:nil andBorderWidth:0.0];
    //    [UtilityAPI setTextFieldToRoundCorners:self.unreadCountTextField withRadius:2.0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setContent:(SPTPlaylistTrack *)track
{
    self.track = track;

    self.trackTitleLabel.text = track.name;

    [self.spinner startAnimating];
    // Pop over to a background queue to load the image over the network.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                       NSError *error = nil;
                       UIImage *image = nil;
                       NSData *imageData = [NSData dataWithContentsOfURL:track.album.smallestCover.imageURL options:0 error:&error];

                       if(imageData != nil)
                       {
                           image = [UIImage imageWithData:imageData];
                       }

                       // …and back to the main queue to display the image.
                       dispatch_async(dispatch_get_main_queue(), ^{
                                          [self.spinner stopAnimating];
                                          self.trackImageView.image = image;
                                          if(image == nil)
                                          {
                                              NSLog(@"Couldn't load cover image with error: %@", error);
                                          }
                                      });
                   });

    [self setNeedsLayout];
}

@end
