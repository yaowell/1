#import <UIKit/UIKit.h>

@interface CCUILowPowerModuleViewController : UIViewController
@end

%hook CCUILowPowerModuleViewController

- (void)viewDidLoad {
    %orig;

    NSLog(@"[SimpleCowbell] ===== CCUILowPowerModuleViewController viewDidLoad =====");
    NSLog(@"[SimpleCowbell] self = %@", self);
    NSLog(@"[SimpleCowbell] class = %@", NSStringFromClass([self class]));

    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:@"SimpleCowbell"
                                                message:@"成功 Hook 到 CCUILowPowerModuleViewController"
                                         preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:
            [UIAlertAction actionWithTitle:@"OK"
                                     style:UIAlertActionStyleDefault
                                   handler:nil]];

        UIViewController *vc = (UIViewController *)self;

        while (vc.presentedViewController) {
            vc = vc.presentedViewController;
        }

        [vc presentViewController:alert
                         animated:YES
                       completion:nil];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);

    NSLog(@"[SimpleCowbell] ===== viewWillAppear =====");
    NSLog(@"[SimpleCowbell] self = %@", self);
    NSLog(@"[SimpleCowbell] class = %@", NSStringFromClass([self class]));
}

%end