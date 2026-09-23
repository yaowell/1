#import <Foundation/Foundation.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <notify.h>

static int gToken = 0;

static void ToggleRecording(void) {
    Class cls = objc_getClass("AudioRecorderController");

    if (!cls) {
        return;
    }

    SEL sharedSel = @selector(sharedInstance);
    SEL toggleSel = @selector(toggleRecordingFromMic:);

    if (![cls respondsToSelector:sharedSel]) {
        return;
    }

    id controller = ((id (*)(id, SEL))objc_msgSend)(cls, sharedSel);

    if (!controller) {
        return;
    }

    if (![controller respondsToSelector:toggleSel]) {
        return;
    }

    ((void (*)(id, SEL, id))objc_msgSend)(
        controller,
        toggleSel,
        nil
    );
}

%ctor {
    Class cls = objc_getClass("AudioRecorderController");

    if (!cls) {
        return;
    }

    notify_register_dispatch(
        "net.yaowell.audiorecorder.toggle",
        &gToken,
        dispatch_get_main_queue(),
        ^(int token) {
            ToggleRecording();
        }
    );
}