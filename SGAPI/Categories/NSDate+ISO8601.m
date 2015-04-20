//
//  NSDate+NSDate_ISO8601.m
//  Pods
//
//  Created by James Van-As on 17/04/15.
//
//

#import "NSDate+ISO8601.h"

@implementation NSDate (ISO8601)

- (NSString *)ISO8601 {
    static NSDateFormatter *dateFormatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = NSDateFormatter.new;
        dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ";
    });
    return [dateFormatter stringFromDate:self];
}

@end
