#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSTimer *gTimer;
static BOOL gWasVisible = NO;
static BOOL gDumped = NO;

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

    CGFloat r=0,g=0,b=0,a=0;

    if ([color getRed:&r green:&g blue:&b alpha:&a]) {
        return [NSString stringWithFormat:@"rgba(%.3f,%.3f,%.3f,%.3f)",r,g,b,a];
    }

    return [NSString stringWithFormat:@"%@",color];
}

static void DumpModule(UIView *view, NSInteger level)
{
    NSString *cls = NSStringFromClass(view.class);

    BOOL module =
        [cls containsString:@"CCUIButtonModuleView"] ||
        [cls containsString:@"CCUIModule"] ||
        [cls containsString:@"CCUIRoundButton"] ||
        [cls containsString:@"CCUIToggleViewController"];

    if (module) {

        WriteLog([NSString stringWithFormat:
            @"MODULE class=%@ frame=%@ hidden=%d alpha=%.2f tint=%@ label=%@ value=%@ subviews=%lu",
            cls,
            NSStringFromCGRect(view.frame),
            view.hidden,
            view.alpha,
            ColorString(view.tintColor),
            view.accessibilityLabel ?: @"nil",
            view.accessibilityValue ?: @"nil",
            (unsigned long)view.subviews.count
        ]);

        for (UIView *subview in view.subviews) {

            NSString *subClass = NSStringFromClass(subview.class);

            if ([subClass containsString:@"UIImageView"] ||
                [subClass containsString:@"Button"] ||
                [subClass containsString:@"Label"]) {

                UIImage *image = nil;

                if ([subview isKindOfClass:[UIImageView class]]) {
                    image = ((UIImageView *)subview).image;
                }

                WriteLog([NSString stringWithFormat:
                    @"  CHILD class=%@ frame=%@ tint=%@ label=%@ value=%@ image=%p imageSize=%@",
                    subClass,
                    NSStringFromCGRect(subview.frame),
                    ColorString(subview.tintColor),
                    subview.accessibilityLabel ?: @"nil",
                    subview.accessibilityValue ?: @"nil",
                    image,
                    image ? NSStringFromCGSize(image.size) : @"nil"
                ]);
            }
        }
    }

    for (UIView *subview in view.subviews) {
        DumpModule(subview, level + 1);
    }
}

static UIWindow *FindCCWindow(void)
{
    UIApplication *app = [UIApplication sharedApplication];

    for (UIScene *scene in app.connectedScenes) {

        if (![scene isKindOfClass:[UIWindowScene class]])
            continue;

        UIWindowScene *ws = (UIWindowScene *)scene;

        for (UIWindow *window in ws.windows) {

            if ([NSStringFromClass(window.class) containsString:@"ControlCenter"])
                return window;
        }
    }

    return nil;
}

static void Check(void)
{
    UIWindow *window = FindCCWindow();

    if (!window)
        return;

    BOOL visible = !window.hidden && window.alpha > 0.01;

    if (visible && !gWasVisible && !gDumped) {

        WriteLog(@"");
        WriteLog(@"================================");
        WriteLog(@"===== DND MODULE PROBE V6 =====");
        WriteLog(@"================================");

        for (UIView *view in window.subviews) {
            DumpModule(view, 0);
        }

        WriteLog(@"===== V6 END =====");

        gDumped = YES;
    }

    if (!visible && gWasVisible) {
        gDumped = NO;
    }

    gWasVisible = visible;
}

%ctor
{
    @autoreleasepool {

        WriteLog(@"");
        WriteLog(@"================================");
        WriteLog(@"===== DND MODULE PROBE V6 =====");
        WriteLog(@"================================");

        dispatch_async(dispatch_get_main_queue(), ^{

            gTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                       repeats:YES
                                                         block:^(NSTimer *timer) {
                Check();
            }];

            WriteLog(@"===== V6 READY =====");
        });
    }
}