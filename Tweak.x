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

static void DumpStack(void) {
    NSArray *stack = [NSThread callStackSymbols];

    WriteLog(@"----- CALL STACK -----");

    for (NSString *line in stack) {
        WriteLog(line);
    }

    WriteLog(@"----- END CALL STACK -----");
}

static void HookVoidMethod(Class cls, SEL sel, NSString *name) {
    Method method = class_getInstanceMethod(cls, sel);

    if (!method) {
        WriteLog([NSString stringWithFormat:@"NOT FOUND: %@", name]);
        return;
    }

    IMP original = method_getImplementation(method);

    IMP replacement = imp_implementationWithBlock(^(__unsafe_unretained id self) {
        WriteLog(@"");
        WriteLog([NSString stringWithFormat:@"===== %@ =====", name]);

        DumpStack();

        ((void (*)(id, SEL))original)(self, sel);

        WriteLog([NSString stringWithFormat:@"===== %@ RETURN =====", name]);
    });

    method_setImplementation(method, replacement);

    WriteLog([NSString stringWithFormat:@"HOOKED: %@", name]);
}

static void HookOneArgMethod(Class cls, SEL sel, NSString *name) {
    Method method = class_getInstanceMethod(cls, sel);

    if (!method) {
        WriteLog([NSString stringWithFormat:@"NOT FOUND: %@", name]);
        return;
    }

    IMP original = method_getImplementation(method);

    IMP replacement = imp_implementationWithBlock(^(__unsafe_unretained id self, __unsafe_unretained id arg) {
        WriteLog(@"");
        WriteLog([NSString stringWithFormat:@"===== %@ =====", name]);

        if (arg) {
            WriteLog([NSString stringWithFormat:@"ARG CLASS: %@", NSStringFromClass([arg class])]);
            WriteLog([NSString stringWithFormat:@"ARG: %@", arg]);
        } else {
            WriteLog(@"ARG: (null)");
        }

        DumpStack();

        ((void (*)(id, SEL, id))original)(self, sel, arg);

        WriteLog([NSString stringWithFormat:@"===== %@ RETURN =====", name]);
    });

    method_setImplementation(method, replacement);

    WriteLog([NSString stringWithFormat:@"HOOKED: %@", name]);
}

static BOOL HookClass(void) {
    Class controller = objc_getClass("AudioRecorderController");
    Class ipc = objc_getClass("AudioRecorderIPCController");

    BOOL foundAnything = NO;

    if (controller) {
        foundAnything = YES;

        WriteLog(@"===== AudioRecorderController FOUND =====");

        HookOneArgMethod(
            controller,
            @selector(recButtonTapped:),
            @"AudioRecorderController recButtonTapped:"
        );

        HookOneArgMethod(
            controller,
            @selector(toggleRecordingFromMic:),
            @"AudioRecorderController toggleRecordingFromMic:"
        );

        HookVoidMethod(
            controller,
            @selector(startRecordingFromMic),
            @"AudioRecorderController startRecordingFromMic"
        );

        HookVoidMethod(
            controller,
            @selector(stopRecordingFromMic),
            @"AudioRecorderController stopRecordingFromMic"
        );

        HookVoidMethod(
            controller,
            @selector(reallyStartRecordingFromMic),
            @"AudioRecorderController reallyStartRecordingFromMic"
        );
    } else {
        WriteLog(@"AudioRecorderController NOT READY");
    }

    if (ipc) {
        foundAnything = YES;

        WriteLog(@"===== AudioRecorderIPCController FOUND =====");

        HookVoidMethod(
            ipc,
            @selector(manuallyStartRecordingForCurrentRecordableSource),
            @"AudioRecorderIPCController manuallyStartRecordingForCurrentRecordableSource"
        );

        HookVoidMethod(
            ipc,
            @selector(manuallyStopRecordingForCurrentSourceBeingRecorded),
            @"AudioRecorderIPCController manuallyStopRecordingForCurrentSourceBeingRecorded"
        );
    } else {
        WriteLog(@"AudioRecorderIPCController NOT READY");
    }

    return foundAnything;
}

static void TryInstall(void) {
    static BOOL installed = NO;

    if (installed) {
        return;
    }

    Class controller = objc_getClass("AudioRecorderController");
    Class ipc = objc_getClass("AudioRecorderIPCController");

    if (!controller && !ipc) {
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
            dispatch_get_main_queue(),
            ^{
                TryInstall();
            }
        );

        return;
    }

    installed = YES;

    WriteLog(@"");
    WriteLog(@"===== INSTALLING LARGE AUDIORECORDER PROBE =====");

    HookClass();

    WriteLog(@"===== LARGE PROBE INSTALL COMPLETE =====");
}

%ctor {
    WriteLog(@"");
    WriteLog(@"===== 1 PROBE LOADED =====");

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
        dispatch_get_main_queue(),
        ^{
            TryInstall();
        }
    );
}