#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dispatch/dispatch.h>

static void WriteLog(NSString *text) {
    @autoreleasepool {
        NSString *path = @"/var/mobile/Documents/1_probe.log";
        NSString *line = [NSString stringWithFormat:@"%@\n", text];
        NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];

        NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:path];

        if (!file) {
            [line writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
        } else {
            [file seekToEndOfFile];
            [file writeData:data];
            [file closeFile];
        }
    }
}

static void CheckClass(NSString *tag) {
    NSString *process = [[NSProcessInfo processInfo] processName];
    NSString *bundle = [[NSBundle mainBundle] bundleIdentifier];
    Class cls = objc_getClass("AudioRecorderIPCController");

    WriteLog([NSString stringWithFormat:
        @"[%@] Process=%@ Bundle=%@ AudioRecorderIPCController=%@",
        tag,
        process,
        bundle,
        cls ? @"FOUND" : @"NOT FOUND"
    ]);
}

%ctor {
    CheckClass(@"0s");

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC),
        dispatch_get_main_queue(),
        ^{
            CheckClass(@"5s");
        }
    );

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC),
        dispatch_get_main_queue(),
        ^{
            CheckClass(@"15s");
        }
    );

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC),
        dispatch_get_main_queue(),
        ^{
            CheckClass(@"30s");
        }
    );
}