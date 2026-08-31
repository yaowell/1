#import <UIKit/UIKit.h>

@interface CCUIToggleViewController : UIViewController
@property (nonatomic, retain) id module;
@end

%hook CCUIToggleViewController

- (void)viewDidLoad {
    %orig;

    NSLog(@"[SimpleCowbell] ===== viewDidLoad =====");
    NSLog(@"[SimpleCowbell] class = %@",
          NSStringFromClass([self class]));

    id module = self.module;

    NSLog(@"[SimpleCowbell] module = %@", module);

    if (module) {
        NSLog(@"[SimpleCowbell] module class = %@",
              NSStringFromClass([module class]));
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);

    NSLog(@"[SimpleCowbell] ===== viewWillAppear =====");
    NSLog(@"[SimpleCowbell] class = %@",
          NSStringFromClass([self class]));

    id module = self.module;

    NSLog(@"[SimpleCowbell] module = %@", module);

    if (module) {
        NSLog(@"[SimpleCowbell] module class = %@",
              NSStringFromClass([module class]));
    }
}

- (void)refreshState {
    NSLog(@"[SimpleCowbell] ===== refreshState =====");

    id module = self.module;

    NSLog(@"[SimpleCowbell] module = %@", module);

    if (module) {
        NSLog(@"[SimpleCowbell] module class = %@",
              NSStringFromClass([module class]));
    }

    %orig;
}

%end