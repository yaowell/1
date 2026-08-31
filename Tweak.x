#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static void WriteResult(NSString *text) {
    NSString *path = @"/var/mobile/Documents/SimpleCowbell_Classes.txt";
    [text writeToFile:path
           atomically:YES
             encoding:NSUTF8StringEncoding
                error:nil];
}

%ctor {

    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
        dispatch_get_main_queue(),
        ^{

            NSMutableString *result =
                [NSMutableString string];

            [result appendString:
                @"=== SimpleCowbell Runtime Test ===\n\n"];

            NSArray *classes = @[
                @"CCUIToggleViewController",
                @"CCUILowPowerModule",
                @"CCUICAPackageView",
                @"_UIBatteryView",
                @"CCUIControlCenterViewController",
                @"SBControlCenterController"
            ];

            for (NSString *name in classes) {

                Class cls =
                    NSClassFromString(name);

                [result appendFormat:
                    @"CLASS %@ = %@\n",
                    name,
                    cls ? @"FOUND" : @"NOT FOUND"
                ];

                if (cls) {

                    [result appendFormat:
                        @"  superclass = %@\n",
                        NSStringFromClass(
                            class_getSuperclass(cls)
                        )
                    ];

                    unsigned int count = 0;

                    Method *methods =
                        class_copyMethodList(
                            cls,
                            &count
                        );

                    [result appendFormat:
                        @"  methods = %u\n",
                        count
                    ];

                    BOOL hasViewDidLoad = NO;
                    BOOL hasViewWillAppear = NO;
                    BOOL hasRefreshState = NO;
                    BOOL hasContentViewController = NO;

                    for (unsigned int i = 0;
                         i < count;
                         i++) {

                        SEL sel =
                            method_getName(methods[i]);

                        NSString *selName =
                            NSStringFromSelector(sel);

                        if ([selName
                            isEqualToString:@"viewDidLoad"]) {

                            hasViewDidLoad = YES;
                        }

                        if ([selName
                            isEqualToString:@"viewWillAppear:"]) {

                            hasViewWillAppear = YES;
                        }

                        if ([selName
                            isEqualToString:@"refreshState"]) {

                            hasRefreshState = YES;
                        }

                        if ([selName
                            isEqualToString:@"contentViewController"]) {

                            hasContentViewController = YES;
                        }
                    }

                    free(methods);

                    [result appendFormat:
                        @"  viewDidLoad = %@\n",
                        hasViewDidLoad ? @"YES" : @"NO"
                    ];

                    [result appendFormat:
                        @"  viewWillAppear = %@\n",
                        hasViewWillAppear ? @"YES" : @"NO"
                    ];

                    [result appendFormat:
                        @"  refreshState = %@\n",
                        hasRefreshState ? @"YES" : @"NO"
                    ];

                    [result appendFormat:
                        @"  contentViewController = %@\n",
                        hasContentViewController ? @"YES" : @"NO"
                    ];
                }

                [result appendString:@"\n"];
            }

            WriteResult(result);
        }
    );
}