//
//  NSString+PJStr.m
//  testSipPhone
//
//  Created by Deemo on 2018/8/24.
//  Copyright © 2018年 ztth. All rights reserved.
//

#import "NSString+PJStr.h"

@implementation NSString (PJStr)
+ (NSString *)stringWithPJString:(pj_str_t)pjString {
    NSString *result = [[NSString alloc] initWithBytes:pjString.ptr length:(NSUInteger)pjString.slen encoding:NSUTF8StringEncoding];
    return result ?: @"";
    
}
@end
