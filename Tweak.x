#import <UIKit/UIKit.h>

%ctor {
    NSLog(@"[SimpleCowbell] >>> LOADED <<<");
    
    UIAlertController *alert =
        [UIAlertController
            alertControllerWithTitle:@"SimpleCowbell"
            message:@"Tweak 已成功加载到 SpringBoard"
            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:
        [UIAlertAction
            actionWithTitle:@"OK"
            style:UIAlertActionStyleDefault
            handler:nil]];

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = nil;

        if (@available(iOS 13.0, *)) {
            for (UIScene *scene in
                 [UIApplication sharedApplication].connectedScenes) {

                if (scene.activationState ==
                    UISceneActivationStateForegroundActive) {

                    if ([scene isKindOfClass:[UIWindowScene class]]) {
                        window =
                            ((UIWindowScene *)scene).windows.firstObject;
                    }

                    if (window) {
                        break;
                    }
                }
            }
        }

        if (!window) {
            return;
        }

        UIViewController *vc =
            window.rootViewController;

        while (vc.presentedViewController) {
            vc = vc.presentedViewController;
        }

        [vc presentViewController:alert
                         animated:YES
                       completion:nil];
    });
}