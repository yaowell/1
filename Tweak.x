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
    NSArray *symbols = [NSThread callStackSymbols];

    WriteLog(@"----- CALL STACK -----");

    for (NSString *symbol in symbols) {
        WriteLog(symbol);
    }

    WriteLog(@"----- END STACK -----");
}

static void InstallHook(void) {
    Class cls = objc_getClass("AudioRecorderIPCController");

    if (!cls) {
        dispatch_after(
            dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
            dispatch_get_main_queue(),
            ^{
                InstallHook();
            }
        );
        return;
    }

    static BOOL installed = NO;

    if (installed) {
        return;
    }

    installed = YES;

    SEL startSel = @selector(manuallyStartRecordingForCurrentRecordableSource);
    SEL stopSel = @selector(manuallyStopRecordingForCurrentSourceBeingRecorded);

    Method startMethod = class_getInstanceMethod(cls, startSel);
    Method stopMethod = class_getInstanceMethod(cls, stopSel);

    if (startMethod) {
        IMP originalStart = method_getImplementation(startMethod);

        IMP replacementStart = imp_implementationWithBlock(^(__unsafe_unretained id self) {
            WriteLog(@"");
            WriteLog(@"===== manuallyStartRecordingForCurrentRecordableSource CALLED =====");
            DumpStack();

            ((void (*)(id, SEL))originalStart)(self, startSel);

            WriteLog(@"===== START RETURN =====");
        });

        method_setImplementation(startMethod, replacementStart);

        WriteLog(@"START HOOK INSTALLED");
    } else {
        WriteLog(@"START METHOD NOT FOUND");
    }

    if (stopMethod) {
        IMP originalStop = method_getImplementation(stopMethod);

        IMP replacementStop = imp_implementationWithBlock(^(__unsafe_unretained id self) {
            WriteLog(@"");
            WriteLog(@"===== manuallyStopRecordingForCurrentSourceBeingRecorded CALLED =====");
            DumpStack();

            ((void (*)(id, SEL))originalStop)(self, stopSel);

            WriteLog(@"===== STOP RETURN =====");
        });

        method_setImplementation(stopMethod, replacementStop);

        WriteLog(@"STOP HOOK INSTALLED");
    } else {
        WriteLog(@"STOP METHOD NOT FOUND");
    }
}

%ctor {
    WriteLog(@"");
    WriteLog(@"===== 1 PROBE LOADED =====");

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
        dispatch_get_main_queue(),
        ^{
            InstallHook();
        }
    );
}