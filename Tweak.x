#import <UIKit/UIKit.h>

// 声明 iOS 16 CCUI 内部私有接口
@interface CCUIRoundButtonViewController : UIViewController
@property (nonatomic, copy) NSString *title;
- (void)setImage:(UIImage *)image;
@end

@interface CCUILowPowerModeModuleViewController : UIViewController
- (CCUIRoundButtonViewController *)buttonViewController;
- (void)updateCowbellUI;
@end

%hook CCUILowPowerModeModuleViewController

- (void)viewDidLoad {
    %orig;

    // 开启设备电量监听
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(updateCowbellUI) 
                                                 name:UIDeviceBatteryLevelDidChangeNotification 
                                               object:nil];
                                               
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(updateCowbellUI) 
                                                 name:UIDeviceBatteryStateDidChangeNotification 
                                               object:nil];

    [self updateCowbellUI];
}

%new
- (void)updateCowbellUI {
    float level = [UIDevice currentDevice].batteryLevel;
    int batteryPercent = (int)roundf(level * 100);
    if (batteryPercent < 0) batteryPercent = 0;

    // 1. 获取按钮控制器
    CCUIRoundButtonViewController *btnVC = nil;
    if ([self respondsToSelector:@selector(buttonViewController)]) {
        btnVC = [self buttonViewController];
    } else {
        btnVC = (CCUIRoundButtonViewController *)self;
    }

    if (!btnVC) return;

    // 2. 更新下方标题为百分比数字
    btnVC.title = [NSString stringWithFormat:@"%d%%", batteryPercent];

    // 3. iOS 16 SF Symbols 动态图标匹配
    NSString *symbolName = @"battery.100";
    if (batteryPercent <= 15) {
        symbolName = @"battery.0";
    } else if (batteryPercent <= 40) {
        symbolName = @"battery.25";
    } else if (batteryPercent <= 65) {
        symbolName = @"battery.50";
    } else if (batteryPercent <= 85) {
        symbolName = @"battery.75";
    }

    // 判断充电状态
    UIDeviceBatteryState state = [UIDevice currentDevice].batteryState;
    if (state == UIDeviceBatteryStateCharging || state == UIDeviceBatteryStateFull) {
        symbolName = [symbolName stringByAppendingString:@".bolt"];
    }

    // 渲染 SF Symbol 强行替换模块 Icon
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleLarge];
    UIImage *batteryIcon = [UIImage systemImageNamed:symbolName withConfiguration:config];

    if (batteryIcon && [btnVC respondsToSelector:@selector(setImage:)]) {
        [btnVC setImage:batteryIcon];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    [self updateCowbellUI];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    %orig;
}

%end
