#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString * const kLogPath =
    @"/var/mobile/Documents/DNDProbe.log";

static void WriteLog(NSString *text)
{
    @autoreleasepool {
        NSString *line =
            [NSString stringWithFormat:@"%@\n", text];

        NSFileHandle *file =
            [NSFileHandle fileHandleForWritingAtPath:kLogPath];

        if (!file) {
            [line writeToFile:kLogPath
                   atomically:YES
                     encoding:NSUTF8StringEncoding
                        error:nil];
        } else {
            [file seekToEndOfFile];
            [file writeData:
                [line dataUsingEncoding:NSUTF8StringEncoding]];
            [file closeFile];
        }
    }
}

static void DumpClasses(void)
{
    int count = objc_getClassList(NULL, 0);

    if (count <= 0) {
        WriteLog(@"objc_getClassList FAILED");
        return;
    }

    Class *classes =
        (__unsafe_unretained Class *)malloc(
            sizeof(Class) * count
        );

    count = objc_getClassList(classes, count);

    WriteLog(@"===== CCUI CLASS LIST BEGIN =====");

    for (int i = 0; i < count; i++) {

        Class cls = classes[i];

        if (!cls)
            continue;

        NSString *name =
            NSStringFromClass(cls);

        if ([name rangeOfString:@"CCUI"
                        options:NSCaseInsensitiveSearch].location
            != NSNotFound) {

            WriteLog(name);
        }

        if ([name rangeOfString:@"Disturb"
                        options:NSCaseInsensitiveSearch].location
            != NSNotFound) {

            WriteLog(
                [NSString stringWithFormat:
                    @"*** DISTURB CLASS: %@ ***",
                    name]
            );
        }

        if ([name rangeOfString:@"Focus"
                        options:NSCaseInsensitiveSearch].location
            != NSNotFound) {

            WriteLog(
                [NSString stringWithFormat:
                    @"*** FOCUS CLASS: %@ ***",
                    name]
            );
        }
    }

    WriteLog(@"===== CCUI CLASS LIST END =====");

    free(classes);
}

%ctor
{
    @autoreleasepool {

        WriteLog(@"");
        WriteLog(@"================================");
        WriteLog(@"===== DND CLASS PROBE LOADED =====");
        WriteLog(@"================================");

        DumpClasses();

        WriteLog(@"===== DND CLASS PROBE READY =====");
    }
}