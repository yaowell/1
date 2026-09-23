#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static void WriteLog(NSString *text) {
    @autoreleasepool {
        NSString *path = @"/var/mobile/Documents/1_process.log";
        NSString *line = [NSString stringWithFormat:@"%@\n", text];

        NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:path];

        if (!file) {
            [line writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
        } else {
            [file seekToEndOfFile];
            [file writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
            [file closeFile];
        }
    }
}

%ctor {
    NSString *process = [[NSProcessInfo processInfo] processName];
    NSString *bundle = [[NSBundle mainBundle] bundleIdentifier];
    Class cls = objc_getClass("AudioRecorderIPCController");

    WriteLog([NSString stringWithFormat:
        @"Process: %@\nBundle: %@\nAudioRecorderIPCController: %@\n",
        process,
        bundle,
        cls ? @"FOUND" : @"NOT FOUND"
    ]);
}