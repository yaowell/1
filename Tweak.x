#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static void WriteTest(NSString *text) {
    NSString *path = @"/var/mobile/Documents/SimpleCowbell_Scan.txt";

    NSFileHandle *file =
        [NSFileHandle fileHandleForWritingAtPath:path];

    if (!file) {
        [text writeToFile:path
               atomically:YES
                 encoding:NSUTF8StringEncoding
                    error:nil];
        return;
    }

    [file seekToEndOfFile];

    NSString *line =
        [NSString stringWithFormat:@"%@\n", text];

    [file writeData:
        [line dataUsingEncoding:NSUTF8StringEncoding]];

    [file closeFile];
}

%ctor {

    WriteTest(@"===== SimpleCowbell INJECTED =====");

    int count = objc_getClassList(NULL, 0);

    WriteTest(
        [NSString stringWithFormat:
            @"Class count = %d", count]
    );

    if (count <= 0) {
        WriteTest(@"objc_getClassList FAILED");
        return;
    }

    Class *classes =
        (__unsafe_unretained Class *)
        malloc(sizeof(Class) * count);

    int realCount =
        objc_getClassList(classes, count);

    for (int i = 0; i < realCount; i++) {

        const char *name =
            class_getName(classes[i]);

        if (!name)
            continue;

        NSString *className =
            [NSString stringWithUTF8String:name];

        NSString *lower =
            [className lowercaseString];

        if ([lower containsString:@"battery"] ||
            [lower containsString:@"lowpower"] ||
            [lower containsString:@"controlcenter"] ||
            [lower containsString:@"toggle"]) {

            WriteTest(
                [NSString stringWithFormat:
                    @"FOUND CLASS: %@", className]
            );
        }
    }

    free(classes);

    WriteTest(@"===== SCAN DONE =====");
}