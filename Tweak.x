#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <substrate.h>
#import <dlfcn.h>
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

static void HookWhenReady(void);

static void StartHookTimer(void) {
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC),
        dispatch_get_main_queue(),
        ^{
            HookWhenReady();
        }
    );
}

static void HookWhenReady(void) {
    Class cls = objc_getClass("AudioRecorderIPCController");

    if (!cls) {
        WriteLog(@"AudioRecorderIPCController NOT READY");
        StartHookTimer();
        return;
    }

    SEL sel = @selector(toggleStartMicRecordingAction);
    Method method = class_getInstanceMethod(cls, sel);

    if (!method) {
        WriteLog(@"toggleStartMicRecordingAction METHOD NOT FOUND");
        return;
    }

    static BOOL hooked = NO;

    if (hooked) {
        return;
    }

    hooked = YES;

    IMP original = method_getImplementation(method);

    IMP replacement = imp_implementationWithBlock(^(__unsafe_unretained id self) {
        WriteLog(@"");
        WriteLog(@"===== toggleStartMicRecordingAction CALLED =====");

        DumpStack();

        ((void (*)(id, SEL))original)(self, sel);

        WriteLog(@"===== toggleStartMicRecordingAction RETURN =====");
    });

    method_setImplementation(method, replacement);

    WriteLog(@"===== HOOK INSTALLED =====");
}

%ctor {
    WriteLog(@"");
    WriteLog(@"===== 1 PROBE LOADED =====");

    StartHookTimer();
}