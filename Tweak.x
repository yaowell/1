#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <string.h>

__attribute__((constructor))
static void CCProbeInit(void) {
    @autoreleasepool {
        unsigned int count = 0;
        Class *classes = objc_copyClassList(&count);

        NSLog(@"[CCProbe] ===== START =====");
        NSLog(@"[CCProbe] Runtime class count: %u", count);

        if (classes) {
            for (unsigned int i = 0; i < count; i++) {
                const char *name = class_getName(classes[i]);

                if (!name) {
                    continue;
                }

                if (strcasestr(name, "LowPower") ||
                    strcasestr(name, "Battery") ||
                    strcasestr(name, "ControlCenter") ||
                    strcasestr(name, "CCUI")) {

                    NSLog(@"[CCProbe] CLASS: %s", name);
                }
            }

            free(classes);
        }

        NSLog(@"[CCProbe] ===== END =====");
    }
}