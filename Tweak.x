#import <UIKit/UIKit.h>

%hook CCUIToggleViewController

- (void)viewDidLoad {
    NSLog(@"[SimpleCowbell] >>> CCUIToggleViewController viewDidLoad");
    %orig;
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"[SimpleCowbell] >>> CCUIToggleViewController viewWillAppear");
    %orig(animated);
}

- (void)refreshState {
    NSLog(@"[SimpleCowbell] >>> CCUIToggleViewController refreshState");
    %orig;
}

%end