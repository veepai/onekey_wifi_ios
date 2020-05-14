//
//  VSSoundWaveSender.m
//  TestVoice
//
//  Created by vstarcam on 2020/2/24.
//  Copyright © 2020 godliu. All rights reserved.
//

#import "VSSoundWaveSender.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>



@interface VSSoundWaveSender ()
@property (nonatomic, strong) MPVolumeView * volumeView;

@property (nonatomic, strong) dispatch_source_t soundTimer;

@end


@implementation VSSoundWaveSender
{
    VoicePlayer2 *player;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        AVAudioSession *mySession = [AVAudioSession sharedInstance];
        //[mySession setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        [mySession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
        
        [self initPlayer];
    }
    return self;
}

int freqs1[] = {15000,15200,15400,15600,15800,16000,16200,16400,16600,16800,17000,17200,17400,17600,17800,18000,18200,18400,18600};

- (void)initPlayer
{
    
    
//    int freqs[] = {15000,15200,15400,15600,15800,16000,16200,16400,16600,16800,17000,17200,17400,17600,17800,18000,18200,18400,18600};
    
    int base = 6500;
    for (int i = 0; i < sizeof(freqs1)/sizeof(int); i ++) {
        freqs1[i] = base + i *150;
    }
    
    player=[[VoicePlayer2 alloc] init];
    [player setFreqs:freqs1 freqCount:sizeof(freqs1)/sizeof(int)];
}

- (BOOL) isStopped
{
    return [player isStopped];
}

- (void)stopPlaying
{
    if (![player isStopped]) {
        [player stop];
    }
    
}


- (BOOL)playWiFiMac:(NSString *)wifiMac password:(NSString *)password userId:(NSString *)userId playCount:(NSInteger)playCount
{
    if ((![self checkStringLegal:wifiMac]) || (![self checkStringLegal:userId])) {
        NSLog(@"playWiFiMac return");
        return NO;
    }
    
    NSString * ssidString = [NSString stringWithFormat:@"%@%@",[self formatWiFiMac:wifiMac],userId];

    if ([AVAudioSession sharedInstance].outputVolume < 0.7) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setVolume:0.7];
        });
    }
    
    __weak VSSoundWaveSender * weakSelf = self;
    _soundTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(_soundTimer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC, 0.5 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(_soundTimer, ^{
#if DEBUG
#else
        if ([AVAudioSession sharedInstance].outputVolume < 0.7) {
            [self setVolume:0.72];
        }
#endif
        if (player.isStopped) {
            dispatch_cancel(weakSelf.soundTimer);
            weakSelf.soundTimer = nil;
        }

    });
    dispatch_resume(_soundTimer);
    
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [player playSSIDWiFi:ssidString pwd:password playCount:playCount muteInterval:1000];
    });
     

    //muteInterval  间隔时间
    
    return YES;

}

- (NSString *)formatWiFiMac:(NSString *)wifiMac
{
    NSMutableString * finnalMac = [[NSMutableString alloc] init];
    
    NSArray * arr = [wifiMac componentsSeparatedByString:@":"];
    for (NSString * string in arr) {
        if (string.length == 1) {
//        if ((string.length == 1) && [self isPureInt:string]) {
            [finnalMac appendFormat:@"0%@",string];
        }
        else
        {
            [finnalMac appendString:string];
        }
    }
    return finnalMac;
}

//是否数字
- (BOOL)isPureInt:(NSString *)string{
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return [scan scanInt:&val] && [scan isAtEnd];
}

- (BOOL)checkStringLegal:(NSString *)string
{
    if (!string) {
        return NO;
    }
    if (![string isKindOfClass:[NSString class]]) {
        return NO;
    }
    if ([string isEqualToString:@"(null)"]) {
        return NO;
    }
    if (string.length == 0) {
        return NO;
    }
    return YES;
}


//https://blog.csdn.net/zq282502532/article/details/78194270
- (void)setVolume:(float)value {
    
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController applicationMusicPlayer];
        if (([musicPlayer respondsToSelector:@selector(setVolume:)]) ) {
                        //消除警告
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Wdeprecated-declarations"
                        [musicPlayer setVolume:value];
            #pragma clang diagnostic pop
        }
        else
        {
            UISlider *volumeSlider = [self volumeSlider];
            if (volumeSlider) {
                self.volumeView.showsVolumeSlider = YES; // 需要设置 showsVolumeSlider 为 YES
                // 下面两句代码是关键
                [volumeSlider setValue:value animated:NO];
                [volumeSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
                [self.volumeView sizeToFit];
                
            }
        }
    
}


- (MPVolumeView *)volumeView {
    if (!_volumeView) {
        _volumeView = [[MPVolumeView alloc] init];
        _volumeView.hidden = YES;
        [[UIApplication sharedApplication].keyWindow addSubview:_volumeView];
    }
    return _volumeView;
}
/*
 * 遍历控件，拿到UISlider
 */
- (UISlider *)volumeSlider {
    UISlider* volumeSlider = nil;
    for (UIView *view in [self.volumeView subviews]) {
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            volumeSlider = (UISlider *)view;
            break;
        }
    }
    return volumeSlider;
}

- (void)dealloc
{
//    __weak VSSoundWaveSender * weakSelf = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [weakSelf.volumeView removeFromSuperview];
//        weakSelf.volumeView = nil;
//    });
    
    if (_soundTimer) {
        dispatch_cancel(_soundTimer);
        _soundTimer = nil;
    }
    if (player) {
        [player stop];
        player = nil;
    }
}

@end
