#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface CCUICAPackageView : UIView
@property (nonatomic, copy) NSString *packageName;
@end

%hook CCUICAPackageView

- (void)didMoveToWindow {
    %orig;

    if (!self.window) return;

    NSString *className = NSStringFromClass([self class]);
    NSString *superName = NSStringFromClass([self superclass]);
    NSString *packageName = @"";

    if ([self respondsToSelector:@selector(packageName)]) {
        packageName = self.packageName ?: @"";
    }

    NSLog(@"[CowbellProbe] ========================");
    NSLog(@"[CowbellProbe] class       = %@", className);
    NSLog(@"[CowbellProbe] superclass  = %@", superName);
    NSLog(@"[CowbellProbe] packageName = %@", packageName);

    UIResponder *r = self;
    int level = 0;

    while (r && level < 12) {
        NSLog(@"[CowbellProbe] responder[%d] = %@",
              level,
              NSStringFromClass([r class]));

        r = [r nextResponder];
        level++;
    }

    NSLog(@"[CowbellProbe] ========================");
}

%end