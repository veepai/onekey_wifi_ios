//
//  ViewController.m
//  OneKeyWifi
//
//  Created by 莫晓文 on 16/7/18.
//  Copyright © 2016年 VSTARTCAM. All rights reserved.
//



#import "ViewController.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "voiceEncoder.h"
#import "SmartLink.h"
#import <Foundation/Foundation.h>
#include <ifaddrs.h>
#import "BoSmartLink.h"
#include <ifaddrs.h>
#include <arpa/inet.h>
#import <ifaddrs.h>

@interface ViewController ()
//@property(nonatomic, strong) RACCommand *startBoSmartCommand;  //博通
@property(nonatomic,strong) NSTimer *SendBoSmartLinkTimer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //1.获取当前WIFI
    [self GetCurrentWiFiSSID];
    
    //音波频率
    int i;
    freq = (int*)malloc(sizeof(int)*19);
    freq[0] = 6500;
    for (i = 0; i < 18; i++) {
        freq[i + 1] = freq[i] + 200;
    }
    
    
    [self createUI];
    
    
}

-(void)createUI
{
    
    CGRect bounds = [[UIScreen mainScreen] bounds];
    MyWifi = [[UITextField alloc]initWithFrame:CGRectMake(20, 74, bounds.size.width-30, 40)];
    MyWifi.text = MyWiFiSSID;
    MyWifi.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:MyWifi];
    
    MyPassword  = [[UITextField alloc]initWithFrame:CGRectMake(20, 134, bounds.size.width-30, 40)];
    MyPassword.placeholder =@"请输入WIFI密码";
    MyPassword.borderStyle = UITextBorderStyleRoundedRect;
    MyPassword.secureTextEntry = NO;
    [self.view addSubview:MyPassword];
    
    Sendbtn =[[UIButton alloc]initWithFrame:CGRectMake(35, 194, 85, 45)];
    [Sendbtn setTitle:@"Send" forState:UIControlStateNormal];
    [Sendbtn setTintColor:[UIColor whiteColor]];
    [Sendbtn setBackgroundColor:[UIColor blackColor]];
    [Sendbtn addTarget:self action:@selector(PlayVoice) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:Sendbtn];
    
    
    Cancelbtn =[[UIButton alloc]initWithFrame:CGRectMake(200, 194, 85, 45)];
    [Cancelbtn setTitle:@"Cancel" forState:UIControlStateNormal];
    [Cancelbtn setTintColor:[UIColor whiteColor]];
    [Cancelbtn setBackgroundColor:[UIColor blackColor]];
    [Cancelbtn addTarget:self action:@selector(StopVoice) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:Cancelbtn];
    

}

-(void)StopVoice
{
    [play isStopped];
    
    play = nil;
    
    if ([_voiceTimesTimer isValid])
    {
        [_voiceTimesTimer invalidate];
        _voiceTimesTimer = nil;
    }
    
    if (_voiceThread)
    {
        [_voiceThread cancel];
        _voiceThread = nil;
    }
    
    [SmartLink StopSmartLink];
    
    [_SendBoSmartLinkTimer invalidate];
    
    _SendBoSmartLinkTimer = nil;
    
    
}

-(void)PlayVoice
{   _times = 0;//控制播放次数
    NSThread *voiceThread = [[NSThread alloc]initWithTarget:self selector:@selector(VoiceThread) object:nil];
    _voiceThread = voiceThread;
    [voiceThread start];
    
    //smartLink
    [SmartLink StopSmartLink];
    [SmartLink setSmartLink:MyWiFiSSID setAuthmod:@"0" setPassWord:MyPassword.text];
    
   struct in_addr addr;
    inet_aton([[self getIPAddress] UTF8String], &addr);
    ip = CFSwapInt32BigToHost(ntohl(addr.s_addr));
    
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.SendBoSmartLinkTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(StartCooee) userInfo:nil repeats:YES];
//        [[NSRunLoop currentRunLoop]addTimer:self.SendBoSmartLinkTimer forMode:NSRunLoopCommonModes];
//    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //[self StartCooee];
           self.SendBoSmartLinkTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(StartCooee) userInfo:nil repeats:YES];
    });
    //[BoSmartLink setBoSmartLink:MyWiFiSSID setLen:(int)strlen([MyWiFiSSID UTF8String]) setPassWord:MyWiFiPwd setPwdLen://(int)strlen([MyWiFiPwd UTF8String]) SetKey:@"" setKeyLen:0 SetIP:ip];
    
}

-(void)StartCooee {
    
    struct in_addr addr;
    inet_aton([[self getIPAddress] UTF8String], &addr);
    ip = CFSwapInt32BigToHost(ntohl(addr.s_addr));
    
    NSLog(@"MyWiFiSSID %@",MyWiFiSSID);
    NSLog(@"MyWiFiPwd %@",MyPassword.text);
    
     //NSLog(@"WIFISSID:%@,WIFILen:%d,WiFIPWD:%@,WIFIPwdLen:%d,IP:%@",MyWiFiSSID,(int)strlen([MyWiFiSSID UTF8String]),MyWiFiPwd,(int)strlen([MyWiFiPwd UTF8String]),ip);
    
    [BoSmartLink setBoSmartLink:MyWiFiSSID setLen:(int)strlen([MyWiFiSSID UTF8String]) setPassWord:MyPassword.text setPwdLen:(int)strlen([MyPassword.text UTF8String]) SetKey:@"" setKeyLen:0 SetIP:ip];
    
    
}

- (NSString *)getIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    
    return address;
}



-(void)VoiceThread
{
    play = [[VoiceEncoder alloc] init];
    
    
    NSArray *array = [NSArray array];
    array = [MyWiFiMac componentsSeparatedByString:@":"];
    NSLog(@"array[4]:%@,array[5]%@",array[4],array[5]);
    
    NSString *str1 = [NSString string];
    str1 = array[5];
    
    NSString *str = [NSString string];
    NSString *str2 = [NSString string];
    NSString *astr;
    NSString *bstr;
    NSString *cstr;
    unsigned long red = 0;
    unsigned long blue = 0;
    unsigned long yellow;
    
    
    if ([array[5] isEqualToString:@"0"]) {
        str = array[3];
        str2 = array[4];
        
        bstr = [NSString stringWithFormat:@"0x%@",str];
        cstr = [NSString stringWithFormat:@"0x%@",str2];
        
        blue = strtoul([cstr UTF8String],0,0);
        red = strtoul([bstr UTF8String],0,0);
        
    }
    astr = [NSString stringWithFormat:@"0x%@",str1];
    yellow = strtoul([astr UTF8String],0,0);
    
    if (MyWiFiMac) {
        
        [play setFreqs:freq freqCount:19];
        
        if ([array[5] isEqualToString:@"0"]){
            
            char mac[2] = {red,blue};
            _mac = mac;
            
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            _voiceTimesTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(startPlay:) userInfo:[NSNumber numberWithInt:2] repeats:YES] ;
            [runLoop run];
        }else{
            
            char mac[1] = {yellow};
            _mac = mac;
            
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            _voiceTimesTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(startPlay:) userInfo:[NSNumber numberWithInt:1] repeats:YES] ;
            
            [runLoop run];
            
            
        }
        
    }
    
    
}

- (void)startPlay:(NSTimer *)aTimer {
    @autoreleasepool {
        MyWiFiPwd = MyPassword.text;
        NSLog(@"pwd ===%@",(MyWiFiPwd));
        [play playWiFi:_mac macLen:1 pwd:MyWiFiPwd  playCount:[[aTimer userInfo] integerValue] muteInterval:8000];
        while (![play isStopped]) {
            usleep(600*4000);
        }
        _times ++;
        if (_times == 10) {
            [_voiceTimesTimer invalidate];
            _voiceTimesTimer = nil;
            play = nil;
            
            [_voiceThread cancel];
            [SmartLink StopSmartLink];
        }
    }
}


//获取当前WiFi名字以及Mac地址
- (NSString *)GetCurrentWiFiSSID {
    NSArray *ifs = (__bridge id)CNCopySupportedInterfaces();
    
    
    id info = nil;
    for (NSString *ifnam in ifs)
    {
        info = (__bridge id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        
        if (info && [info count])
        {
            break;
        }
    }
    
    NSDictionary *dctySSID = (NSDictionary *)info;
    NSString *ssid = [dctySSID objectForKey:@"SSID"];
    MyWiFiSSID =[[NSString alloc] initWithFormat:@"%@", ssid];
    
    NSString *Bssid = [dctySSID objectForKey:@"BSSID"];
    MyWiFiMac =[[NSString alloc] initWithFormat:@"%@", Bssid];
    NSLog(@"________%@",MyWiFiMac);
    
    NSString *tempSSID = [[NSString alloc] initWithFormat:@"%@+%@", ssid, Bssid];
    
    return tempSSID;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
