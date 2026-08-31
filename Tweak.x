#import <UIKit/UIKit.h>

%hook CCUILowPowerModuleViewController

- (void)viewDidLoad {
    %orig;

    NSLog(@"[SimpleCowbell] ===== CCUILowPowerModuleViewController viewDidLoad =====");

    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:@"SimpleCowbell"
                                            message:@"成功进入 CCUILowPowerModuleViewController"
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:
        [UIAlertAction actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDefault
                               handler:nil]];

    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *vc = self;

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

    NSLog(@"[SimpleCowbell] ===== CCUILowPowerModuleViewController viewWillAppear =====");
}

%end