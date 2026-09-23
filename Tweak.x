#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <notify.h>

static int gToken = 0;

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

static void ToggleRecording(void) {
    WriteLog(@"===== TOGGLE COMMAND RECEIVED =====");

    Class cls = objc_getClass("AudioRecorderController");

    if (!cls) {
        WriteLog(@"AudioRecorderController NOT FOUND");
        return;
    }

    WriteLog(@"AudioRecorderController FOUND");

    SEL sharedSel = @selector(sharedInstance);
    SEL toggleSel = @selector(toggleRecordingFromMic:);

    if (![cls respondsToSelector:sharedSel]) {
        WriteLog(@"sharedInstance NOT FOUND");
        return;
    }

    WriteLog(@"sharedInstance FOUND");

    id controller = ((id (*)(id, SEL))objc_msgSend)(cls, sharedSel);

    if (!controller) {
        WriteLog(@"sharedInstance RETURNED NIL");
        return;
    }

    WriteLog([NSString stringWithFormat:@"INSTANCE: %@", controller]);

    if (![controller respondsToSelector:toggleSel]) {
        WriteLog(@"toggleRecordingFromMic: NOT FOUND");
        return;
    }

    WriteLog(@"toggleRecordingFromMic: FOUND");
    WriteLog(@"CALLING TOGGLE NOW");

    ((void (*)(id, SEL, id))objc_msgSend)(
        controller,
        toggleSel,
        nil
    );

    WriteLog(@"===== TOGGLE CALL RETURNED =====");
}

%ctor {
    WriteLog(@"");
    WriteLog(@"===== TOGGLE PROBE LOADED =====");

    int result = notify_register_dispatch(
        "net.yaowell.audiorecorder.toggle",
        &gToken,
        dispatch_get_main_queue(),
        ^(int token) {
            ToggleRecording();
        }
    );

    WriteLog([NSString stringWithFormat:@"notify_register_dispatch RESULT=%d TOKEN=%d", result, gToken]);
}