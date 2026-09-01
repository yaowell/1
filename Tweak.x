#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface CCUICAPackageView : UIView
@property (nonatomic, copy) NSString *packageName;
@end

%hook CCUICAPackageView

- (void)layoutSubviews {
    %orig;

    NSLog(@"[CCProbe] ===== CCUICAPackageView =====");
    NSLog(@"[CCProbe] self = %@", self);
    NSLog(@"[CCProbe] class = %@", NSStringFromClass([self class]));
    NSLog(@"[CCProbe] packageName = %@", self.packageName);
    NSLog(@"[CCProbe] window = %@", self.window);

    for (UIView *subview in self.subviews) {
        NSLog(@"[CCProbe] subview = %@ | class = %@ | tag = %ld",
              subview,
              NSStringFromClass([subview class]),
              (long)subview.tag);
    }

    NSLog(@"[CCProbe] ============================");
}

%end