#import <UIKit/UIKit.h>

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig(application);

    NSLog(@"[SimpleCowbell TEST] SpringBoard HOOK SUCCESS");
}

%end