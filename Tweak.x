#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface CCUIToggleViewController : UIViewController
@property (nonatomic, retain) id module;
@end

%hook CCUIToggleViewController

- (void)viewDidLoad {
    %orig;

    id module = self.module;

    NSLog(@"[CowbellTest] CCUIToggleViewController = %@", self);
    NSLog(@"[CowbellTest] module = %@", module);
    NSLog(@"[CowbellTest] moduleClass = %@", module ? NSStringFromClass([module class]) : @"nil");

    if ([module isKindOfClass:NSClassFromString(@"CCUILowPowerModule")]) {
        NSLog(@"[CowbellTest] ★ FOUND CCUILowPowerModule ★");
    }
}

%end