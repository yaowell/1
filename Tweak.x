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

static NSString *ImageInfo(UIImage *image)
{
    if (!image) return @"image=nil";

    return [NSString stringWithFormat:
        @"image=%p size=%@ scale=%.2f mode=%ld",
        image,
        NSStringFromCGSize(image.size),
        image.scale,
        (long)image.renderingMode
    ];
}

static void DumpParentChain(UIView *view)
{
    NSInteger level = 0;

    while (view && level < 8) {

        WriteLog([NSString stringWithFormat:
            @"  PARENT[%ld] class=%@ frame=%@ tint=%@ bg=%@",
            (long)level,
            NSStringFromClass(view.class),
            NSStringFromCGRect(view.frame),
            ColorString(view.tintColor),
            ColorString(view.backgroundColor)
        ]);

        view = view.superview;
        level++;
    }
}

static BOOL InterestingImageView(UIImageView *view)
{
    if (!view.image)
        return NO;

    NSString *cls = NSStringFromClass(view.class);

    if (![cls isEqualToString:@"UIImageView"])
        return NO;

    CGSize size = view.image.size;

    if (size.width < 10 || size.width > 40)
        return NO;

    if (size.height < 5 || size.height > 40)
        return NO;

    return YES;
}

static void ScanView(UIView *view)
{
    if ([view isKindOfClass:[UIImageView class]]) {

        UIImageView *imageView = (UIImageView *)view;

        if (InterestingImageView(imageView)) {

            NSString *key = [NSString stringWithFormat:@"%p",imageView];

            NSString *state = [NSString stringWithFormat:
                @"class=%@ frame=%@ tint=%@ bg=%@ %@",
                NSStringFromClass(imageView.class),
                NSStringFromCGRect(imageView.frame),
                ColorString(imageView.tintColor),
                ColorString(imageView.backgroundColor),
                ImageInfo(imageView.image)
            ];

            NSString *old = gStates[key];

            if (!old) {
                gStates[key] = state;
            }
            else if (![old isEqualToString:state]) {

                WriteLog(@"");
                WriteLog(@"========== IMAGE CHANGED ==========");
                WriteLog([NSString stringWithFormat:@"OLD: %@",old]);
                WriteLog([NSString stringWithFormat:@"NEW: %@",state]);

                WriteLog(@"----- PARENT CHAIN -----");
                DumpParentChain(imageView);
                WriteLog(@"----- END PARENT CHAIN -----");

                WriteLog(@"===================================");

                gStates[key] = state;
            }
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
        WriteLog(@"===== DND PROBE V5 BASELINE =====");
        WriteLog(@"================================");

        for (UIView *view in window.subviews) {
            ScanView(view);
        }

        WriteLog(@"===== V5 BASELINE READY =====");
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
        WriteLog(@"===== DND COLOR PROBE V5 =====");
        WriteLog(@"================================");

        dispatch_async(dispatch_get_main_queue(), ^{

            gTimer = [NSTimer scheduledTimerWithTimeInterval:0.25
                                                       repeats:YES
                                                         block:^(NSTimer *timer) {
                ScanControlCenter();
            }];

            WriteLog(@"===== DND COLOR PROBE V5 READY =====");
        });
    }
}