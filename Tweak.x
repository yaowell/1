#import <UIKit/UIKit.h>
#import <objc/runtime.h>

%hook CCUICAPackageView

- (void)didMoveToWindow {
    %orig;

    if (!self.window) return;

    NSLog(@"[CCProbe] ===== CCUICAPackageView =====");
    NSLog(@"[CCProbe] self = %@", self);
    NSLog(@"[CCProbe] class = %@", NSStringFromClass([self class]));

    if ([self respondsToSelector:@selector(packageName)]) {
        NSLog(@"[CCProbe] packageName = %@", self.packageName);
    }

    UIResponder *r = self;

    for (int i = 0; r && i < 15; i++) {
        NSLog(@"[CCProbe] responder[%d] = %@ | class=%@",
              i,
              r,
              NSStringFromClass([r class]));

        r = [r nextResponder];
    }

    NSLog(@"[CCProbe] ===========================");
}

%end