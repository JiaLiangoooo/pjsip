//
//  NSString+PJStr.h
//  testSipPhone
//
//  Created by Deemo on 2018/8/24.
//  Copyright © 2018年 ztth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pjsua-lib/pjsua.h>

@interface NSString (PJStr)
+ (NSString *)stringWithPJString:(pj_str_t)pjString;
@end
