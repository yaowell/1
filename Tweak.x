#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSTimer *gTimer;
static UIWindow *gWindow;
static BOOL gVisible = NO;
static BOOL gBaselineReady = NO;
static BOOL gLastDNDState = NO;

static NSMutableDictionary *gBaseline = nil;

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

static NSString *ParentChain(UIView *view)
{
    NSMutableArray *array = [NSMutableArray array];

    UIView *v = view.superview;

    while (v) {
        [array addObject:NSStringFromClass(v.class)];
        v = v.superview;
    }

    return [array componentsJoinedByString:@" <- "];
}

static BOOL IsTargetView(UIView *view)
{
    NSString *cls = NSStringFromClass(view.class);

    return
        [cls containsString:@"CCUIButtonModuleView"] ||
        [cls containsString:@"CCUIRoundButton"];
}

static NSString *ViewKey(UIView *view)
{
    return [NSString stringWithFormat:@"%p",view];
}

static NSDictionary *StateForView(UIView *view)
{
    NSMutableArray *children = [NSMutableArray array];

    for (UIView *subview in view.subviews) {

        if (![subview isKindOfClass:[UIImageView class]])
            continue;

        UIImageView *imageView = (UIImageView *)subview;

        [children addObject:@{
            @"class": NSStringFromClass(subview.class),
            @"frame": NSStringFromCGRect(subview.frame),
            @"tint": ColorString(subview.tintColor),
            @"image": [NSString stringWithFormat:@"%p",imageView.image],
            @"size": imageView.image ?
                NSStringFromCGSize(imageView.image.size) : @"nil"
        }];
    }

    return @{
        @"class": NSStringFromClass(view.class),
        @"frame": NSStringFromCGRect(view.frame),
        @"hidden": @(view.hidden),
        @"alpha": @(view.alpha),
        @"tint": ColorString(view.tintColor),
        @"selected": [view respondsToSelector:@selector(isSelected)] ?
            @([view isSelected]) : @(-1),
        @"highlighted": [view respondsToSelector:@selector(isHighlighted)] ?
            @([view isHighlighted]) : @(-1),
        @"identifier": view.accessibilityIdentifier ?: @"nil",
        @"label": view.accessibilityLabel ?: @"nil",
        @"value": view.accessibilityValue ?: @"nil",
        @"children": children,
        @"parents": ParentChain(view)
    };
}

static void CollectViews(UIView *view, NSMutableDictionary *result)
{
    if (IsTargetView(view)) {
        result[ViewKey(view)] = StateForView(view);
    }

    for (UIView *subview in view.subviews) {
        CollectViews(subview, result);
    }
}

static NSDictionary *CurrentState(void)
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    if (!gWindow)
        return result;

    CollectViews(gWindow, result);

    return result;
}

static BOOL StateChanged(NSDictionary *a, NSDictionary *b)
{
    if (!a || !b)
        return YES;

    NSArray *keys = @[
        @"frame",
        @"hidden",
        @"alpha",
        @"tint",
        @"selected",
        @"highlighted",
        @"identifier",
        @"label",
        @"value",
        @"children"
    ];

    for (NSString *key in keys) {
        if (![[a[key] description] isEqualToString:[b[key] description]])
            return YES;
    }

    return NO;
}

static void DumpChanges(NSDictionary *before, NSDictionary *after)
{
    WriteLog(@"");
    WriteLog(@"================================");
    WriteLog(@"===== DND STATE CHANGES =====");
    WriteLog(@"================================");

    for (NSString *key in after) {

        NSDictionary *oldState = before[key];
        NSDictionary *newState = after[key];

        if (!StateChanged(oldState,newState))
            continue;

        WriteLog(@"");
        WriteLog([NSString stringWithFormat:@"VIEW %@",key]);

        WriteLog([NSString stringWithFormat:
            @"CLASS=%@",
            newState[@"class"]]);

        WriteLog([NSString stringWithFormat:
            @"FRAME=%@",
            newState[@"frame"]]);

        WriteLog([NSString stringWithFormat:
            @"TINT=%@",
            newState[@"tint"]]);

        WriteLog([NSString stringWithFormat:
            @"SELECTED=%@",
            newState[@"selected"]]);

        WriteLog([NSString stringWithFormat:
            @"HIGHLIGHTED=%@",
            newState[@"highlighted"]]);

        WriteLog([NSString stringWithFormat:
            @"IDENTIFIER=%@",
            newState[@"identifier"]]);

        WriteLog([NSString stringWithFormat:
            @"LABEL=%@",
            newState[@"label"]]);

        WriteLog([NSString stringWithFormat:
            @"VALUE=%@",
            newState[@"value"]]);

        WriteLog([NSString stringWithFormat:
            @"PARENTS=%@",
            newState[@"parents"]]);

        WriteLog(@"CHILDREN:");

        for (NSDictionary *child in newState[@"children"]) {
            WriteLog([NSString stringWithFormat:
                @"  class=%@ frame=%@ tint=%@ image=%@ size=%@",
                child[@"class"],
                child[@"frame"],
                child[@"tint"],
                child[@"image"],
                child[@"size"]]);
        }

        if (oldState) {
            WriteLog(@"--- BEFORE ---");
            WriteLog([NSString stringWithFormat:@"%@",oldState]);
        } else {
            WriteLog(@"--- BEFORE: NONE ---");
        }
    }

    WriteLog(@"");
    WriteLog(@"===== DND STATE CHANGES END =====");
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

    gWindow = window;

    BOOL visible =
        !window.hidden &&
        window.alpha > 0.01;

    if (visible && !gVisible) {

        gBaseline = [CurrentState() mutableCopy];
        gBaselineReady = YES;

        WriteLog(@"");
        WriteLog(@"================================");
        WriteLog(@"===== DND BASELINE CAPTURED =====");
        WriteLog(@"===== NOW CLICK NATIVE DND =====");
        WriteLog(@"================================");
    }

    if (visible && gVisible && gBaselineReady) {

        NSDictionary *current = CurrentState();

        BOOL different = NO;

        for (NSString *key in current) {
            if (StateChanged(gBaseline[key],current[key])) {
                different = YES;
                break;
            }
        }

        if (different) {

            DumpChanges(gBaseline,current);

            gBaselineReady = NO;
        }
    }

    if (!visible && gVisible) {
        gBaselineReady = NO;
        gBaseline = nil;
    }

    gVisible = visible;
}

%ctor
{
    @autoreleasepool {

        WriteLog(@"");
        WriteLog(@"================================");
        WriteLog(@"===== DND PROBE V7 =====");
        WriteLog(@"================================");

        dispatch_async(dispatch_get_main_queue(), ^{

            gTimer = [NSTimer scheduledTimerWithTimeInterval:0.15
                                                       repeats:YES
                                                         block:^(NSTimer *timer) {
                Check();
            }];

            WriteLog(@"===== V7 READY =====");
        });
    }
}