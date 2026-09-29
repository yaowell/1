#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSTimer *gTimer;
static BOOL gWasVisible = NO;

static void WriteLog(NSString *text)
{
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

static void DumpView(UIView *view, NSInteger level)
{
    if (!view) return;

    NSMutableString *indent = [NSMutableString string];
    for (NSInteger i = 0; i < level; i++) {
        [indent appendString:@"  "];
    }

    NSString *cls = NSStringFromClass(view.class);
    NSString *label = nil;
    NSString *value = nil;

    @try {
        label = view.accessibilityLabel;
        value = view.accessibilityValue;
    } @catch (...) {}

    WriteLog([NSString stringWithFormat:
        @"%@%@ frame=%@ hidden=%d alpha=%.2f tint=%@ label=%@ value=%@ subviews=%lu",
        indent,
        cls,
        NSStringFromCGRect(view.frame),
        view.hidden,
        view.alpha,
        view.tintColor,
        label ?: @"nil",
        value ?: @"nil",
        (unsigned long)view.subviews.count
    ]);

    for (UIView *subview in view.subviews) {
        DumpView(subview, level + 1);
    }
}

static UIWindow *FindCCWindow(void)
{
    UIApplication *app = [UIApplication sharedApplication];

    for (UIScene *scene in app.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]])
            continue;

        UIWindowScene *sceneWindow = (UIWindowScene *)scene;

        for (UIWindow *window in sceneWindow.windows) {
            NSString *cls = NSStringFromClass(window.class);

            if ([cls containsString:@"ControlCenter"]) {
                return window;
            }
        }
    }

    return nil;
}

static void CheckControlCenter(void)
{
    UIWindow *window = FindCCWindow();
    if (!window) return;

    BOOL visible = !window.hidden && window.alpha > 0.01;

    if (visible && !gWasVisible) {
        WriteLog(@"");
        WriteLog(@"================================");
        WriteLog(@"===== CONTROL CENTER OPENED =====");
        WriteLog(@"================================");

        WriteLog([NSString stringWithFormat:
            @"WINDOW CLASS: %@",
            NSStringFromClass(window.class)
        ]);

        WriteLog([NSString stringWithFormat:
            @"WINDOW FRAME: %@",
            NSStringFromCGRect(window.frame)
        ]);

        WriteLog(@"===== BEGIN FULL VIEW HIERARCHY =====");

        for (UIView *view in window.subviews) {
            DumpView(view, 0);
        }

        WriteLog(@"===== END FULL VIEW HIERARCHY =====");
    }

    gWasVisible = visible;
}

%ctor
{
    @autoreleasepool {
        WriteLog(@"");
        WriteLog(@"================================");
        WriteLog(@"===== DND HIERARCHY PROBE V3 =====");
        WriteLog(@"================================");

        dispatch_async(dispatch_get_main_queue(), ^{
            gTimer = [NSTimer scheduledTimerWithTimeInterval:0.20
                                                       repeats:YES
                                                         block:^(NSTimer *timer) {
                CheckControlCenter();
            }];

            WriteLog(@"===== DND HIERARCHY PROBE V3 READY =====");
        });
    }
}