//
//  IncomingCallViewController.h
//  SimpleSipPhone
//
//  Created by Deemo on 18/8/23.
//  Copyright (c) 2018年 ICSOC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IncomingCallViewController : UIViewController

@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, assign) NSInteger callId;

@end
