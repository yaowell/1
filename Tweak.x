#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSTimer *gTimer;
static BOOL gWasVisible = NO;
static BOOL gHasBaseline = NO;
static NSMutableDictionary *gStates;

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

    CGFloat r = 0, g = 0, b = 0, a = 0;

    if ([color getRed:&r green:&g blue:&b alpha:&a]) {
        return [NSString stringWithFormat:@"rgba(%.3f,%.3f,%.3f,%.3f)",r,g,b,a];
    }

    return [NSString stringWithFormat:@"%@",color];
}

static NSString *StateForView(UIView *view)
{
    NSString *cls = NSStringFromClass(view.class);
    NSString *label = view.accessibilityLabel ?: @"nil";
    NSString *value = view.accessibilityValue ?: @"nil";

    NSString *state = [NSString stringWithFormat:
        @"class=%@ frame=%@ hidden=%d alpha=%.3f tint=%@ bg=%@ label=%@ value=%@",
        cls,
        NSStringFromCGRect(view.frame),
        view.hidden,
        view.alpha,
        ColorString(view.tintColor),
        ColorString(view.backgroundColor),
        label,
        value
    ];

    if ([view isKindOfClass:[UIImageView class]]) {
        UIImage *image = ((UIImageView *)view).image;

        if (image) {
            state = [state stringByAppendingFormat:
                @" image=%p size=%@ mode=%ld",
                image,
                NSStringFromCGSize(image.size),
                (long)image.renderingMode
            ];
        } else {
            state = [state stringByAppendingString:@" image=nil"];
        }
    }

    return state;
}

static BOOL InterestingView(UIView *view)
{
    NSString *cls = NSStringFromClass(view.class);

    return
        [cls containsString:@"CCUIButtonModuleView"] ||
        [cls containsString:@"CCUIRoundButton"] ||
        [cls containsString:@"CCUIToggleViewController"] ||
        [cls containsString:@"UIImageView"];
}

static void ScanView(UIView *view)
{
    if (InterestingView(view)) {

        NSString *key = [NSString stringWithFormat:@"%p",view];
        NSString *state = StateForView(view);
        NSString *old = gStates[key];

        if (!old) {
            gStates[key] = state;
        } else if (![old isEqualToString:state]) {

            WriteLog(@"");
            WriteLog(@"===== CHANGED =====");
            WriteLog([NSString stringWithFormat:@"OLD: %@",old]);
            WriteLog([NSString stringWithFormat:@"NEW: %@",state]);
            WriteLog(@"===================");

            gStates[key] = state;
        }
    }

    for (UIView *subview in view.subviews) {
        ScanView(subview);
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

            if ([cls containsString:@"ControlCenter"])
                return window;
        }
    }

    return nil;
}

static void ScanControlCenter(void)
{
    UIWindow *window = FindCCWindow();

    if (!window)
        return;

    BOOL visible = !window.hidden && window.alpha > 0.01;

    if (visible && !gWasVisible) {

        gStates = [NSMutableDictionary dictionary];
        gHasBaseline = YES;

        WriteLog(@"");
        WriteLog(@"================================");
        WriteLog(@"===== DND BASELINE CAPTURE =====");
        WriteLog(@"================================");

        for (UIView *view in window.subviews) {
            ScanView(view);
        }

        WriteLog(@"===== BASELINE READY =====");
    }

    if (visible && gWasVisible && gHasBaseline) {
        for (UIView *view in window.subviews) {
            ScanView(view);
        }
    }

    if (!visible && gWasVisible) {
        gHasBaseline = NO;
        gStates = nil;
    }

    gWasVisible = visible;
}

%ctor
{
    @autoreleasepool {

        WriteLog(@"");
        WriteLog(@"================================");
        WriteLog(@"===== DND COLOR PROBE V4 =====");
        WriteLog(@"================================");

        dispatch_async(dispatch_get_main_queue(), ^{

            gTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                       repeats:YES
                                                         block:^(NSTimer *timer) {
                ScanControlCenter();
            }];

            WriteLog(@"===== DND COLOR PROBE V4 READY =====");
        });
    }
}