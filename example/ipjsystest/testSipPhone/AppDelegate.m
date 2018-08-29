//
//  AppDelegate.m
//  SimpleSipPhone
//
//  Created by MK on 15/5/21.
//  Copyright (c) 2015年 Makee. All rights reserved.
//

#import <pjsua-lib/pjsua.h>

#import "AppDelegate.h"
#import "NSString+PJStr.h"
#import "IncomingCallViewController.h"


static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata);
static void on_call_state(pjsua_call_id call_id, pjsip_event *e);
static void on_call_media_state(pjsua_call_id call_id);
static void on_reg_state(pjsua_acc_id acc_id);



#define AUDIO_CODEC_G729    "18"
#define DISABLE_AUDIO_CODEC    "GSM/8000"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(__handleIncommingCall:)
                                                 name:@"SIPIncomingCallNotification"
                                               object:nil];
    
    pj_status_t status;
    
    // 创建SUA
    status = pjsua_create();
    
    if (status != PJ_SUCCESS) {
        NSLog(@"error create pjsua"); return NO;
    }
    
    {
        // SUA 相关配置
        pjsua_config cfg;
        pjsua_media_config media_cfg;
        pjsua_logging_config log_cfg;
        
        pjsua_config_default(&cfg);
        
        // 回调函数配置
        cfg.cb.on_incoming_call = &on_incoming_call;            // 来电回调
        cfg.cb.on_call_media_state = &on_call_media_state;      // 媒体状态回调（通话建立后，要播放RTP流）
        cfg.cb.on_call_state = &on_call_state;                  // 电话状态回调
        cfg.cb.on_reg_state = &on_reg_state;                    // 注册状态回调
        
        // 媒体相关配置
        pjsua_media_config_default(&media_cfg);
        media_cfg.clock_rate = 16000;
        media_cfg.snd_clock_rate = 16000;
        media_cfg.ec_tail_len = 0;
        
        // 日志相关配置
        pjsua_logging_config_default(&log_cfg);
#ifdef DEBUG
        log_cfg.msg_logging = PJ_TRUE;
        log_cfg.console_level = 4;
        log_cfg.level = 5;
#else
        log_cfg.msg_logging = PJ_FALSE;
        log_cfg.console_level = 0;
        log_cfg.level = 0;
#endif
        
        // 初始化PJSUA
        status = pjsua_init(&cfg, &log_cfg, &media_cfg);
        if (status != PJ_SUCCESS) {
            NSLog(@"error init pjsua"); return NO;
        }
    }
    
    // udp transport
    {
        pjsua_transport_config cfg;
        pjsua_transport_config_default(&cfg);
       
        // 传输类型配置
        status = pjsua_transport_create(PJSIP_TRANSPORT_UDP, &cfg, NULL);
        if (status != PJ_SUCCESS) {
            NSLog(@"error add transport for pjsua"); return NO;
        }
    }
    
    // 启动PJSUA
    status = pjsua_start();
    if (status != PJ_SUCCESS) {
        NSLog(@"error start pjsua"); return NO;
    }
    
    {
        pj_str_t codec_id = pj_str( "speex/8000" );
        
        pj_status_t status = pjsua_codec_set_priority(&codec_id, PJMEDIA_CODEC_PRIO_DISABLED);
        if (status != PJ_SUCCESS) {
            NSLog(@"codeC设置失败");
        }
    }
    
    {
        pj_str_t codec_id = pj_str( "G729/8000" );
        pj_status_t status = pjsua_codec_set_priority(&codec_id, PJMEDIA_CODEC_PRIO_NORMAL);
        if (status != PJ_SUCCESS) {
            NSLog(@"codeC设置失败");
        }
    }
    {
        const unsigned kCodecInfoSize = 64;
        pjsua_codec_info codecInfo[kCodecInfoSize];
        unsigned codecCount = kCodecInfoSize;
        pj_status_t status = pjsua_enum_codecs(codecInfo, &codecCount);
        if (status != PJ_SUCCESS) {
            NSLog(@"Error getting list of codecs");
        } else {
            for (NSUInteger i = 0; i < codecCount; i++) {
                NSString *codecIdentifier = [NSString stringWithPJString:codecInfo[i].codec_id];
                NSLog(@"codec = %@",codecIdentifier);
                
            }
        }
    }
    
    // 快捷方式获得session对象
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString:@"http://www.daka.com/login?username=daka&pwd=123"];
    // 通过URL初始化task,在block内部可以直接对返回的数据进行处理
    NSURLSessionTask *task = [session dataTaskWithURL:url
                                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                        NSLog(@"%@", [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil]);
                                    }];
    
    // 启动任务
    [task resume];
    return YES;
}
    
+ (NSString *)stringWithPJString:(pj_str_t)pjString {
        NSString *result = [[NSString alloc] initWithBytes:pjString.ptr length:(NSUInteger)pjString.slen encoding:NSUTF8StringEncoding];
        return result ?: @"";
        
}

- (void)__handleIncommingCall:(NSNotification *)notification {
    pjsua_call_id callId = [notification.userInfo[@"call_id"] intValue];
    NSString *phoneNumber = notification.userInfo[@"remote_address"];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    IncomingCallViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"IncomingCallViewController"];
    
    viewController.phoneNumber = phoneNumber;
    viewController.callId = callId;
    
    UIViewController *rootViewController = self.window.rootViewController;
    [rootViewController presentViewController:viewController animated:YES completion:nil];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end



static void on_incoming_call(pjsua_acc_id acc_id, pjsua_call_id call_id, pjsip_rx_data *rdata) {
    pjsua_call_info ci;
    pjsua_call_get_info(call_id, &ci);
    
    NSString *remote_info = [NSString stringWithUTF8String:ci.remote_info.ptr];
    
    NSUInteger startIndex = [remote_info rangeOfString:@"<"].location;
    NSUInteger endIndex = [remote_info rangeOfString:@">"].location;
    
    NSString *remote_address = [remote_info substringWithRange:NSMakeRange(startIndex + 1, endIndex - startIndex - 1)];
    remote_address = [remote_address componentsSeparatedByString:@":"][1];
    
    id argument = @{
                    @"call_id"          : @(call_id),
                    @"remote_address"   : remote_address
                    };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SIPIncomingCallNotification" object:nil userInfo:argument];
    });
    
}

static void on_call_state(pjsua_call_id call_id, pjsip_event *e) {
    pjsua_call_info ci;
    pjsua_call_get_info(call_id, &ci);
    
    id argument = @{
                    @"call_id"  : @(call_id),
                    @"state"    : @(ci.state)
                    };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SIPCallStatusChangedNotification" object:nil userInfo:argument];
    });
}

static void on_call_media_state(pjsua_call_id call_id) {
    pjsua_call_info ci;
    pjsua_call_get_info(call_id, &ci);
    
    if (ci.media_status == PJSUA_CALL_MEDIA_ACTIVE) {
        // When media is active, connect call to sound device.
        pjsua_conf_connect(ci.conf_slot, 0);
        pjsua_conf_connect(0, ci.conf_slot);
    }
}

static void on_reg_state(pjsua_acc_id acc_id) {
    
    pj_status_t status;
    pjsua_acc_info info;
    
    status = pjsua_acc_get_info(acc_id, &info);
    if (status != PJ_SUCCESS)
        return;
    
    id argument = @{
                    @"acc_id"       : @(acc_id),
                    @"status_text"  : [NSString stringWithUTF8String:info.status_text.ptr],
                    @"status"       : @(info.status)
                    };
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SIPRegisterStatusNotification" object:nil userInfo:argument];
    });
}



