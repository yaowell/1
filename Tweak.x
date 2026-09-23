#import <Foundation/Foundation.h>

@interface AudioRecorderIPCController : NSObject
- (void)toggleStartMicRecordingAction;
- (void)manuallyStartRecordingForCurrentRecordableSource;
- (void)manuallyStopRecordingForCurrentSourceBeingRecorded;
@end

static void WriteProbe(NSString *method) {
    @autoreleasepool {
        NSString *path = @"/var/mobile/Documents/AudioRecorderProbe.log";

        NSMutableString *text = [NSMutableString stringWithFormat:@"\n========== %@ ==========\n", method];
        [text appendFormat:@"Time: %@\n", [NSDate date]];
        [text appendFormat:@"Process: %@\n", [[NSProcessInfo processInfo] processName]];
        [text appendString:@"Call Stack:\n"];
        [text appendString:[[NSThread callStackSymbols] componentsJoinedByString:@"\n"]];
        [text appendString:@"\n"];

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

%hook AudioRecorderIPCController

- (void)toggleStartMicRecordingAction {
    WriteProbe(@"toggleStartMicRecordingAction");
    %orig;
}

- (void)manuallyStartRecordingForCurrentRecordableSource {
    WriteProbe(@"manuallyStartRecordingForCurrentRecordableSource");
    %orig;
}

- (void)manuallyStopRecordingForCurrentSourceBeingRecorded {
    WriteProbe(@"manuallyStopRecordingForCurrentSourceBeingRecorded");
    %orig;
}

%end