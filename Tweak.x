#import <Foundation/Foundation.h>

static void WriteLog(void) {
    @autoreleasepool {
        NSString *path = @"/var/mobile/Documents/1_process.log";
        NSString *text = [NSString stringWithFormat:@"\nLoaded: %@\nProcess: %@\nBundle: %@\n",
            [NSDate date],
            [[NSProcessInfo processInfo] processName],
            [[NSBundle mainBundle] bundleIdentifier]];

        NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:path];

        if (!file) {
            [text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
        } else {
            [file seekToEndOfFile];
            [file writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
            [file closeFile];
        }
    }
}

%ctor {
    WriteLog();
}