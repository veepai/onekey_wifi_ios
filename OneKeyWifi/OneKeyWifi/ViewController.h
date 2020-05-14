

#import <UIKit/UIKit.h>

#import <UIKit/UIKit.h>
#import "voiceEncoder.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController : UIViewController{
    
    UITextField *MyWifi;
    UITextField *MyPassword;
    UIButton *Sendbtn;
    UIButton *Cancelbtn;
    UIButton *Sendnewbtn;
    UIButton *Cancenewlbtn;
    int *freq;
    
    UITextView *tiptv;
    
    NSThread *_voiceThread;// 播放声波的子线程
    NSTimer *_voiceTimesTimer;//播放timer 用来循环播放
    char *_mac;//用来播放的数组
    NSInteger _times;
    
    NSString *MyWiFiSSID;
    NSString *MyWiFiMac;
    NSString *MyWiFiPwd;
    NSString *allmac;
    
    VoiceEncoder *play;
    
      unsigned int ip;
    
    
}


@end

