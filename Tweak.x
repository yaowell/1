%hook CCUIToggleViewController

- (void)viewDidLoad {
    %orig;

    if ([self.module isKindOfClass:NSClassFromString(@"CCUILowPowerModule")]) {
        NSLog(@"[CowbellTest] FOUND CCUILowPowerModule");
    }
}

%end