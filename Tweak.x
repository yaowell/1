#import <Foundation/Foundation.h>

%ctor {
    NSString *path = @"/var/mobile/Documents/1_build_test.log";
    NSString *text = [NSString stringWithFormat:@"1 loaded: %@\n", [NSDate date]];
    [text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}