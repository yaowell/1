#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

static NSString * const kLogPath =
    @"/var/mobile/Documents/DNDProbe.log";

static void WriteLog(NSString *text)
{
    @autoreleasepool {
        NSString *line =
            [NSString stringWithFormat:@"%@\n", text];

        NSData *data =
            [line dataUsingEncoding:NSUTF8StringEncoding];

        NSFileHandle *file =
            [NSFileHandle fileHandleForWritingAtPath:kLogPath];

        if (!file) {
            [line writeToFile:kLogPath
                   atomically:YES
                     encoding:NSUTF8StringEncoding
                        error:nil];
        } else {
            [file seekToEndOfFile];
            [file writeData:data];
            [file closeFile];
        }
    }
}

static NSString *ColorString(UIColor *color)
{
    if (!color)
        return @"nil";

    CGFloat r = 0;
    CGFloat g = 0;
    CGFloat b = 0;
    CGFloat a = 0;

    UIColor *rgb =
        [color colorUsingColorSpace:
            [UIColorSpace sRGBColorSpace]];

    if ([rgb getRed:&r
              green:&g
               blue:&b
              alpha:&a]) {

        return [NSString stringWithFormat:
            @"RGBA %.4f %.4f %.4f %.4f / #%02X%02X%02X",
            r, g, b, a,
            (unsigned int)(r * 255.0),
            (unsigned int)(g * 255.0),
            (unsigned int)(b * 255.0)];
    }

    return [NSString stringWithFormat:@"%@", color];
}

static void DumpImage(UIImage *image, NSString *name)
{
    if (!image) {
        WriteLog(
            [NSString stringWithFormat:
                @"IMAGE %@ = nil",
                name]
        );
        return;
    }

    WriteLog(
        [NSString stringWithFormat:
            @"IMAGE %@ size=%.1fx%.1f scale=%.1f "
             "renderingMode=%ld",
            name,
            image.size.width,
            image.size.height,
            image.scale,
            (long)image.renderingMode]
    );
}

static void DumpControlCenterViews(void)
{
    dispatch_async(dispatch_get_main_queue(), ^{

        WriteLog(@"===== CC VIEW DUMP BEGIN =====");

        NSArray *windows =
            [UIApplication sharedApplication].windows;

        for (UIWindow *window in windows) {

            NSString *windowClass =
                NSStringFromClass([window class]);

            if ([windowClass rangeOfString:@"ControlCenter"
                                  options:NSCaseInsensitiveSearch].location
                == NSNotFound) {
                continue;
            }

            WriteLog(
                [NSString stringWithFormat:
                    @"WINDOW class=%@ tint=%@ hidden=%d alpha=%.2f",
                    windowClass,
                    ColorString(window.tintColor),
                    window.hidden,
                    window.alpha]
            );

            NSMutableArray *queue =
                [NSMutableArray arrayWithObject:window];

            while (queue.count > 0) {

                UIView *view = queue.firstObject;
                [queue removeObjectAtIndex:0];

                NSString *className =
                    NSStringFromClass([view class]);

                BOOL isCCUI =
                    [className rangeOfString:@"CCUI"
                                    options:NSCaseInsensitiveSearch].location
                    != NSNotFound;

                if (isCCUI) {

                    NSString *extra = @"";

                    if ([view isKindOfClass:[UIImageView class]]) {

                        UIImageView *imageView =
                            (UIImageView *)view;

                        UIImage *image =
                            imageView.image;

                        extra =
                            [NSString stringWithFormat:
                                @" image=%p imageMode=%ld",
                                image,
                                (long)image.renderingMode];

                        if (image) {
                            DumpImage(
                                image,
                                [NSString stringWithFormat:
                                    @"%@.image",
                                    className]
                            );
                        }
                    }

                    WriteLog(
                        [NSString stringWithFormat:
                            @"VIEW class=%@ frame=%@ "
                             "tint=%@ hidden=%d alpha=%.2f%@",
                            className,
                            NSStringFromCGRect(view.frame),
                            ColorString(view.tintColor),
                            view.hidden,
                            view.alpha,
                            extra]
                    );
                }

                for (UIView *subview in view.subviews) {
                    [queue addObject:subview];
                }
            }
        }

        WriteLog(@"===== CC VIEW DUMP END =====");
    });
}

static void ProbeToggleState(id object, BOOL selected)
{
    NSString *className =
        NSStringFromClass([object class]);

    WriteLog(
        [NSString stringWithFormat:
            @"===== setSelected: class=%@ selected=%d =====",
            className,
            selected]
    );

    SEL iconSEL = @selector(iconGlyph);

    if ([object respondsToSelector:iconSEL]) {

        @try {

            UIImage *image =
                ((UIImage *(*)(id, SEL))
                    objc_msgSend)(
                        object,
                        iconSEL
                    );

            DumpImage(
                image,
                [NSString stringWithFormat:
                    @"%@ iconGlyph",
                    className]
            );

        }
        @catch (NSException *exception) {

            WriteLog(
                [NSString stringWithFormat:
                    @"iconGlyph EXCEPTION: %@",
                    exception]
            );
        }
    } else {
        WriteLog(@"iconGlyph NOT FOUND");
    }

    DumpControlCenterViews();

    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            (int64_t)(0.15 * NSEC_PER_SEC)
        ),
        dispatch_get_main_queue(),
        ^{

            WriteLog(
                [NSString stringWithFormat:
                    @"===== 150ms AFTER selected=%d =====",
                    selected]
            );

            DumpControlCenterViews();
        }
    );

    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            (int64_t)(0.50 * NSEC_PER_SEC)
        ),
        dispatch_get_main_queue(),
        ^{

            WriteLog(
                [NSString stringWithFormat:
                    @"===== 500ms AFTER selected=%d =====",
                    selected]
            );

            DumpControlCenterViews();
        }
    );
}

%hook CCUIToggleModule

- (void)setSelected:(BOOL)selected
{
    ProbeToggleState(self, selected);

    %orig;
}

%end

%ctor
{
    @autoreleasepool {

        WriteLog(@"");
        WriteLog(@"================================");
        WriteLog(@"===== DND PROBE LOADED =====");
        WriteLog(@"================================");

        Class toggleClass =
            objc_getClass("CCUIToggleModule");

        if (toggleClass) {
            WriteLog(@"CCUIToggleModule FOUND");
        } else {
            WriteLog(@"CCUIToggleModule NOT FOUND");
        }

        Class dndClass =
            objc_getClass("CCUIDoNotDisturbModule");

        if (dndClass) {
            WriteLog(
                [NSString stringWithFormat:
                    @"CCUIDoNotDisturbModule FOUND: %@",
                    NSStringFromClass(dndClass)]
            );
        } else {
            WriteLog(
                @"CCUIDoNotDisturbModule NOT FOUND"
            );
        }

        WriteLog(@"===== DND PROBE READY =====");
    }
}