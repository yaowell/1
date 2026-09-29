#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSTimer *gTimer;
static NSMutableDictionary *gLastStates;

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

static NSString *ColorString(UIColor *color)
{
    if (!color) return @"nil";

    CGFloat r = 0;
    CGFloat g = 0;
    CGFloat b = 0;
    CGFloat a = 0;

    if ([color getRed:&r green:&g blue:&b alpha:&a]) {
        return [NSString stringWithFormat:@"rgba(%.3f,%.3f,%.3f,%.3f)", r,g,b,a];
    }

    return [NSString stringWithFormat:@"%@", color];
}

static NSString *ViewKey(UIView *view)
{
    return [NSString stringWithFormat:@"%p", view];
}

static void InspectView(UIView *view)
{
    NSString *cls = NSStringFromClass([view class]);

    BOOL interesting =
        [cls containsString:@"CCUIRoundButton"] ||
        [cls containsString:@"CCUIButtonModuleView"] ||
        [cls containsString:@"CCUIToggleViewController"] ||
        [cls containsString:@"CCUIModule"] ||
        [cls containsString:@"UIImageView"];

    if (!interesting)
        return;

    NSString *key = ViewKey(view);

    NSString *label = nil;
    NSString *value = nil;

    @try {
        label = view.accessibilityLabel;
        value = view.accessibilityValue;
    } @catch (...) {}

    NSString *state = [NSString stringWithFormat:
        @"class=%@ frame=%@ hidden=%d alpha=%.3f tint=%@ label=%@ value=%@",
        cls,
        NSStringFromCGRect(view.frame),
        view.hidden,
        view.alpha,
        ColorString(view.tintColor),
        label ?: @"nil",
        value ?: @"nil"
    ];

    if ([view isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView *)view;
        UIImage *image = imageView.image;

        if (image) {
            state = [state stringByAppendingFormat:
                @" image=%p size=%@ scale=%.2f renderingMode=%ld",
                image,
                NSStringFromCGSize(image.size),
                image.scale,
                (long)image.renderingMode
            ];
        } else {
            state = [state stringByAppendingString:@" image=nil"];
        }
    }

    NSString *old = gLastStates[key];

    if (!old || ![old isEqualToString:state]) {
        WriteLog([NSString stringWithFormat:@"[CHANGE] %@", state]);
        gLastStates[key] = state;
    }

    for (UIView *subview in view.subviews) {
        InspectView(subview);
    }
}

static UIWindow *FindControlCenterWindow(void)
{
    UIApplication *app = [UIApplication sharedApplication];

    for (UIScene *scene in app.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]])
            continue;

        UIWindowScene *windowScene = (UIWindowScene *)scene;

        for (UIWindow *window in windowScene.windows) {
            NSString *cls = NSStringFromClass([window class]);

            if ([cls containsString:@"ControlCenter"] ||
                [cls containsString:@"CCUI"]) {
                return window;
            }
        }
    }

    return nil;
}

static void ScanControlCenter(void)
{
    UIWindow *window = FindControlCenterWindow();

    if (!window) {
        return;
    }

    NSString *windowClass = NSStringFromClass([window class]);

    NSString *header = [NSString stringWithFormat:
        @"[CC FOUND] window=%@ frame=%@ hidden=%d alpha=%.3f",
        windowClass,
        NSStringFromCGRect(window.frame),
        window.hidden,
        window.alpha
    ];

    static NSString *lastHeader;

    if (!lastHeader || ![lastHeader isEqualToString:header]) {
        WriteLog(header);
        lastHeader = [header copy];
    }

    for (UIView *view in window.subviews) {
        InspectView(view);
    }
}

%ctor
{
    @autoreleasepool {

        WriteLog(@"");
        WriteLog(@"================================");
        WriteLog(@"===== DND COLOR PROBE V2 =====");
        WriteLog(@"================================");

        gLastStates = [NSMutableDictionary dictionary];

        dispatch_async(dispatch_get_main_queue(), ^{
            gTimer = [NSTimer scheduledTimerWithTimeInterval:0.30
                                                       repeats:YES
                                                         block:^(NSTimer *timer) {
                ScanControlCenter();
            }];

            WriteLog(@"===== DND COLOR PROBE V2 READY =====");
        });
    }
}