//
//  ViewController.m
//  tonafm-led
//
//  Created by gao chao on 15/1/9.
//  Copyright (c) 2015年 sensory media. All rights reserved.
//

#import "PlayerViewController.h"
#import "Config.h"
#import "TrackTableViewCell.h"
#import "UtilityAPI.h"

@interface PlayerViewController () <SPTAudioStreamingDelegate, TrackTableViewCellDelegate, NSURLConnectionDelegate, SPTCoreAudioControllerDelegate>

@property (weak, nonatomic) IBOutlet UINavigationItem *trackTitleItem;
@property (weak, nonatomic) IBOutlet UIImageView *coverView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (nonatomic, strong) SPTSession *session;
@property (nonatomic, strong) SPTCoreAudioController *audioController;
@property (nonatomic, strong) SPTAudioStreamingController *player;
@property (nonatomic, strong) SPTPlaylistSnapshot *firstPlayList;

@property (nonatomic, strong) NSMutableData *responseData;

@property (nonatomic, strong) SPTPlaylistTrack *currentTrack;

@property (weak, nonatomic) IBOutlet UITableView *tracksTableView;

@property (nonatomic) int count;
@end

@implementation PlayerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.count = 0;
    self.tracksTableView.dataSource = self;
    self.tracksTableView.delegate = self;

    //注册nib
    [self.tracksTableView registerNib:[UINib nibWithNibName:@"TrackTableViewCell"
                                       bundle:[NSBundle mainBundle]]
     forCellReuseIdentifier:@"TrackTableViewCell"];

    self.responseData = [NSMutableData data];
}

#pragma mark - Actions

- (IBAction)rewind:(id)sender
{
    [self.player skipPrevious:nil];
}

- (IBAction)playPause:(id)sender
{
    [self.player setIsPlaying:!self.player.isPlaying callback:nil];
}

- (IBAction)fastForward:(id)sender
{
    [self.player skipNext:nil];
}

#pragma mark - Logic

- (void)updateUI
{
    if(self.player.currentTrackMetadata == nil)
    {
        self.trackTitleItem.title = @"Nothing Playing";
    }
    else
    {
        self.trackTitleItem.title = [self.player.currentTrackMetadata valueForKey:SPTAudioStreamingMetadataTrackName];
    }
    [self updateCoverArt];
}

- (void)updateCoverArt
{
    if(self.player.currentTrackMetadata == nil)
    {
        self.coverView.image = nil;
        return;
    }

    [self.spinner startAnimating];

    [SPTAlbum albumWithURI:[NSURL URLWithString:[self.player.currentTrackMetadata valueForKey:SPTAudioStreamingMetadataAlbumURI]]
     session:self.session
     callback: ^(NSError *error, SPTAlbum *album) {
         NSURL *imageURL = album.largestCover.imageURL;
         if(imageURL == nil)
         {
             NSLog(@"Album %@ doesn't have any images!", album);
             self.coverView.image = nil;
             return;
         }

         // Pop over to a background queue to load the image over the network.
         dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            NSError *error = nil;
                            UIImage *image = nil;
                            NSData *imageData = [NSData dataWithContentsOfURL:imageURL options:0 error:&error];

                            if(imageData != nil)
                            {
                                image = [UIImage imageWithData:imageData];
                            }

                            // …and back to the main queue to display the image.
                            dispatch_async(dispatch_get_main_queue(), ^{
                                               [self.spinner stopAnimating];
                                               self.coverView.image = image;
                                               if(image == nil)
                                               {
                                                   NSLog(@"Couldn't load cover image with error: %@", error);
                                               }
                                           });
                        });
     }];
}

- (void)handleNewSession:(SPTSession *)session
{
    self.session = session;

    if(self.player == nil)
    {
//        self.player = [[SPTAudioStreamingController alloc] initWithClientId:kClientId];
        self.player = [[SPTAudioStreamingController alloc] initWithClientId:kClientId audioController:self.audioController];
        self.player.playbackDelegate = self;
//        self.audioController.delegate = self;
    }

    [self.player loginWithSession:session callback: ^(NSError *error) {
         if(error != nil)
         {
             NSLog(@"*** Enabling playback got error: %@", error);
             return;
         }

//         [SPTRequest requestItemAtURI:[NSURL URLWithString:@"spotify:album:4L1HDyfdGIkACuygktO7T7"]
//          withSession:session
//          callback:^(NSError *error, id object) {
//              if(error != nil)
//              {
//                  NSLog(@"*** Album lookup got error %@", error);
//                  return;
//              }
//
//         [self.player playTrackProvider:(id <SPTTrackProvider>) object callback:nil];
//          }];
         ///////////////////////
         [SPTRequest playlistsForUserInSession:session callback: ^(NSError *error, id object) {
              SPTPlaylistList *playlist = (SPTPlaylistList *)object;
              SPTPartialPlaylist *partialPlaylist = [[playlist items] firstObject];
              [SPTRequest requestItemFromPartialObject:partialPlaylist withSession:session callback: ^(NSError *error, id object) {
                   SPTPlaylistSnapshot *fullPlaylist = (SPTPlaylistSnapshot *)object;
                   self.firstPlayList = fullPlaylist;
                   [self.player playTrackProvider:(id < SPTTrackProvider >)self.firstPlayList callback:nil];
                   [self.tracksTableView reloadData];
               }];
          }];
     }];
}

#pragma mark - Track Player Delegates
- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didReceiveMessage:(NSString *)message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Message from Spotify"
                              message:message
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
    [alertView show];
}

- (void)audioStreaming:(SPTAudioStreamingController *)audioStreaming didChangeToTrack:(NSDictionary *)trackMetadata
{
    [self updateUI];
}

#pragma mark - Table View
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.firstPlayList.trackCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TrackTableViewCell";
    TrackTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if(cell == nil)
    {
        cell = [[TrackTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    [self configureCell:cell forTableview:tableView atIndexPath:indexPath];

    return cell;
}

- (void)configureCell:(TrackTableViewCell *)cell forTableview:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath
{
    cell.delegate = self;
    SPTPlaylistTrack *track = [self.firstPlayList.tracksForPlayback objectAtIndex:indexPath.row];
    [cell setContent:track];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Animate the deselection
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    // get track
    SPTPlaylistTrack *track = [self.firstPlayList.tracksForPlayback objectAtIndex:indexPath.row];
    self.currentTrack = track;

    //get profile data
    NSURLRequest *request = [NSURLRequest requestWithURL:
                             [UtilityAPI getEchoNestUrlForTrackProfileFromTrack:track]];
    [[NSURLConnection alloc] initWithRequest:request delegate:self];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"didReceiveResponse");
    [self.responseData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError");
    NSLog([NSString stringWithFormat:@"Connection failed: %@", [error description]]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"connectionDidFinishLoading");
    NSLog(@"Succeeded! Received %lu bytes of data", (unsigned long)[self.responseData length]);

    // convert to JSON
    NSError *myError = nil;
    NSDictionary *res = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingMutableLeaves error:&myError];

    NSString *analysis_url_str = [[[[res objectForKey:@"response"] objectForKey:@"track"] objectForKey:@"audio_summary"] objectForKey:@"analysis_url"];

    if([UtilityAPI isAnEmptyString:analysis_url_str])
    {
        // this is analysis data

        [self.player playTrackProvider:(id < SPTTrackProvider >)self.currentTrack callback:nil];
        [self.player addObserver:self forKeyPath:@"currentPlaybackPosition" options:NSKeyValueChangeOldKey context:nil];
//        NSLog(@"data:%@", res);
//        [NSTimer scheduledTimerWithTimeInterval:0.5
//         target:self
//         selector:@selector(currentPlaybackPosition)
//         userInfo:nil
//         repeats:YES];
    }
    else
    {
        // need to get analysis data
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:analysis_url_str]];
        [[NSURLConnection alloc] initWithRequest:request delegate:self];
    }
}

#pragma mark - xxx
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"keyPath:%@ change:%@",keyPath,change);
    NSLog(@"position:%f",self.player.currentPlaybackPosition);
}

-(void)currentPlaybackPosition
{
    NSLog(@"position:%f",self.player.currentPlaybackPosition);
    NSDate *mydate = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"hhmmss"];
    NSString *formattedDateString = [dateFormatter stringFromDate:mydate];
    NSLog(@"date str:%@",formattedDateString);
    switch(self.count)
    {
    case 0:
        [self.view setBackgroundColor: [UIColor redColor]];
        break;
    case 1:
        [self.view setBackgroundColor: [UIColor grayColor]];
        break;
    case 2:
        [self.view setBackgroundColor: [UIColor greenColor]];
        break;

    case 3:
        [self.view setBackgroundColor: [UIColor yellowColor]];
        break;

    default:
        [self.view setBackgroundColor: [UIColor blueColor]];
        break;
    }
//    [self.view setBackgroundColor: [self colorWithHexString:formattedDateString]];

    self.count += 1;
}

-(UIColor*)colorWithHexString:(NSString*)hex
{
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];

    // String should be 6 or 8 characters
    if([cString length] < 6)
    {
        return [UIColor grayColor];
    }

    // strip 0X if it appears
    if([cString hasPrefix:@"0X"])
    {
        cString = [cString substringFromIndex:2];
    }

    if([cString length] != 6)
    {
        return [UIColor grayColor];
    }

    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    NSString *rString = [cString substringWithRange:range];

    range.location = 2;
    NSString *gString = [cString substringWithRange:range];

    range.location = 4;
    NSString *bString = [cString substringWithRange:range];

    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];

    return [UIColor colorWithRed:((float) r / 255.0f)
            green:((float) g / 255.0f)
            blue:((float) b / 255.0f)
            alpha:1.0f];
}

#pragma mark - SPTCoreAudioController
- (SPTCoreAudioController *)audioController
{
    if(!_audioController)
    {
        _audioController = [SPTCoreAudioController new];
        _audioController.delegate = self; //not working here
    }

    return _audioController;
}

-(void)coreAudioController:(SPTCoreAudioController *)controller didOutputAudioOfDuration:(NSTimeInterval)audioDuration
{
    NSLog(@"duration:%f",audioDuration);
}

@end
