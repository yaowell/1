#import <UIKit/UIKit.h>
#import <objc/runtime.h>

%ctor {
    NSLog(@"[SimpleCowbell] ===== INJECTED =====");

    int count = objc_getClassList(NULL, 0);

    if (count <= 0) {
        NSLog(@"[SimpleCowbell] objc_getClassList failed");
        return;
    }

    Class *classes = (__unsafe_unretained Class *)malloc(sizeof(Class) * count);

    int realCount = objc_getClassList(classes, count);

    NSLog(@"[SimpleCowbell] class count = %d", realCount);

    for (int i = 0; i < realCount; i++) {

        Class cls = classes[i];

        const char *name = class_getName(cls);

        if (!name) {
            continue;
        }

        NSString *className =
            [NSString stringWithUTF8String:name];

        NSString *lower =
            [className lowercaseString];

        if ([lower containsString:@"battery"] ||
            [lower containsString:@"lowpower"] ||
            [lower containsString:@"lowpower"] ||
            [lower containsString:@"controlcenter"] ||
            [lower containsString:@"toggle"]) {

            NSLog(@"[SimpleCowbell] FOUND CLASS: %@",
                  className);
        }
    }

    free(classes);

    NSLog(@"[SimpleCowbell] ===== SCAN DONE =====");
}