#import <UIKit/UIKit.h>

%hook CCUICAPackageView

- (void)didMoveToWindow {
    %orig;

    if (!self.window) return;

    NSLog(@"[CCProbe] ===== CCUICAPackageView =====");
    NSLog(@"[CCProbe] self = %@", (UIView *)self);
    NSLog(@"[CCProbe] class = %@", NSStringFromClass([(UIView *)self class]));

    UIView *view = (UIView *)self;

    if ([view respondsToSelector:@selector(packageName)]) {
        NSLog(@"[CCProbe] packageName = %@", 
              [view valueForKey:@"packageName"]);
    }

    UIResponder *r = (UIResponder *)view;

    for (int i = 0; r && i < 20; i++) {

        NSLog(@"[CCProbe] responder[%d] = %@ | class = %@",
              i,
              r,
              NSStringFromClass([r class]));

        r = [r nextResponder];
    }

    NSLog(@"[CCProbe] ===============================");
}

%end