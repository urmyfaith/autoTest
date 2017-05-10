//
//  MeasureViewController.m
//  Mavic
//
//  Created by zhangxiaoqiang on 2017/4/4.
//  Copyright © 2017年 LoHas-Tech. All rights reserved.
//

#include <sys/time.h>
#import "MeasureViewController.h"
#import "DevicesViewController.h"
#import "SettingViewController.h"
#import "MViewController.h"
#import "LoginManager.h"
#import "YYKit.h"
#import "LoginApi.h"
#import "MainView.h"
#import "CommonEntities.h"
#import "DevicesApi.h"
#import "DeviceManager.h"
#import "MeasureProtocol.h"
#import "L_T_MeasureProtocol.h"
#import "MBProgressHUD.h"
#import "MeasureManager.h"
#import "ViewController.h"
#import "CheckByte_XOR.h"
#import "UIImage+memory.h"

#import "LockSignal.h"


typedef enum : NSUInteger {
    AidPosition_LT,
    AidPosition_RT,
    AidPosition_LB,
    AidPosition_RB
} AidPosition;

@interface MeasureViewController ()<BLEManagerDelegate, MBProgressHUDDelegate>
{
//    NSTimer *_popDataTimer;
    BOOL isRevData;
    BOOL isStartOrderResponse_L_T;
    BOOL isStartOrderResponse_L_B;
    BOOL isStartOrderResponse_R_T;
    BOOL isStartOrderResponse_R_B;
    
    UIImage *aid_nobind;
    UIImage *aid_unconnected;
    UIImage *aid_connected;
    
    // 包序列
    NSInteger lt_num;
    NSInteger lb_num;
    NSInteger rt_num;
    NSInteger rb_num;
    
    BOOL         isNeedACounter;
    NSInteger    counter;
}
@property (nonatomic, strong) MainView     *mainView;
@property (nonatomic, strong) DevicesApi   *api;
@property (nonatomic, strong) LoginApi     *loginApi;

@property (nonatomic, strong) Peripheral     *L_B_Peripheral;
@property (nonatomic, strong) Peripheral     *R_B_Peripheral;
@property (nonatomic, strong) Peripheral     *L_T_Peripheral;
@property (nonatomic, strong) Peripheral     *R_T_Peripheral;

//@property (nonatomic, strong) CBPeripheral   *L_B_CB_Peripheral;
//@property (nonatomic, strong) CBPeripheral   *R_B_CB_Peripheral;
//@property (nonatomic, strong) CBPeripheral   *L_T_CB_Peripheral;
//@property (nonatomic, strong) CBPeripheral   *R_T_CB_Peripheral;

@property (nonatomic, strong) MeasureProtocol     *protocol;

@property (nonatomic, strong) MBProgressHUD   *hud;


@property (nonatomic, strong) MViewController *home;
@property (nonatomic, strong) ViewController  *mainVC;


@property (nonatomic, strong) MeasureManager *measureManager;
@property (nonatomic, strong) DeviceManager  *deviceManager;

//@property (nonatomic, strong) CBCharacteristic   *L_B_CB_Characteristic;
//@property (nonatomic, strong) CBCharacteristic   *R_B_CB_Characteristic;
//@property (nonatomic, strong) CBCharacteristic   *L_T_CB_Characteristic;
//@property (nonatomic, strong) CBCharacteristic   *R_T_CB_Characteristic;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) LockSignal *ls;

@end

@implementation MeasureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = UIColorHex(eef8fa);
    
    [BLEMANAGER setDelegate:self.protocol];
    // 开始测量按钮
    [self.mainView.startBtn addTarget:self
                               action:@selector(startMeasure:)
                     forControlEvents:UIControlEventTouchUpInside];
    // 四路贴片连接按钮
    [self.mainView.L_T_AidBtn addTarget:self
                                 action:@selector(L_T_AidBtnDidClicked:)
                       forControlEvents:UIControlEventTouchUpInside];
    [self.mainView.R_T_AidBtn addTarget:self
                                 action:@selector(R_T_AidBtnDidClicked:)
                       forControlEvents:UIControlEventTouchUpInside];
    [self.mainView.L_B_AidBtn addTarget:self
                                 action:@selector(L_B_AidBtnDidClicked:)
                       forControlEvents:UIControlEventTouchUpInside];
    [self.mainView.R_B_AidBtn addTarget:self
                                 action:@selector(R_B_AidBtnDidClicked:)
                       forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.mainView.deviceListView.lt_bind addTarget:self action:@selector(lt_aid_bind:) forControlEvents:UIControlEventTouchUpInside];
    [self.mainView.deviceListView.rt_bind addTarget:self action:@selector(rt_aid_bind:) forControlEvents:UIControlEventTouchUpInside];
    [self.mainView.deviceListView.lb_bind addTarget:self action:@selector(lb_aid_bind:) forControlEvents:UIControlEventTouchUpInside];
    [self.mainView.deviceListView.rb_bind addTarget:self action:@selector(rb_aid_bind:) forControlEvents:UIControlEventTouchUpInside];

    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(runtimer) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
    

    [self.mainView.addUserView.saveInfoBtn addTarget:self action:@selector(saveInfoBtnDidClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    // 通知
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserverForName:AddUserNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        
        [UIView animateWithDuration:0.35 animations:^{
            self.mainView.addUserView.hidden = NO;
        }];
        
    }];
    
    // 进入『设备』界面
    [center addObserverForName:@"DeviceListNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        
        [[DeviceManager defaultManager] getHardwareVersion:^(NSString *version) {
            self.mainView.deviceListView.hardware.text = version;
        }];
        
        self.mainView.startBtn.hidden = YES;
        self.mainView.layerAnimaView.hidden = YES;
        self.mainView.L_T_AidBtn.userInteractionEnabled = NO;
        self.mainView.L_B_AidBtn.userInteractionEnabled = NO;
        self.mainView.R_T_AidBtn.userInteractionEnabled = NO;
        self.mainView.R_B_AidBtn.userInteractionEnabled = NO;
        [UIView animateWithDuration:0.35 animations:^{
            self.mainView.deviceListView.hidden = NO;
            [self.mainView.deviceListView reloadAllData];
        }];
        
    }];
    
    // 进入『测量』界面
    [center addObserverForName:@"MeasureNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        self.mainView.startBtn.hidden = NO;
        self.mainView.layerAnimaView.hidden = NO;
        self.mainView.L_T_AidBtn.userInteractionEnabled = YES;
        self.mainView.L_B_AidBtn.userInteractionEnabled = YES;
        self.mainView.R_T_AidBtn.userInteractionEnabled = YES;
        self.mainView.R_B_AidBtn.userInteractionEnabled = YES;
        [UIView animateWithDuration:0.35 animations:^{
            self.mainView.deviceListView.hidden = YES;
            
        }];
        
    }];
    
    // 退出登录
    [center addObserverForName:LogoutNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        
    }];
    
    // 清上一个控制器
    [center addObserverForName:PopPreViewController object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        _home = nil;
    }];
    
    // 重新测量
    [center addObserverForName:ReMeasureNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [self startMeasure:self.mainView.startBtn];
    }];
    

    aid_nobind = [UIImage imageNamed:@"aid_nobind"];
    aid_unconnected = [UIImage imageNamed:@"aid_unconnected"];
    aid_connected = [UIImage imageNamed:@"aid_connected"];
    
    _ls = [[LockSignal alloc] init];
    
    lt_num = 0;
    lb_num = 0;
    rb_num = 0;
    rt_num = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!_L_B_Peripheral) {
        _L_B_Peripheral = [DeviceManager defaultManager].L_B_Aid;
        _L_B_Peripheral.state = CBPeripheralStateDisconnected;
        
    }
    if (!_R_B_Peripheral) {
        _R_B_Peripheral = [DeviceManager defaultManager].R_B_Aid;
        _R_B_Peripheral.state = CBPeripheralStateDisconnected;
        
    }
    if (!_L_T_Peripheral) {
        _L_T_Peripheral = [DeviceManager defaultManager].L_T_Aid;
        _L_T_Peripheral.state = CBPeripheralStateDisconnected;
        
    }
    if (!_R_T_Peripheral) {
        _R_T_Peripheral = [DeviceManager defaultManager].R_T_Aid;
        _R_T_Peripheral.state = CBPeripheralStateDisconnected;
        
    }
    
    
    [self updateAidStatus];
    [self addUserInfoView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    [self rescanPeripherals];
    
}

- (void)addUserInfoView {
    LoginManager *lm = [LoginManager defaultManager];
    if (!lm.currentPatient) {
        [lm getLastPatientInfo];
    }
    
    if (lm.currentPatient) {
        self.mainView.addUserView.isAddedPatient = YES;
        self.mainView.addUserView.currentPatient = lm.currentPatient;

        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center postNotificationName:HeadIconDidChangeNotification object:lm.currentPatient.gender];
        
    }
    else {
        self.mainView.addUserView.isAddedPatient = NO;
        self.mainView.addUserView.currentPatient = nil;
        
        // 默认登录时的手机号
        [[LoginManager defaultManager] getLastUserInfo];
        self.mainView.addUserView.phoneText.text = [LoginManager defaultManager].currentUser.mobile;
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center postNotificationName:HeadIconDidChangeNotification object:nil];
    }

}

- (void)updateAidStatus {
    if (!_L_B_Peripheral) {
        self.mainView.L_B_AidBtn.imageView.image = aid_nobind;
    }
    else {
        self.mainView.L_B_AidBtn.imageView.image = aid_unconnected;
        // 本地外设状态还原
        [self.api saveCurrentPeripheral:_L_B_Peripheral];
    }
    if (!_R_B_Peripheral) {
        self.mainView.R_B_AidBtn.imageView.image = aid_nobind;
    }
    else {
        self.mainView.R_B_AidBtn.imageView.image = aid_unconnected;
        // 本地外设状态还原
        [self.api saveCurrentPeripheral:_R_B_Peripheral];
    }
    if (!_L_T_Peripheral) {
        self.mainView.L_T_AidBtn.imageView.image = aid_nobind;
    }
    else {
        self.mainView.L_T_AidBtn.imageView.image = aid_unconnected;
        // 本地外设状态还原
        [self.api saveCurrentPeripheral:_L_T_Peripheral];
    }
    if (!_R_T_Peripheral) {
        self.mainView.R_T_AidBtn.imageView.image = aid_nobind;
    }
    else {
        self.mainView.R_T_AidBtn.imageView.image = aid_unconnected;
        // 本地外设状态还原
        [self.api saveCurrentPeripheral:_R_T_Peripheral];
    }
}

- (void)rescanPeripherals:(Location)location {
    [BLEMANAGER stopScan];
    [BLEMANAGER setDelegate:nil];
    switch (location) {
        case L_T_Aid: {
            self.protocol.L_T_Peripheral = _L_T_Peripheral;
            [BLEMANAGER setDelegate:self.protocol];
            [BLEMANAGER scanForPeripherals:nil];
            
            __weak typeof(self) myself = self;
            self.protocol.didFoundPeripheral = ^(CBPeripheral *peripheral, Location location) {
                EZLog(@"+++++++++++++++");
                EZLog(@"%@", peripheral);
                switch (location) {
                    case L_T_Aid: {
//                        _L_T_CB_Peripheral = peripheral;
                        myself.deviceManager.L_T_CB_Peripheral = peripheral;
                        [BLEMANAGER stopScan];
                        [BLEMANAGER setDelegate:myself];
                        [BLEMANAGER connect:peripheral];
                        break;
                    }
                    case R_T_Aid: {
                        myself.deviceManager.R_T_CB_Peripheral = peripheral;
//                        [DeviceManager defaultManager].R_T_CB_Peripheral = peripheral;
                        break;
                    }
                    case L_B_Aid: {
                        myself.deviceManager.L_B_CB_Peripheral = peripheral;
//                        [DeviceManager defaultManager].L_B_CB_Peripheral = peripheral;
                        break;
                    }
                    case R_B_Aid: {
//                        _R_B_CB_Peripheral = peripheral;
                        myself.deviceManager.R_B_CB_Peripheral = peripheral;
                        break;
                    }
                    default:
                        break;
                }
                
                
            };
            break;
        }
        case R_T_Aid: {
            self.protocol.R_T_Peripheral = _R_T_Peripheral;
            [BLEMANAGER setDelegate:self.protocol];
            [BLEMANAGER scanForPeripherals:nil];
            
            __weak typeof(self) myself = self;
            self.protocol.didFoundPeripheral = ^(CBPeripheral *peripheral, Location location) {
                EZLog(@"+++++++++++++++");
                EZLog(@"%@", peripheral);
                switch (location) {
                    case L_T_Aid: {
//                        _L_T_CB_Peripheral = peripheral;
                        myself.deviceManager.L_T_CB_Peripheral = peripheral;
                        break;
                    }
                    case R_T_Aid: {
                        myself.deviceManager.R_T_CB_Peripheral = peripheral;
                        [DeviceManager defaultManager].R_T_CB_Peripheral = peripheral;
                        [BLEMANAGER stopScan];
                        [BLEMANAGER setDelegate:myself];
                        [BLEMANAGER connect:peripheral];
                        break;
                    }
                    case L_B_Aid: {
                        myself.deviceManager.L_B_CB_Peripheral = peripheral;
//                        [DeviceManager defaultManager].L_B_CB_Peripheral = peripheral;
                        break;
                    }
                    case R_B_Aid: {
//                        _R_B_CB_Peripheral = peripheral;
                        myself.deviceManager.R_B_CB_Peripheral = peripheral;
                        break;
                    }
                    default:
                        break;
                }

                
            };
            break;
        }
        case L_B_Aid: {
            self.protocol.L_B_Peripheral = _L_B_Peripheral;
            [BLEMANAGER setDelegate:self.protocol];
            [BLEMANAGER scanForPeripherals:nil];
            
            __weak typeof(self) myself = self;
            self.protocol.didFoundPeripheral = ^(CBPeripheral *peripheral, Location location) {
                EZLog(@"+++++++++++++++");
                EZLog(@"%@", peripheral);
                switch (location) {
                    case L_T_Aid: {
//                        _L_T_CB_Peripheral = peripheral;
                        myself.deviceManager.L_T_CB_Peripheral = peripheral;
                        break;
                    }
                    case R_T_Aid: {
                        myself.deviceManager.R_T_CB_Peripheral = peripheral;
//                        [DeviceManager defaultManager].R_T_CB_Peripheral = peripheral;
                        break;
                    }
                    case L_B_Aid: {
                        myself.deviceManager.L_B_CB_Peripheral = peripheral;
//                        [DeviceManager defaultManager].L_B_CB_Peripheral = peripheral;
                        [BLEMANAGER stopScan];
                        [BLEMANAGER setDelegate:myself];
                        [BLEMANAGER connect:peripheral];
                        break;
                    }
                    case R_B_Aid: {
//                        _R_B_CB_Peripheral = peripheral;
                        myself.deviceManager.R_B_CB_Peripheral = peripheral;
                        break;
                    }
                    default:
                        break;
                }
                
                
            };
            break;
        }
        case R_B_Aid: {
            self.protocol.R_B_Peripheral = _R_B_Peripheral;
            [BLEMANAGER setDelegate:self.protocol];
            [BLEMANAGER scanForPeripherals:nil];
            
            __weak typeof(self) myself = self;
            self.protocol.didFoundPeripheral = ^(CBPeripheral *peripheral, Location location) {
                EZLog(@"+++++++++++++++");
                EZLog(@"%@", peripheral);
                switch (location) {
                    case L_T_Aid: {
//                        _L_T_CB_Peripheral = peripheral;
                        myself.deviceManager.L_T_CB_Peripheral = peripheral;
                        break;
                    }
                    case R_T_Aid: {
                        myself.deviceManager.R_T_CB_Peripheral = peripheral;
//                        [DeviceManager defaultManager].R_T_CB_Peripheral = peripheral;
                        break;
                    }
                    case L_B_Aid: {
                        myself.deviceManager.L_B_CB_Peripheral = peripheral;
//                        [DeviceManager defaultManager].L_B_CB_Peripheral = peripheral;
                        break;
                    }
                    case R_B_Aid: {
//                        _R_B_CB_Peripheral = peripheral;
                        myself.deviceManager.R_B_CB_Peripheral = peripheral;
                        [BLEMANAGER stopScan];
                        [BLEMANAGER setDelegate:myself];
                        [BLEMANAGER connect:peripheral];
                        break;
                    }
                    default:
                        break;
                }
                
                
            };
            break;
        }
        default:
            break;
    }
    
}

#pragma mark - 定时器
- (void)runtimer {
    NSLog(@"1");
    // 超时情况 计时
    if (isNeedACounter) {
        counter += 1;
        if (counter>=6) {
            [self didConnectPeripheralTimeout];
        }
    }
    
    _L_T_Peripheral.state = self.deviceManager.L_T_CB_Peripheral.state;
    _L_B_Peripheral.state = self.deviceManager.L_B_CB_Peripheral.state;
    _R_T_Peripheral.state = self.deviceManager.R_T_CB_Peripheral.state;
    _R_B_Peripheral.state = self.deviceManager.R_B_CB_Peripheral.state;
    if (_L_T_Peripheral && _L_T_Peripheral.state != CBPeripheralStateConnected) { // 未连接状态
        self.mainView.L_T_AidBtn.imageView.image = aid_unconnected;
    }
    else if (!_L_T_Peripheral) {
        self.mainView.L_T_AidBtn.imageView.image = aid_nobind;
    }
    if (_L_B_Peripheral && _L_B_Peripheral.state != CBPeripheralStateConnected) { // 未连接状态
        self.mainView.L_B_AidBtn.imageView.image = aid_unconnected;
    }
    else if (!_L_B_Peripheral) {
        self.mainView.L_B_AidBtn.imageView.image = aid_nobind;
    }
    if (_R_T_Peripheral && _R_T_Peripheral.state != CBPeripheralStateConnected) { // 未连接状态
        self.mainView.R_T_AidBtn.imageView.image = aid_unconnected;
    }
    else if (!_R_T_Peripheral) {
        self.mainView.R_T_AidBtn.imageView.image = aid_nobind;
    }
    if (_R_B_Peripheral && _R_B_Peripheral.state != CBPeripheralStateConnected) { // 未连接状态
        self.mainView.R_B_AidBtn.imageView.image = aid_unconnected;
    }
    else if (!_R_B_Peripheral) {
        self.mainView.R_B_AidBtn.imageView.image = aid_nobind;
    }
    
    if (!self.mainView.deviceListView.hidden) {
        [self.mainView.deviceListView reloadAllData];
    }
    
}

/*
 ** 重开定时器
 */

- (void)restartTimer {
    if (!_timer.isValid) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(runtimer) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSDefaultRunLoopMode];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

#pragma mark - 预测量
- (void)startMeasure:(UIButton *)sender {
    isRevData = NO;
    NSLog(@"预测量");
    [_timer invalidate];
    _timer = nil;
    
    /* 
     ** 配合压力测试的log日志
     for (NSData *d in self.measureManager.logs) {
         [self writeToFileWithString:d withFileName:@""];
     }
     */
    
    if (!self.mainView.addUserView.isAddedPatient) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"请先完善个人信息";
        [hud hide:YES afterDelay:1];
        return;
    }
    
    // step 1: 判断是否存在未绑定的设备
    if (!_L_T_Peripheral) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"左上肢贴片未绑定";
        [hud hide:YES afterDelay:1];
        return;
    }
    if (!_L_B_Peripheral) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"左下肢贴片未绑定";
        [hud hide:YES afterDelay:1];
        return;
    }
    
    if (!_R_T_Peripheral) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"右上肢贴片未绑定";
        [hud hide:YES afterDelay:1];
        return;
    }
    if (!_R_B_Peripheral) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = @"右下肢贴片未绑定";
        [hud hide:YES afterDelay:1];
        return;
    }
    
    // step 2: 区分已连接和未连接的设备，已连接的设备不做处理
    NSMutableArray *retrievePeraipherals = [NSMutableArray array];
    if (!self.deviceManager.L_T_CB_Peripheral || self.deviceManager.L_T_CB_Peripheral.state != CBPeripheralStateConnected) {
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:_L_T_Peripheral.identifier];
        [retrievePeraipherals addObject:uuid];
    }
    if (!self.deviceManager.L_B_CB_Peripheral || self.deviceManager.L_B_CB_Peripheral.state != CBPeripheralStateConnected) {
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:_L_B_Peripheral.identifier];
        [retrievePeraipherals addObject:uuid];
    }
    if (!self.deviceManager.R_T_CB_Peripheral  || self.deviceManager.R_T_CB_Peripheral.state != CBPeripheralStateConnected) {
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:_R_T_Peripheral.identifier];
        [retrievePeraipherals addObject:uuid];
    }
    if (!self.deviceManager.R_B_CB_Peripheral  || self.deviceManager.R_B_CB_Peripheral.state != CBPeripheralStateConnected) {
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:_R_B_Peripheral.identifier];
        [retrievePeraipherals addObject:uuid];
    }
    NSArray *cb_peripherals = [BLEMANAGER retrievePeripheralsWithIdentifiers:retrievePeraipherals];
    [BLEMANAGER setDelegate:self];
    
    for (CBPeripheral *peripheral in cb_peripherals) {
        if ([peripheral.identifier.UUIDString isEqualToString:_L_T_Peripheral.identifier]) {
            self.deviceManager.L_T_CB_Peripheral = peripheral;
//            [DeviceManager defaultManager].L_T_CB_Peripheral = peripheral;
            [BLEMANAGER connect:peripheral];
            isNeedACounter = YES;
            counter = 0;
        }
        if ([peripheral.identifier.UUIDString isEqualToString:_L_B_Peripheral.identifier]) {
            self.deviceManager.L_B_CB_Peripheral = peripheral;
            [DeviceManager defaultManager].L_B_CB_Peripheral = peripheral;
            [BLEMANAGER connect:self.deviceManager.L_B_CB_Peripheral];
            isNeedACounter = YES;
            counter = 0;
        }
        if ([peripheral.identifier.UUIDString isEqualToString:_R_T_Peripheral.identifier]) {
            self.deviceManager.R_T_CB_Peripheral = peripheral;
//            [DeviceManager defaultManager].R_T_CB_Peripheral = peripheral;
            [BLEMANAGER connect:self.deviceManager.R_T_CB_Peripheral];
            isNeedACounter = YES;
            counter = 0;
        }
        if ([peripheral.identifier.UUIDString isEqualToString:_R_B_Peripheral.identifier]) {
            self.deviceManager.R_B_CB_Peripheral = peripheral;
//            self.deviceManager.R_B_CB_Peripheral = peripheral;
            [BLEMANAGER connect:self.deviceManager.R_B_CB_Peripheral];
            isNeedACounter = YES;
            counter = 0;
        }
        
    }
    
    if (cb_peripherals.count > 0) {
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.labelText = @"正在建立连接";
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [hud hide:YES afterDelay:1];
            // 开始命令
            Byte byte4[] = {0x0a,0x04,0x03,0x00,0x07,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xf0};
            
            NSData *data23 = [NSData dataWithBytes:byte4 length:sizeof(byte4)];
            if (self.deviceManager.L_B_CB_Characteristic && self.deviceManager.R_B_CB_Characteristic && self.deviceManager.R_T_CB_Characteristic &&self.deviceManager.L_T_CB_Characteristic) {//
                NSLog(@"start 0");
                [self.deviceManager.R_B_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.R_B_CB_Characteristic type:1];
                [self.deviceManager.R_T_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.R_T_CB_Characteristic type:1];
                [self.deviceManager.L_B_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.L_B_CB_Characteristic type:1];
                [self.deviceManager.L_T_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.L_T_CB_Characteristic type:1];
                
                // 1次重连
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (!isStartOrderResponse_L_T) {
                        [self.deviceManager.L_T_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.L_T_CB_Characteristic type:1];
                        // 2次重连
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if (!isStartOrderResponse_L_T) {
                                [self.deviceManager.L_T_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.L_T_CB_Characteristic type:1];
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                    if(!isStartOrderResponse_L_T) {
                                        // Exit
                                        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                        hud.mode = MBProgressHUDModeText;
                                        hud.labelText = @"左上肢贴片开始指令响应超时";
                                        [hud hide:YES afterDelay:1];
                                        
                                    }
                                });
                            }
                        });
                    }
                    if (!isStartOrderResponse_L_B) {
                        [self.deviceManager.L_B_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.L_B_CB_Characteristic type:1];
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if (!isStartOrderResponse_L_B) {
                                [self.deviceManager.L_B_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.L_B_CB_Characteristic type:1];
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                    if(!isStartOrderResponse_L_B) {
                                        // Exit
                                        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                        hud.mode = MBProgressHUDModeText;
                                        hud.labelText = @"左下踝贴片开始指令响应超时";
                                        [hud hide:YES afterDelay:1];
                                        
                                    }
                                });
                            }
                        });
                    }
                    if (!isStartOrderResponse_R_T) {
                        [self.deviceManager.R_T_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.R_T_CB_Characteristic type:1];
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if (!isStartOrderResponse_R_T) {
                                [self.deviceManager.R_T_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.R_T_CB_Characteristic type:1];
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                    if(!isStartOrderResponse_R_T) {
                                        // Exit
                                        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                        hud.mode = MBProgressHUDModeText;
                                        hud.labelText = @"右上肢贴片开始指令响应超时";
                                        [hud hide:YES afterDelay:1];
                                        
                                    }
                                });
                            }
                        });
                    }
                    if (!isStartOrderResponse_R_B) {
                        [self.deviceManager.R_B_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.R_B_CB_Characteristic type:1];
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if (!isStartOrderResponse_R_B) {
                                [self.deviceManager.R_B_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.R_B_CB_Characteristic type:1];
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                    if(!isStartOrderResponse_R_B) {
                                        // Exit
                                        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                        hud.mode = MBProgressHUDModeText;
                                        hud.labelText = @"右下踝贴片开始指令响应超时";
                                        [hud hide:YES afterDelay:1];
                                        
                                    }
                                });
                            }
                        });
                    }
                    
                });

            }
            else {
                [self restartTimer];
                return;
            }

        });
    }
    else {
        // 开始命令
        Byte byte4[] = {0x0a,0x04,0x03,0x00,0x07,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xf0};
        
        NSData *data23 = [NSData dataWithBytes:byte4 length:sizeof(byte4)];
        if (self.deviceManager.L_B_CB_Characteristic && self.deviceManager.R_B_CB_Characteristic && self.deviceManager.R_T_CB_Characteristic &&self.deviceManager.L_T_CB_Characteristic) {//
            NSLog(@"start 0");
            [self.deviceManager.R_B_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.R_B_CB_Characteristic type:1];
            [self.deviceManager.R_T_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.R_T_CB_Characteristic type:1];
            [self.deviceManager.L_B_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.L_B_CB_Characteristic type:1];
            [self.deviceManager.L_T_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.L_T_CB_Characteristic type:1];
            // 1次重连
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!isStartOrderResponse_L_T) {
                    [self.deviceManager.L_T_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.L_T_CB_Characteristic type:1];
                    // 2次重连
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (!isStartOrderResponse_L_T) {
                            [self.deviceManager.L_T_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.L_T_CB_Characteristic type:1];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                if(!isStartOrderResponse_L_T) {
                                    // Exit
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                    hud.mode = MBProgressHUDModeText;
                                    hud.labelText = @"左上肢贴片开始指令响应超时";
                                    [hud hide:YES afterDelay:1];
                                    
                                }
                            });
                        }
                    });
                }
                if (!isStartOrderResponse_L_B) {
                    [self.deviceManager.L_B_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.L_B_CB_Characteristic type:1];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (!isStartOrderResponse_L_B) {
                            [self.deviceManager.L_B_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.L_B_CB_Characteristic type:1];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                if(!isStartOrderResponse_L_B) {
                                    // Exit
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                    hud.mode = MBProgressHUDModeText;
                                    hud.labelText = @"左下踝贴片开始指令响应超时";
                                    [hud hide:YES afterDelay:1];
                                    
                                }
                            });
                        }
                    });
                }
                if (!isStartOrderResponse_R_T) {
                    [self.deviceManager.R_T_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.R_T_CB_Characteristic type:1];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (!isStartOrderResponse_R_T) {
                            [self.deviceManager.R_T_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.R_T_CB_Characteristic type:1];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                if(!isStartOrderResponse_R_T) {
                                    // Exit
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                    hud.mode = MBProgressHUDModeText;
                                    hud.labelText = @"右上肢贴片开始指令响应超时";
                                    [hud hide:YES afterDelay:1];
                                    
                                }
                            });
                        }
                    });
                }
                if (!isStartOrderResponse_R_B) {
                    [self.deviceManager.R_B_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.R_B_CB_Characteristic type:1];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (!isStartOrderResponse_R_B) {
                            [self.deviceManager.R_B_CB_Peripheral writeValue:data23 forCharacteristic:self.deviceManager.R_B_CB_Characteristic type:1];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                if(!isStartOrderResponse_R_B) {
                                    // Exit
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                    hud.mode = MBProgressHUDModeText;
                                    hud.labelText = @"右下踝贴片开始指令响应超时";
                                    [hud hide:YES afterDelay:1];
                                    
                                }
                            });
                        }
                    });
                }
                
            });
            
        }
        else {
            [self restartTimer];
            if ([MBProgressHUD allHUDsForView:self.view].count>0) {
                
            }
            else {
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.labelText = @"贴片传输中断，请重新连接";
                [hud hide:YES afterDelay:1];
            }
            return;
        }

    }
}

#pragma mark - 推出预测量页面
- (void)showPreMeasureViewConroller {
    if (isStartOrderResponse_L_T && isStartOrderResponse_L_B && isStartOrderResponse_R_T && isStartOrderResponse_R_B) {//
        if(!_home) {
            [_timer invalidate];
            _timer = nil;
        _home = [[MViewController alloc]
                 init];
        _mainVC = (ViewController *)self.parentViewController;
        for (ViewController *vc in [_mainVC childViewControllers]) {
            if ([vc isKindOfClass:[SettingViewController class]]) {
                vc.view.userInteractionEnabled = NO;
            }
        }
        [self addChildViewController:_home];
        _home.modalPresentationStyle = UIModalPresentationFormSheet;
        _home.preferredContentSize   = CGSizeMake(375, 678);
        _home.view.frame = CGRectMake(_mainVC.view.width, 0, _mainVC.view.width, self.view.height);
        _home.view.backgroundColor = [UIColor whiteColor];
        __weak typeof(self) myself = self;
        _home.uploadBlock = ^{
            myself.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:myself selector:@selector(runtimer) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:myself.timer forMode:NSDefaultRunLoopMode];
            [myself.timer fire];
            for (UIView *v in myself.mainVC.naviBarView.subviews) {
                if ([v isKindOfClass:[UIButton class]]) {
                    v.hidden = YES;
                }
            }
            _home = nil;
        };
        [self.view addSubview:_home.view];
        
        [UIView animateWithDuration:0.35 animations:^{
            _home.view.frame = CGRectMake(-120, 0, _mainVC.view.width, _mainVC.view.height);
        } completion:^(BOOL finished) {
            
        }];
        }
    }
    else {
        [self restartTimer];
    }
}

#pragma mark - 四路外设连接
- (void)L_T_AidBtnDidClicked:(UIButton *)sender {
    if (_L_T_Peripheral && _L_T_Peripheral.state != CBPeripheralStateConnected) { // 未连接状态
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.labelText = @"正在建立连接";
        _hud.delegate = self;
        isNeedACounter = YES; // 需要 判断超时情况 计时
        if (self.deviceManager.L_T_CB_Peripheral) {
            [BLEMANAGER setDelegate:self];
            [BLEMANAGER connect:self.deviceManager.L_T_CB_Peripheral];
        }
        else {
            [self rescanPeripherals:L_T_Aid];
        }
        
    }
    else if (!_L_T_Peripheral) {
        UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        DevicesViewController *deviceVC = [story instantiateViewControllerWithIdentifier:@"device"];
        deviceVC.measureVC = self;
        deviceVC.cpBlock = ^(Peripheral *peripheral, CBPeripheral *cb_peripheral) {
            _L_T_Peripheral          = peripheral;
            _L_T_Peripheral.location = L_T_Aid;
            self.deviceManager.L_T_CB_Peripheral       = cb_peripheral;
//            [DeviceManager defaultManager].L_T_CB_Peripheral = cb_peripheral;
            cb_peripheral.delegate = self;
            [BLEMANAGER discoverServices:cb_peripheral];
            if (_L_T_Peripheral.state == CBPeripheralStateConnected) {
                self.mainView.L_T_AidBtn.imageView.image = aid_connected;
                [DeviceManager defaultManager].L_T_Aid = _L_T_Peripheral;
                [self.api saveCurrentPeripheral:_L_T_Peripheral];
            }
        };
        deviceVC.modalPresentationStyle = UIModalPresentationFormSheet;
        deviceVC.preferredContentSize = CGSizeMake(320, 360);
        [self presentViewController:deviceVC animated:YES completion:^{
            
        }];
    }
}

- (void)R_T_AidBtnDidClicked:(UIButton *)sender {
    if (_R_T_Peripheral && _R_T_Peripheral.state != CBPeripheralStateConnected) { // 未连接状态
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.labelText = @"正在建立连接";
        _hud.delegate = self;
        isNeedACounter = YES; // 需要 判断超时情况 计时
        if (self.deviceManager.R_T_CB_Peripheral) {
            [BLEMANAGER setDelegate:self];
            [BLEMANAGER connect:self.deviceManager.R_T_CB_Peripheral];
        }
        else {
            [self rescanPeripherals:R_T_Aid];
        }
        
    }
    else if (!_R_T_Peripheral) {
        UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        DevicesViewController *deviceVC = [story instantiateViewControllerWithIdentifier:@"device"];
        deviceVC.measureVC = self;
        deviceVC.cpBlock = ^(Peripheral *peripheral, CBPeripheral *cb_peripheral) {
            _R_T_Peripheral          = peripheral;
            _R_T_Peripheral.location = R_T_Aid;
            self.deviceManager.R_T_CB_Peripheral       = cb_peripheral;
//            [DeviceManager defaultManager].R_T_CB_Peripheral = cb_peripheral;
            cb_peripheral.delegate = self;
            [BLEMANAGER discoverServices:cb_peripheral];
            EZLog(@"%@---%@",_L_T_Peripheral, _R_T_Peripheral);
            // 已连接
            if (_R_T_Peripheral.state == CBPeripheralStateConnected) {
                self.mainView.R_T_AidBtn.imageView.image = aid_connected;
                [DeviceManager defaultManager].R_T_Aid = _R_T_Peripheral;
                [self.api saveCurrentPeripheral:_R_T_Peripheral];
            }
        };
        deviceVC.modalPresentationStyle = UIModalPresentationFormSheet;
        deviceVC.preferredContentSize = CGSizeMake(320, 360);
        [self presentViewController:deviceVC animated:YES completion:^{
            
        }];
    }
}

- (void)L_B_AidBtnDidClicked:(UIButton *)sender {
    if (_L_B_Peripheral && _L_B_Peripheral.state != CBPeripheralStateConnected) { // 未连接状态
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.labelText = @"正在建立连接";
        _hud.delegate = self;
        isNeedACounter = YES; // 需要 判断超时情况 计时
        if (self.deviceManager.L_B_CB_Peripheral) {
            [BLEMANAGER setDelegate:self];
            [BLEMANAGER connect:self.deviceManager.L_B_CB_Peripheral];
        }
        else {
            [self rescanPeripherals:L_B_Aid];
        }
    }
    else if (!_L_B_Peripheral) {
        UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        DevicesViewController *deviceVC = [story instantiateViewControllerWithIdentifier:@"device"];
        deviceVC.measureVC = self;
        deviceVC.cpBlock = ^(Peripheral *peripheral, CBPeripheral *cb_peripheral) {
            _L_B_Peripheral          = peripheral;
            _L_B_Peripheral.location = L_B_Aid;
            self.deviceManager.L_B_CB_Peripheral       = cb_peripheral;
            [DeviceManager defaultManager].L_B_CB_Peripheral = cb_peripheral;
            cb_peripheral.delegate = self;
            [BLEMANAGER discoverServices:cb_peripheral];
            if (_L_B_Peripheral.state == CBPeripheralStateConnected) {
                self.mainView.L_B_AidBtn.imageView.image = aid_connected;
                [DeviceManager defaultManager].L_B_Aid = _L_B_Peripheral;
                [self.api saveCurrentPeripheral:_L_B_Peripheral];
            }
            
        };
        deviceVC.modalPresentationStyle = UIModalPresentationFormSheet;
        deviceVC.preferredContentSize = CGSizeMake(320, 360);
        [self presentViewController:deviceVC animated:YES completion:^{
            
        }];
    }
}

- (void)R_B_AidBtnDidClicked:(UIButton *)sender {
    if (_R_B_Peripheral && _R_B_Peripheral.state != CBPeripheralStateConnected) { // 未连接状态
        _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        _hud.labelText = @"正在建立连接";
        _hud.delegate = self;
        isNeedACounter = YES; // 需要 判断超时情况 计时
        if (self.deviceManager.R_B_CB_Peripheral) {
            [BLEMANAGER setDelegate:self];
            [BLEMANAGER connect:self.deviceManager.R_B_CB_Peripheral];
        }
        else {
            [self rescanPeripherals:R_B_Aid];
        }
    }
    else if (!_R_B_Peripheral) {
        UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
        DevicesViewController *deviceVC = [story instantiateViewControllerWithIdentifier:@"device"];
        deviceVC.measureVC = self;
        deviceVC.cpBlock = ^(Peripheral *peripheral, CBPeripheral *cb_peripheral) {
            _R_B_Peripheral          = peripheral;
            _R_B_Peripheral.location = R_B_Aid;
            self.deviceManager.R_B_CB_Peripheral       = cb_peripheral;
//            [DeviceManager defaultManager].R_B_CB_Peripheral = cb_peripheral;
            EZLog(@"%@---%@",_L_B_Peripheral, _R_B_Peripheral);
            cb_peripheral.delegate = self;
            [BLEMANAGER discoverServices:cb_peripheral];
            if (_R_B_Peripheral.state == CBPeripheralStateConnected) {
                self.mainView.R_B_AidBtn.imageView.image = aid_connected;
                [DeviceManager defaultManager].R_B_Aid = _R_B_Peripheral;
                [self.api saveCurrentPeripheral:_R_B_Peripheral];
            }
        };
        deviceVC.modalPresentationStyle = UIModalPresentationFormSheet;
        deviceVC.preferredContentSize = CGSizeMake(320, 360);
        [self presentViewController:deviceVC animated:YES completion:^{
            
        }];
    }
}

#pragma mark - BLEManagerDelegate
- (void) didUpdateState:(CBManagerState) state {
    NSLog(@"[Meassure]BLEManager state changed to %ld", (long)state);
//    [self rescanPeripherals];
}

#pragma mark 发现设备
- (void) didPeripheralFound:(CBPeripheral *)peripheral advertisementData:(BLEAdvertisementData *)advertisementData RSSI:(NSNumber *)RSSI {
    NSLog(@"[Meassure]Device found:%@", peripheral.name);
}

#pragma mark 连接成功
- (void) didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"+++%@[Meassure]Connected", peripheral.name);
    
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    peripheral.delegate = self;
    [BLEMANAGER discoverServices:peripheral];
    if ([_L_T_Peripheral.identifier isEqualToString:peripheral.identifier.UUIDString]) {
        // 超时计数器归零
        isNeedACounter = NO;
        counter = 0;
        
        self.mainView.L_T_AidBtn.imageView.image = aid_connected;
        _L_T_Peripheral.state = CBPeripheralStateConnected;
        self.deviceManager.L_T_CB_Peripheral    = peripheral;
//        [DeviceManager defaultManager].L_T_CB_Peripheral = peripheral;
        [DeviceManager defaultManager].L_T_Aid = _L_T_Peripheral;
        [self.api saveCurrentPeripheral:_L_T_Peripheral];
//        [BLEMANAGER discoverServices:peripheral];
        
    }
    if ([_R_T_Peripheral.identifier isEqualToString:peripheral.identifier.UUIDString]) {
        // 超时计数器归零
        isNeedACounter = NO;
        counter = 0;
        self.mainView.R_T_AidBtn.imageView.image = aid_connected;
        _R_T_Peripheral.state = CBPeripheralStateConnected;
        self.deviceManager.R_T_CB_Peripheral    = peripheral;
//        [DeviceManager defaultManager].R_T_CB_Peripheral = peripheral;
        [DeviceManager defaultManager].R_T_Aid = _R_T_Peripheral;
        [self.api saveCurrentPeripheral:_R_T_Peripheral];
//        [BLEMANAGER discoverServices:peripheral];
        
    }
    if ([_L_B_Peripheral.identifier isEqualToString:peripheral.identifier.UUIDString]) {
        // 超时计数器归零
        isNeedACounter = NO;
        counter = 0;
        self.mainView.L_B_AidBtn.imageView.image = aid_connected;
        _L_B_Peripheral.state = CBPeripheralStateConnected;
        self.deviceManager.L_B_CB_Peripheral    = peripheral;
        [DeviceManager defaultManager].L_B_CB_Peripheral = peripheral;
        [DeviceManager defaultManager].L_B_Aid = _L_B_Peripheral;
        [self.api saveCurrentPeripheral:_L_B_Peripheral];
    }
    if ([_R_B_Peripheral.identifier isEqualToString:peripheral.identifier.UUIDString]) {
        // 超时计数器归零
        isNeedACounter = NO;
        counter = 0;
        self.mainView.R_B_AidBtn.imageView.image = aid_connected;
        _R_B_Peripheral.state = CBPeripheralStateConnected;
        self.deviceManager.R_B_CB_Peripheral    = peripheral;
//        [DeviceManager defaultManager].R_B_CB_Peripheral = peripheral;
        [DeviceManager defaultManager].R_B_Aid = _R_B_Peripheral;
        [self.api saveCurrentPeripheral:_R_B_Peripheral];
    }
}

#pragma mark 连接失败
- (void) didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    NSLog(@"[Meassure]Fail to connect");
}

#pragma mark 连接断开
- (void) didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error {
    NSLog(@"[Meassure]%@Disconnected", peripheral.name);
    if ([peripheral.identifier.UUIDString isEqual:_L_T_Peripheral.identifier]) {
        self.mainView.L_T_AidBtn.imageView.image = aid_unconnected;
        _L_T_Peripheral.state = CBPeripheralStateDisconnected;
        self.deviceManager.L_T_CB_Peripheral    = peripheral;
//        [DeviceManager defaultManager].L_T_CB_Peripheral = peripheral;
        [DeviceManager defaultManager].L_T_Aid = _L_T_Peripheral;
        [self.api saveCurrentPeripheral:_L_T_Peripheral];
    }
    else if ([peripheral.identifier.UUIDString isEqual:_R_T_Peripheral.identifier]) {
        self.mainView.R_T_AidBtn.imageView.image = aid_unconnected;
        _R_T_Peripheral.state = CBPeripheralStateDisconnected;
        self.deviceManager.R_T_CB_Peripheral    = peripheral;
//        [DeviceManager defaultManager].R_T_CB_Peripheral = peripheral;
        [DeviceManager defaultManager].R_T_Aid = _R_T_Peripheral;
        [self.api saveCurrentPeripheral:_R_T_Peripheral];

    }
    else if ([peripheral.identifier.UUIDString isEqual:_L_B_Peripheral.identifier]) {
        self.mainView.L_B_AidBtn.imageView.image = aid_unconnected;
        _L_B_Peripheral.state = CBPeripheralStateDisconnected;
        self.deviceManager.L_B_CB_Peripheral    = peripheral;
        [DeviceManager defaultManager].L_B_CB_Peripheral = peripheral;
        [DeviceManager defaultManager].L_B_Aid = _L_B_Peripheral;
        [self.api saveCurrentPeripheral:_L_B_Peripheral];
    }
    else if ([peripheral.identifier.UUIDString isEqual:_R_B_Peripheral.identifier]) {
        self.mainView.R_B_AidBtn.imageView.image = aid_unconnected;
        _R_B_Peripheral.state = CBPeripheralStateDisconnected;
        self.deviceManager.R_B_CB_Peripheral    = peripheral;
//        [DeviceManager defaultManager].R_B_CB_Peripheral = peripheral;
        [DeviceManager defaultManager].R_B_Aid = _R_B_Peripheral;
        [self.api saveCurrentPeripheral:_R_B_Peripheral];
    }
}

#pragma mark 发现服务
- (void) didServicesFound:(CBPeripheral *)peripheral services:(NSArray<CBPeripheral *> *)services {
    
}

/**
 * 新设备使用*/
- (void)peripheral:(nonnull CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error {
    for (CBService *service in peripheral.services) {
        if ([service.UUID.UUIDString isEqualToString:@"0003CDD0-0000-1000-8000-00805F9B0131"]) {
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
    
}

- (void)peripheral:(nonnull CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(nonnull CBService *)service error:(nullable NSError *)error {
    
    //打开通道
    if ([self.deviceManager.L_T_CB_Peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            //发现特征
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0003CDD1-0000-1000-8000-00805F9B0131"]]) {
                //            NSLog(@"监听：%@",characteristic);//监听特征
                [self.deviceManager.L_T_CB_Peripheral setNotifyValue:YES forCharacteristic:characteristic];
                
            }
            else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0003CDD2-0000-1000-8000-00805F9B0131"]]) {

                self.deviceManager.L_T_CB_Characteristic = characteristic;
                [DeviceManager defaultManager].L_T_CB_Characteristic = characteristic;
            }
            
        }
    }
    if ([self.deviceManager.R_T_CB_Peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            //发现特征
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0003CDD1-0000-1000-8000-00805F9B0131"]]) {
                //            NSLog(@"监听：%@",characteristic);//监听特征
                [self.deviceManager.R_T_CB_Peripheral setNotifyValue:YES forCharacteristic:characteristic];
                
            }
            else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0003CDD2-0000-1000-8000-00805F9B0131"]]) {

                self.deviceManager.R_T_CB_Characteristic = characteristic;
                [DeviceManager defaultManager].R_T_CB_Characteristic = characteristic;
            }
            
        }
    }
    if ([self.deviceManager.L_B_CB_Peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            //发现特征
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0003CDD1-0000-1000-8000-00805F9B0131"]]) {
                //            NSLog(@"监听：%@",characteristic);//监听特征
                [self.deviceManager.L_B_CB_Peripheral setNotifyValue:YES forCharacteristic:characteristic];
                
            }
            else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0003CDD2-0000-1000-8000-00805F9B0131"]]) {

                self.deviceManager.L_B_CB_Characteristic = characteristic;
                [DeviceManager defaultManager].L_B_CB_Characteristic = characteristic;
            }
            
        }
    }
    if ([self.deviceManager.R_B_CB_Peripheral.identifier.UUIDString isEqualToString:peripheral.identifier.UUIDString]) {
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            //发现特征
            if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0003CDD1-0000-1000-8000-00805F9B0131"]]) {
                //            NSLog(@"监听：%@",characteristic);//监听特征
                [self.deviceManager.R_B_CB_Peripheral setNotifyValue:YES forCharacteristic:characteristic];

                
            }
            else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"0003CDD2-0000-1000-8000-00805F9B0131"]]) {

                self.deviceManager.R_B_CB_Characteristic = characteristic;
                [DeviceManager defaultManager].R_B_CB_Characteristic = characteristic;
            }
            
        }
    }
    
}

#pragma mark - 增量写入数据到txt
-(void)writeToFileWithString:(NSData *)string withFileName:(NSString*)fileName{
    //@"Map_Succ.txt"
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *fileName1 = [path stringByAppendingPathComponent:@"125Hz.txt"];
    NSFileManager* fileManager = [NSFileManager defaultManager];

    if ( [fileManager fileExistsAtPath:fileName1]) {

    }
    else {
        [fileManager createFileAtPath:fileName1 contents:nil attributes:nil];
    }

    NSFileHandle *fh = [NSFileHandle fileHandleForUpdatingAtPath:fileName1];
    [fh seekToEndOfFile];
    [fh writeData:string];
    [fh seekToEndOfFile];
    //移动到文件末尾
    [fh writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [fh synchronizeFile];//把数据同步到磁盘, 防止数据丢失
    
}

#pragma mark - 16进制字符串 转 10进制数
- (long long) htoi:(const char *)s
{
    int i;
    int n = 0;
    if (s[0] == '0' && (s[1]=='x' || s[1]=='X'))
    {
        i = 2;
    }
    else
    {
        i = 0;
    }
    for (; (s[i] >= '0' && s[i] <= '9') || (s[i] >= 'a' && s[i] <= 'z') || (s[i] >='A' && s[i] <= 'Z');++i)
    {
        if (tolower(s[i]) > '9')
        {
            n = 16 * n + (10 + tolower(s[i]) - 'a');
        }
        else
        {
            n = 16 * n + (tolower(s[i]) - '0');
        }
    }
    return n;
}

- (void)peripheral:(nonnull CBPeripheral *)peripheral didUpdateValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
    isRevData = YES;
    NSData *revData = characteristic.value;
    Byte *testByte = (Byte *)[revData bytes];
    // 辨别设备
    if ([characteristic.service.peripheral.identifier.UUIDString isEqualToString:[DeviceManager defaultManager].L_T_Aid.identifier]) {
        if ((testByte[0]&0xff)==32) {    // 32 <===> 0x20  指令包
            if (((testByte[2]&0xff)==0)&&((testByte[3]&0xff)==0)) { // 设置不成功或参数非法

            }
            if ((testByte[2]&0xff)==2) { // 2  <===> 0x02  读版本信息
                
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                [center postNotificationName:@"GetVersionNotification" object:revData];
            }
            if ((testByte[2]&0xff)==3) { // 3  <===> 0x03  开始命令
                // 开始命令 得到下位机响应
                isStartOrderResponse_L_T = YES;
                [self showPreMeasureViewConroller];
            }
            if ((testByte[2]&0xff)==4) {
                // 停止命令
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                [center postNotificationName:StopOrderDidResponseNotification object:@(AidPosition_LT)];
            }
            if ((testByte[2]&0xff)==5) { // 5  <===> 0x05  暂停命令
                // 暂停命令 得到下位机响应
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                [center postNotificationName:PauseOrderDidResponseNotification object:@(AidPosition_LT)];
            }
            if ((testByte[2]&0xff)==9) { // 9  <===> 0x09  时间戳查询命令
                // 异或校验 **从字节1到字节17进行异或校验，与字节18比较
                 // 获取时间戳
                    NSString *hex = [NSString stringWithFormat:@"%x", testByte[4]&0xff];
                    if ([hex length] == 1) {
                        hex = [NSString stringWithFormat:@"0%@",hex];
                    }
                    else {
                        
                    }
                    for (int i = 5; i <= 7; i++) {
                        NSString *newHexStr = [NSString stringWithFormat:@"%x", testByte[i]&0xff];
                        if([newHexStr length]==1) {
                            hex = [NSString stringWithFormat:@"%@0%@",hex,newHexStr];
                        }
                        else {
                            hex = [NSString stringWithFormat:@"%@%@",hex,newHexStr];
                        }
                    }
                    long long timestamp = [self htoi:[hex UTF8String]];
                    NSLog(@"%@-%lld", @"LT:", timestamp);
                    // 通过notification 定时开始
                    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                    [center postNotificationName:TimeStampDidResponseNotification object:@[@(timestamp),@(AidPosition_LT)]];
                
            }
            if ((testByte[2]&0xff)==10) { // A <===> 0x0A  定时命令
                // 异或校验 **从字节1到字节17进行异或校验，与字节18比较------
                NSLog(@"LT:%@", characteristic.value);
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                [center postNotificationName:TimeStartDidResponseNotification object:@(AidPosition_LT)];
            }
            return;
        }
        
        
        
        // Byte 转 16进制
        
        NSString *hexStr = [NSString stringWithFormat:@"%x",testByte[0]&0xff];///16进制数
        if ([hexStr length] == 1) {
            hexStr = [NSString stringWithFormat:@"0%@",hexStr];
        }
        else {
            
        }
        
        for(int i=1;i<[revData length];i++) {
            NSString *newHexStr = [NSString stringWithFormat:@"%x",testByte[i]&0xff];///16进制数
            if([newHexStr length]==1) {
                hexStr = [NSString stringWithFormat:@"%@：0%@",hexStr,newHexStr];
            }
            else {
                hexStr = [NSString stringWithFormat:@"%@：%@",hexStr,newHexStr];
            }
        }
        
        // Byte 转 10进制
//        NSString *decStr = [NSString stringWithFormat:@"%d",testByte[0]];///10进制数
        NSMutableArray *by = [NSMutableArray array];
        for(int i=1;i<[revData length];i++) {
            /*
            NSString *newDecStr = [NSString stringWithFormat:@"%d",testByte[i]];///10进制数
            if([newDecStr length]==1) {
                decStr = [NSString stringWithFormat:@"%@,0%@",decStr,newDecStr];
            }
            else {
                decStr = [NSString stringWithFormat:@"%@,%@",decStr,newDecStr];
            }
             */
            if ( (i%20 != 0) && ((i-1)%20 != 0) ) {
                [by addObject:@(testByte[i])];
            }
            else {

            }
            if (i%20==1) {
                NSLog(@"lt_包序列：%@ lt_num:%ld", [NSString stringWithFormat:@"%d",testByte[i]], lt_num);
                if ((testByte[i]) != (lt_num+1)%256) { // > 255?0:lt_num+1
                    NSLog(@"lt_丢包了吧");
                    for (NSInteger i = lt_num+1; i < testByte[i]; i++) {
                        // 丢包补齐
                        if (self.measureManager.lt_q_str.length > 0) {
                            [self.measureManager.lt_q_str appendFormat:@",-%ld", i*100];
                        }
                        else {
                            [self.measureManager.lt_q_str appendFormat:@"-%ld", i*100];
                        }
                        
                        // 丢包补齐
                        if (self.measureManager.lt_i_str.length > 0) {
                            [self.measureManager.lt_i_str appendFormat:@",-%ld", i*100];
                        }
                        else {
                            [self.measureManager.lt_i_str appendFormat:@"-%ld", i*100];
                        }
                    }
                }
                lt_num = testByte[i];
            }
        }
        
        // log txt
        
        NSDateFormatter * formatter = [[NSDateFormatter alloc ] init];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        [formatter setDateFormat:@"YYYY-MM-dd hh:mm:ss:SSSSSS"];
        NSString *date = [formatter stringFromDate:[NSDate date]];
        hexStr = [NSString stringWithFormat:@"%@：%@",date, hexStr];
        NSData *d = [hexStr dataUsingEncoding:NSUTF8StringEncoding];
        [self.measureManager.lt_logs addObject:d];
//        [self writeToFileWithString:d withFileName:@""];
//        EZLog(@"%@--%@", peripheral.identifier.UUIDString, [decStr substringToIndex:15]);
        
        // 数据解析
        BOOL isEcg = YES;
        for(int i=0;i<[by count];i+=3) {
            unsigned int total = 0;
//            total += [by[i] intValue]*256*256;
            total += (([by[i] intValue]&0xff) << 16);
            if (i+1<by.count) {
//                total += [by[i+1] intValue]*256;
                total += (([by[i+1] intValue]&0xff) << 8);
            }
            if (i+2<by.count) {
                total += [by[i+2] intValue];
            }
            
            if (isEcg) { // Q路
                // 用于画波
                [self.measureManager.lt_ecg_list addObject:@(total)];
                // 用于上传
                if (self.measureManager.lt_q_str.length > 0) {
                    [self.measureManager.lt_q_str appendFormat:@",%d",total];
                }
                else {
                    [self.measureManager.lt_q_str appendFormat:@"%d",total];
                }
                
            }
            else {       // I路
                // 用于画波
                [self.measureManager.lt_rf_list addObject:@(total)];
                self.measureManager.lt_quality = [_ls test:total];
                EZLog(@"quality_lt:%d",self.measureManager.lt_quality);
                // 用于上传
                if (self.measureManager.lt_i_str.length > 0) {
                    [self.measureManager.lt_i_str appendFormat:@",%d", total];
                }
                else {
                    [self.measureManager.lt_i_str appendFormat:@"%d",total];
                }
                
            }
            isEcg = !isEcg;
            
        }
    }
    else if ([characteristic.service.peripheral.identifier.UUIDString isEqualToString:[DeviceManager defaultManager].R_T_Aid.identifier]) {
        Byte *testByte = (Byte *)[revData bytes];
        if ((testByte[0]&0xff)==32) {    // 32 <===> 0x20  指令包
            if (((testByte[2]&0xff)==0)&&((testByte[3]&0xff)==0)) { // 设置不成功或参数非法
                
            }
            if ((testByte[2]&0xff)==3) { // 3  <===> 0x03  开始命令
                // 开始命令 得到下位机响应
                isStartOrderResponse_R_T = YES;
                [self showPreMeasureViewConroller];
            }
            if ((testByte[2]&0xff)==4) {
                // 停止命令
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                [center postNotificationName:StopOrderDidResponseNotification object:@(AidPosition_RT)];
            }
            if ((testByte[2]&0xff)==5) { // 5  <===> 0x05  暂停命令
                // 暂停命令 得到下位机响应
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                [center postNotificationName:PauseOrderDidResponseNotification object:@(AidPosition_RT)];
            }
            if ((testByte[2]&0xff)==9) { // 9  <===> 0x09  时间戳查询命令
                // 异或校验 **从字节1到字节17进行异或校验，与字节18比较
                // 获取时间戳
                    NSString *hex = [NSString stringWithFormat:@"%x", testByte[4]&0xff];
                    if ([hex length] == 1) {
                        hex = [NSString stringWithFormat:@"0%@",hex];
                    }
                    else {
                        
                    }
                    for (int i = 5; i <= 7; i++) {
                        NSString *newHexStr = [NSString stringWithFormat:@"%x", testByte[i]&0xff];
                        if([newHexStr length]==1) {
                            hex = [NSString stringWithFormat:@"%@0%@",hex,newHexStr];
                        }
                        else {
                            hex = [NSString stringWithFormat:@"%@%@",hex,newHexStr];
                        }
                    }
                    long long timestamp = [self htoi:[hex UTF8String]];
                    NSLog(@"%@-%lld", @"RT:", timestamp);
                    // 通过notification 定时开始
                    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                    [center postNotificationName:TimeStampDidResponseNotification object:@[@(timestamp), @(AidPosition_RT)]];

            }
            if ((testByte[2]&0xff)==10) { // A <===> 0x0A  定时命令
                // 异或校验 **从字节1到字节17进行异或校验，与字节18比较
                NSLog(@"RT:%@", characteristic.value);
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                [center postNotificationName:TimeStartDidResponseNotification object:@(AidPosition_RT)];
            }
            return;
        }

        // Byte 转 16进制
        
        NSString *hexStr = [NSString stringWithFormat:@"%x",testByte[0]&0xff];///16进制数
        if ([hexStr length] == 1) {
            hexStr = [NSString stringWithFormat:@"0%@",hexStr];
        }
        else {
            
        }
        
        for(int i=1;i<[revData length];i++) {
            NSString *newHexStr = [NSString stringWithFormat:@"%x",testByte[i]&0xff];///16进制数
            if([newHexStr length]==1) {
                hexStr = [NSString stringWithFormat:@"%@：0%@",hexStr,newHexStr];
            }
            else {
                hexStr = [NSString stringWithFormat:@"%@：%@",hexStr,newHexStr];
            }
        }
        
        
        // Byte 转 10进制
//        NSString *decStr = [NSString stringWithFormat:@"%d",testByte[0]];///10进制数
        NSMutableArray *by = [NSMutableArray array];
        for(int i=1;i<[revData length];i++) {
            /*
            NSString *newDecStr = [NSString stringWithFormat:@"%d",testByte[i]];///10进制数
            if([newDecStr length]==1) {
                decStr = [NSString stringWithFormat:@"%@,0%@",decStr,newDecStr];
            }
            else {
                decStr = [NSString stringWithFormat:@"%@,%@",decStr,newDecStr];
            }
             */
            if ( (i%20 != 0) && ((i-1)%20 != 0) ) {
                [by addObject:@(testByte[i])];
            }
            else {
                
            }
            if (i%20==1) {
                NSLog(@"rt_包序列：%@ rt_num:%ld", [NSString stringWithFormat:@"%d",testByte[i]], rt_num);
                if ((testByte[i]) != (rt_num+1)%256) { // > 255?0:lt_num+1
                    NSLog(@"lt_丢包了吧");
                    
                    for (NSInteger i = rt_num+1; i < testByte[i]; i++) {
                        // 丢包补齐
                        if (self.measureManager.rt_q_str.length > 0) {
                            [self.measureManager.rt_q_str appendFormat:@",-%ld", i*100];
                        }
                        else {
                            [self.measureManager.rt_q_str appendFormat:@"-%ld", i*100];
                        }
                        
                        // 丢包补齐
                        if (self.measureManager.rt_i_str.length > 0) {
                            [self.measureManager.rt_i_str appendFormat:@",-%ld", i*100];
                        }
                        else {
                            [self.measureManager.rt_i_str appendFormat:@"-%ld", i*100];
                        }
                    }
                }
                rt_num = testByte[i];
            }
        }
        
        // log txt
        
        NSDateFormatter * formatter = [[NSDateFormatter alloc ] init];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        [formatter setDateFormat:@"YYYY-MM-dd hh:mm:ss:SSSSSS"];
        NSString *date = [formatter stringFromDate:[NSDate date]];
        hexStr = [NSString stringWithFormat:@"%@：%@",date, hexStr];
        NSData *d = [hexStr dataUsingEncoding:NSUTF8StringEncoding];
        [self.measureManager.rt_logs addObject:d];
//        [self writeToFileWithString:d withFileName:@""];
//        EZLog(@"%@--%@", peripheral.identifier.UUIDString, [decStr substringToIndex:15]);
        
        // 数据解析
        BOOL isEcg = YES;
        for(int i=0;i<[by count];i+=3) {
            unsigned int total = 0;
//            total += [by[i] intValue]*256*256;
            total += (([by[i] intValue]&0xff) << 16);
            if (i+1<by.count) {
//                total += [by[i+1] intValue]*256;
                total += (([by[i+1] intValue]&0xff) << 8);
            }
            if (i+2<by.count) {
                total += [by[i+2] intValue];
            }
            
            if (isEcg) {
                [self.measureManager.rt_ecg_list addObject:@(total)];
                // 用于上传
                if (self.measureManager.rt_q_str.length > 0) {
                    [self.measureManager.rt_q_str appendFormat:@",%d", total];
                }
                else {
                    [self.measureManager.rt_q_str appendFormat:@"%d", total];
                }
                
            }
            else {
                [self.measureManager.rt_rf_list addObject:@(total)];
                self.measureManager.rt_quality = [_ls test:total];
                EZLog(@"quality_rt:%d",self.measureManager.rt_quality);
                // 用于上传
                if (self.measureManager.rt_i_str.length > 0) {
                    [self.measureManager.rt_i_str appendFormat:@",%d", total];
                }
                else {
                    [self.measureManager.rt_i_str appendFormat:@"%d", total];
                }
                
            }
            isEcg = !isEcg;
            
        }
        
    }
    else if ([characteristic.service.peripheral.identifier.UUIDString isEqualToString:[DeviceManager defaultManager].L_B_Aid.identifier]) {
        Byte *testByte = (Byte *)[revData bytes];
    
        if ((testByte[0]&0xff)==32) {    // 32 <===> 0x20  指令包
            if (((testByte[2]&0xff)==0)&&((testByte[3]&0xff)==0)) { // 设置不成功或参数非法

            }
            if ((testByte[2]&0xff)==3) { // 3  <===> 0x03  开始命令
                // 开始命令 得到下位机响应
                isStartOrderResponse_L_B = YES;
                [self showPreMeasureViewConroller];
            }
            if ((testByte[2]&0xff)==4) {
                // 停止命令
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                [center postNotificationName:StopOrderDidResponseNotification object:@(AidPosition_LB)];
            }
            if ((testByte[2]&0xff)==5) { // 5  <===> 0x05  暂停命令
                // 暂停命令 得到下位机响应
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                [center postNotificationName:PauseOrderDidResponseNotification object:@(AidPosition_LB)];
            }
            if ((testByte[2]&0xff)==9) { // 9  <===> 0x09  时间戳查询命令
                // 异或校验 **从字节1到字节17进行异或校验，与字节18比较
                // 获取时间戳
                    NSString *hex = [NSString stringWithFormat:@"%x", testByte[4]&0xff];
                    if ([hex length] == 1) {
                        hex = [NSString stringWithFormat:@"0%@",hex];
                    }
                    else {
                        
                    }
                    for (int i = 5; i <= 7; i++) {
                        NSString *newHexStr = [NSString stringWithFormat:@"%x", testByte[i]&0xff];
                        if([newHexStr length]==1) {
                            hex = [NSString stringWithFormat:@"%@0%@",hex,newHexStr];
                        }
                        else {
                            hex = [NSString stringWithFormat:@"%@%@",hex,newHexStr];
                        }
                    }
                    long long timestamp = [self htoi:[hex UTF8String]];
                    NSLog(@"%@-%lld", @"LB:", timestamp);
                    // 通过notification 定时开始
                    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                    [center postNotificationName:TimeStampDidResponseNotification object:@[@(timestamp), @(AidPosition_LB)]];

            }
            if ((testByte[2]&0xff)==10) { // A <===> 0x0A  定时命令
                // 异或校验 **从字节1到字节17进行异或校验，与字节18比较
                NSLog(@"LB:%@", characteristic.value);
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                [center postNotificationName:TimeStartDidResponseNotification object:@(AidPosition_LB)];
            }
            return;
        }

        // Byte 转 16进制
        
        NSString *hexStr = [NSString stringWithFormat:@"%x",testByte[0]&0xff];///16进制数
        if ([hexStr length] == 1) {
            hexStr = [NSString stringWithFormat:@"0%@",hexStr];
        }
        else {
            
        }
        
        for(int i=1;i<[revData length];i++) {
            NSString *newHexStr = [NSString stringWithFormat:@"%x",testByte[i]&0xff];///16进制数
            if([newHexStr length]==1) {
                hexStr = [NSString stringWithFormat:@"%@：0%@",hexStr,newHexStr];
            }
            else {
                hexStr = [NSString stringWithFormat:@"%@：%@",hexStr,newHexStr];
            }
        }
        
        
        // Byte 转 10进制
//        NSString *decStr = [NSString stringWithFormat:@"%d",testByte[0]];///10进制数
        NSMutableArray *by = [NSMutableArray array];
        for(int i=1;i<[revData length];i++) {
            /*
            NSString *newDecStr = [NSString stringWithFormat:@"%d",testByte[i]];///10进制数
            if([newDecStr length]==1) {
                decStr = [NSString stringWithFormat:@"%@,0%@",decStr,newDecStr];
            }
            else {
                decStr = [NSString stringWithFormat:@"%@,%@",decStr,newDecStr];
            }
             */
            if ( (i%20 != 0) && ((i-1)%20 != 0) ) {
                [by addObject:@(testByte[i])];
            }
            else {

            }
            if (i%20==1) {
                NSLog(@"lb_包序列：%@ lb_num:%ld", [NSString stringWithFormat:@"%d",testByte[i]], lb_num);
                if ((testByte[i]) != (lb_num+1)%256) { // > 255?0:lt_num+1
                    NSLog(@"lb_丢包了吧");
                    
                    for (NSInteger i = lb_num+1; i < testByte[i]; i++) {
                        // 丢包补齐
                        if (self.measureManager.lb_q_str.length > 0) {
                            [self.measureManager.lb_q_str appendFormat:@",-%ld", i*100];
                        }
                        else {
                            [self.measureManager.lb_q_str appendFormat:@"-%ld", i*100];
                        }
                        
                        // 丢包补齐
                        if (self.measureManager.lb_i_str.length > 0) {
                            [self.measureManager.lb_i_str appendFormat:@",-%ld", i*100];
                        }
                        else {
                            [self.measureManager.lb_i_str appendFormat:@"-%ld", i*100];
                        }
                    }
                }
                lb_num = testByte[i];
            }
        }
        
        // log txt
        
        NSDateFormatter * formatter = [[NSDateFormatter alloc ] init];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        [formatter setDateFormat:@"YYYY-MM-dd hh:mm:ss:SSSSSS"];
        NSString *date = [formatter stringFromDate:[NSDate date]];
        hexStr = [NSString stringWithFormat:@"%@：%@",date, hexStr];
        NSData *d = [hexStr dataUsingEncoding:NSUTF8StringEncoding];
//        [self writeToFileWithString:d withFileName:@""];
        [self.measureManager.lb_logs addObject:d];
//        EZLog(@"%@", hexStr);
        
        // 数据解析
        BOOL isEcg = YES;
        for(int i=0;i<[by count];i+=3) {
            unsigned int total = 0;
//            total += [by[i] intValue]*256*256;
            total += (([by[i] intValue]&0xff) << 16);
            if (i+1<by.count) {
//                total += [by[i+1] intValue]*256;
                total += (([by[i+1] intValue]&0xff) << 8);
            }
            if (i+2<by.count) {
                total += [by[i+2] intValue];
            }
            
            if (isEcg) {
                [self.measureManager.lb_ecg_list addObject:@(total)];
                // 用于上传
                if (self.measureManager.lb_q_str.length > 0) {
                    [self.measureManager.lb_q_str appendFormat:@",%d", total];
                }
                else {
                    [self.measureManager.lb_q_str appendFormat:@"%d",total];
                }
                
            }
            else {
                [self.measureManager.lb_rf_list addObject:@(total)];
                self.measureManager.lb_quality = [_ls test:total];
                EZLog(@"quality_lb:%d",self.measureManager.lb_quality);
                // 用于上传
                if (self.measureManager.lb_i_str.length > 0) {
                    [self.measureManager.lb_i_str appendFormat:@",%d", total];
                }
                else {
                    [self.measureManager.lb_i_str appendFormat:@"%d",total];
                }
                
            }
            isEcg = !isEcg;
            
        }
    }
    else if ([characteristic.service.peripheral.identifier.UUIDString isEqualToString:[DeviceManager defaultManager].R_B_Aid.identifier]) {
        Byte *testByte = (Byte *)[revData bytes];
        if ((testByte[0]&0xff)==32) {    // 32 <===> 0x20  指令包
            if (((testByte[2]&0xff)==0)&&((testByte[3]&0xff)==0)) { // 设置不成功或参数非法
                
            }
            if ((testByte[2]&0xff)==3) { // 3  <===> 0x03  开始命令
                // 开始命令 得到下位机响应
                isStartOrderResponse_R_B = YES;
                [self showPreMeasureViewConroller];
            }
            if ((testByte[2]&0xff)==4) {
                // 停止命令
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                [center postNotificationName:StopOrderDidResponseNotification object:@(AidPosition_RB)];
            }
            if ((testByte[2]&0xff)==5) { // 5  <===> 0x05  暂停命令
                // 暂停命令 得到下位机响应
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                [center postNotificationName:PauseOrderDidResponseNotification object:@(AidPosition_RB)];
            }
            if ((testByte[2]&0xff)==9) { // 9  <===> 0x09  时间戳查询命令
                // 异或校验 **从字节1到字节17进行异或校验，与字节18比较
                // 获取时间戳
                    NSString *hex = [NSString stringWithFormat:@"%x", testByte[4]&0xff];
                    if ([hex length] == 1) {
                        hex = [NSString stringWithFormat:@"0%@",hex];
                    }
                    else {
                        
                    }
                    for (int i = 5; i <= 7; i++) {
                        NSString *newHexStr = [NSString stringWithFormat:@"%x", testByte[i]&0xff];
                        if([newHexStr length]==1) {
                            hex = [NSString stringWithFormat:@"%@0%@",hex,newHexStr];
                        }
                        else {
                            hex = [NSString stringWithFormat:@"%@%@",hex,newHexStr];
                        }
                    }
                    long long timestamp = [self htoi:[hex UTF8String]];
                    NSLog(@"%@-%lld", @"RB:", timestamp);
                    // 通过notification 定时开始
                    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                    [center postNotificationName:TimeStampDidResponseNotification object:@[@(timestamp), @(AidPosition_RB)]];
    
            }
            if ((testByte[2]&0xff)==10) { // A <===> 0x0A  定时命令
                // 异或校验 **从字节1到字节17进行异或校验，与字节18比较
                NSLog(@"RB:%@", characteristic.value);
                NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                [center postNotificationName:TimeStartDidResponseNotification object:@(AidPosition_RB)];
            }
            return;
        }

        // Byte 转 16进制
        
        NSString *hexStr = [NSString stringWithFormat:@"%x",testByte[0]&0xff];///16进制数
        if ([hexStr length] == 1) {
            hexStr = [NSString stringWithFormat:@"0%@",hexStr];
        }
        else {
            
        }
        
        for(int i=1;i<[revData length];i++) {
            NSString *newHexStr = [NSString stringWithFormat:@"%x",testByte[i]&0xff];///16进制数
            if([newHexStr length]==1) {
                hexStr = [NSString stringWithFormat:@"%@：0%@",hexStr,newHexStr];
            }
            else {
                hexStr = [NSString stringWithFormat:@"%@：%@",hexStr,newHexStr];
            }
        }
        
        
        // Byte 转 10进制
//        NSString *decStr = [NSString stringWithFormat:@"%d",testByte[0]];///10进制数
        NSMutableArray *by = [NSMutableArray array];
        for(int i=1;i<[revData length];i++) {
            /*
            NSString *newDecStr = [NSString stringWithFormat:@"%d",testByte[i]];///10进制数
            if([newDecStr length]==1) {
                decStr = [NSString stringWithFormat:@"%@,0%@",decStr,newDecStr];
            }
            else {
                decStr = [NSString stringWithFormat:@"%@,%@",decStr,newDecStr];
            }
             */
            if ( (i%20 != 0) && ((i-1)%20 != 0) ) {
                [by addObject:@(testByte[i])];
            }
            else {
                
            }
            if (i%20==1) {
                NSLog(@"rb_包序列：%@ rb_num:%ld", [NSString stringWithFormat:@"%d",testByte[i]], rb_num);
                if ((testByte[i]) != (rb_num+1)%256) { // (rb_num+1)%256==0?1:(rb_num+1)%256
                    NSLog(@"rb_丢包了吧");
                    
                    for (NSInteger i = rb_num+1; i < testByte[i]; i++) {
                        // 丢包补齐
                        if (self.measureManager.rb_q_str.length > 0) {
                            [self.measureManager.rb_q_str appendFormat:@",-%ld", i*100];
                        }
                        else {
                            [self.measureManager.rb_q_str appendFormat:@"-%ld", i*100];
                        }
                        
                        // 丢包补齐
                        if (self.measureManager.rb_i_str.length > 0) {
                            [self.measureManager.rb_i_str appendFormat:@",-%ld", i*100];
                        }
                        else {
                            [self.measureManager.rb_i_str appendFormat:@"-%ld", i*100];
                        }
                    }
                    
                    
                }
                rb_num = testByte[i];
            }
        }
        
        // log txt
        
        NSDateFormatter * formatter = [[NSDateFormatter alloc ] init];
        [formatter setTimeZone:[NSTimeZone systemTimeZone]];
        [formatter setDateFormat:@"YYYY-MM-dd hh:mm:ss:SSSSSS"];
        NSString *date = [formatter stringFromDate:[NSDate date]];
        hexStr = [NSString stringWithFormat:@"%@：%@",date, hexStr];
        NSData *d = [hexStr dataUsingEncoding:NSUTF8StringEncoding];
        [self.measureManager.rb_logs addObject:d];
//        [self writeToFileWithString:d withFileName:@""];
        
//        EZLog(@"%@--%@", peripheral.identifier.UUIDString, [decStr substringToIndex:15]);
        
//        EZLog(@"%@--%@", peripheral.identifier.UUIDString, [hexStr substringToIndex:15]);
        
        // 数据解析
        BOOL isEcg = YES;
        for(int i=0;i<[by count];i+=3) {
            unsigned int total = 0;
//            int a = ([by[i] intValue]&0xff) << 16;
//            total += [by[i] intValue]*256*256;
            total += (([by[i] intValue]&0xff) << 16);
            if (i+1<by.count) {
//                total += [by[i+1] intValue]*256;
                total += (([by[i+1] intValue]&0xff) << 8);
            }
            if (i+2<by.count) {
                total += [by[i+2] intValue];
            }
            
            if (isEcg) {
                [self.measureManager.rb_ecg_list addObject:@(total)];
                // 用于上传
                if (self.measureManager.rb_q_str.length > 0) {
                    [self.measureManager.rb_q_str appendFormat:@",%d", total];
                }
                else {
                    [self.measureManager.rb_q_str appendFormat:@"%d", total];
                }
                
            }
            else {
                [self.measureManager.rb_rf_list addObject:@(total)];
                self.measureManager.rb_quality = [_ls test:total];
                EZLog(@"quality_rb:%d",self.measureManager.rb_quality);
                // 用于上传
                if (self.measureManager.rb_i_str.length > 0) {
                    [self.measureManager.rb_i_str appendFormat:@",%d", total];
                }
                else {
                    [self.measureManager.rb_i_str appendFormat:@"%d", total];
                }
                
            }
            isEcg = !isEcg;
            
        }
    }
    
}
- (void)peripheral:(nonnull CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error {
    if (error) {
        NSLog(@"错误didUpdateNotification：%@",error);
        return;
    }
    
    CBCharacteristicProperties properties = characteristic.properties;
    if (properties & CBCharacteristicPropertyRead) {
        //如果具备读特性，即可以读取特性的value
        [peripheral readValueForCharacteristic:characteristic];
    }
}

#pragma mark - 连接超时
- (void)didConnectPeripheralTimeout {
    _hud.labelText = @"连接超时，请检查设备";
    _hud.mode = MBProgressHUDModeText;
    [_hud hide:YES afterDelay:1.5];
    [BLEMANAGER stopScan];
    //    [BLEMANAGER disconnect:<#(nonnull CBPeripheral *)#>]
    isNeedACounter = NO;
    counter = 0;
}

#pragma mark - MBProgressHud delegate
- (void)hudViewTapGesture {
    _hud.labelText = @"正在取消连接";
    [_hud hide:YES afterDelay:1.5];
    [BLEMANAGER stopScan];
//    [BLEMANAGER disconnect:<#(nonnull CBPeripheral *)#>]
    isNeedACounter = NO;
    counter = 0;
}


#pragma mark - MBProgressHudDelegate
- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    
    hud = nil;
}

#pragma mark - 保存用户信息
- (void)saveInfoBtnDidClicked:(UIButton *)sender {
    
    if (self.mainView.addUserView.isAddedPatient) { // 编辑
        self.mainView.addUserView.isAddedPatient = NO;
    }
    else { // 保存
        if (self.mainView.addUserView.nameText.text.stringByTrim.length == 0) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"姓名未填写";
            [hud hide:YES afterDelay:1];
            return;
        }
        if ([self.mainView.addUserView.genderBtn.titleLabel.text.stringByTrim isEqualToString:@"未设置"]) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"性别未填写";
            [hud hide:YES afterDelay:1];
            return;
        }
        if ([self.mainView.addUserView.ageBtn.titleLabel.text.stringByTrim isEqualToString:@"未设置"]) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"年龄未填写";
            [hud hide:YES afterDelay:1];
            return;
        }
        if ([self.mainView.addUserView.heightBtn.titleLabel.text.stringByTrim isEqualToString:@"未设置"]) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"身高未填写";
            [hud hide:YES afterDelay:1];
            return;
        }
        if ([self.mainView.addUserView.weightBtn.titleLabel.text.stringByTrim isEqualToString:@"未设置"]) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            hud.mode = MBProgressHUDModeText;
            hud.labelText = @"体重未填写";
            [hud hide:YES afterDelay:1];
            return;
        }

        NSArray *subs = [self.mainView.addUserView.ageBtn.titleLabel.text componentsSeparatedByString:@"("];
        NSString *s = subs.lastObject;
        subs = [s componentsSeparatedByString:@")"];
        s = subs.firstObject;
        
        NSArray *heights = [self.mainView.addUserView.heightBtn.titleLabel.text componentsSeparatedByString:@" "];
        NSString *height = heights.firstObject;
        
        NSArray *weights = [self.mainView.addUserView.weightBtn.titleLabel.text componentsSeparatedByString:@" "];
        NSString *weight = weights.firstObject;
        
        LoginManager *lm = [LoginManager defaultManager];
    //    if (!lm.currentPatient) {
    //        [lm getLastPatientInfo];
    //    }
        Patient *patient = [[Patient alloc] init];
        patient.Id     = [LoginManager defaultManager].currentUser.Id;
        patient.name   = self.mainView.addUserView.nameText.text.stringByTrim;
        patient.mobile = self.mainView.addUserView.phoneText.text.stringByTrim;
        patient.gender = self.mainView.addUserView.genderBtn.titleLabel.text.stringByTrim;
        patient.age    = self.mainView.addUserView.ageBtn.titleLabel.text.stringByTrim;
        patient.height = [height integerValue];
        patient.weight = [weight integerValue];
        patient.isLastAdd = YES;
        
        // 上传服务器
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        [self.loginApi saveCurrentPatient:patient completion:^(BOOL success, NSString *msg) {
            if (success) {
                // 保存到数据库
                lm.currentPatient = patient;
                [lm savePatientInfo:patient];
                [self addUserInfoView];
                hud.mode = MBProgressHUDModeText;
                hud.labelText = @"上传成功";
                [hud hide:YES afterDelay:1];
            }
            else {
                // 失败
                hud.mode = MBProgressHUDModeText;
                hud.labelText = @"保存失败";
                [hud hide:YES afterDelay:1];
            }
        }];
    }

}

#pragma mark - 解除绑定的操作
- (void)lt_aid_bind:(UIButton *)sender {
    if (_L_T_Peripheral) {
        // 断开连接
        if (self.deviceManager.L_T_CB_Peripheral) {
            [BLEMANAGER disconnect:self.deviceManager.L_T_CB_Peripheral];
        }
        // 删除数据库数据
        [self.api removePeripheral:_L_T_Peripheral];

        _L_T_Peripheral = nil;
//        _L_T_CB_Peripheral = nil;
//        _L_T_CB_Characteristic = nil;
        self.deviceManager.L_T_Aid = nil;
        self.deviceManager.L_T_CB_Peripheral = nil;
        self.deviceManager.L_T_CB_Characteristic = nil;
        
    }
    else {
        // 绑定设备
        [self L_T_AidBtnDidClicked:self.mainView.L_T_AidBtn];
    }
    [self.mainView.deviceListView reloadAllData];
}
- (void)rt_aid_bind:(UIButton *)sender {
    if (_R_T_Peripheral) {
        // 断开连接
        if (self.deviceManager.R_T_CB_Peripheral) {
            [BLEMANAGER disconnect:self.deviceManager.R_T_CB_Peripheral];
        }
        
        // 删除数据库数据
        [self.api removePeripheral:_R_T_Peripheral];
        
        _R_T_Peripheral = nil;
//        _R_T_CB_Peripheral = nil;
//        _R_T_CB_Characteristic = nil;
        self.deviceManager.R_T_Aid = nil;
        self.deviceManager.R_T_CB_Peripheral = nil;
        self.deviceManager.R_T_CB_Characteristic = nil;
        
    }
    else {
        // 绑定设备
        [self R_T_AidBtnDidClicked:self.mainView.R_T_AidBtn];
    }
    [self.mainView.deviceListView reloadAllData];
}
- (void)lb_aid_bind:(UIButton *)sender {
    if (_L_B_Peripheral) {
        // 断开连接
        if (self.deviceManager.L_B_CB_Peripheral) {
            [BLEMANAGER disconnect:self.deviceManager.L_B_CB_Peripheral];
        }
        
        // 删除数据库数据
        [self.api removePeripheral:_L_B_Peripheral];
        
        _L_B_Peripheral = nil;
//        _L_B_CB_Peripheral = nil;
//        _L_B_CB_Characteristic = nil;
        self.deviceManager.L_B_Aid = nil;
        self.deviceManager.L_B_CB_Peripheral = nil;
        self.deviceManager.L_B_CB_Characteristic = nil;
        
    }
    else {
        // 绑定设备
        [self L_B_AidBtnDidClicked:self.mainView.L_B_AidBtn];
    }
    [self.mainView.deviceListView reloadAllData];
}
- (void)rb_aid_bind:(UIButton *)sender {
    if (_R_B_Peripheral) {
        // 断开连接
        if (self.deviceManager.R_B_CB_Peripheral) {
            [BLEMANAGER disconnect:self.deviceManager.R_B_CB_Peripheral];
        }
        
        // 删除数据库数据
        [self.api removePeripheral:_R_B_Peripheral];
        
        _R_B_Peripheral = nil;
//        _R_B_CB_Peripheral = nil;
//        _R_B_CB_Characteristic = nil;
        self.deviceManager.R_B_Aid = nil;
        self.deviceManager.R_B_CB_Peripheral = nil;
        self.deviceManager.R_B_CB_Characteristic = nil;
        
    }
    else {
        // 绑定设备
        [self R_B_AidBtnDidClicked:self.mainView.R_B_AidBtn];
    }
    [self.mainView.deviceListView reloadAllData];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    for (UIView *v in self.mainView.addUserView.contentView.subviews) {
        [v resignFirstResponder];
    }
}


#pragma mark - properties
- (MainView *)mainView {
    return (MainView *)self.view;
}

- (BLEManager *)bleManager {
    return [BLEManager sharedInstance];
}

- (DevicesApi *)api {
    if (!_api) {
        _api = [DevicesApi biz];
    }
    
    return _api;
}

-(LoginApi *)loginApi {
    if (!_loginApi) {
        _loginApi = [LoginApi biz];
    }
    return _loginApi;
}

- (MeasureProtocol *)protocol {
    if (!_protocol) {
        _protocol = [[MeasureProtocol alloc] init];
    }
    return _protocol;
}


- (MeasureManager *)measureManager {
    return [MeasureManager defaultManager];
}

- (DeviceManager *)deviceManager {
    return [DeviceManager defaultManager];
}

@end
