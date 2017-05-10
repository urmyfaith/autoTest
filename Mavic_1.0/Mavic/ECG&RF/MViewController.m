//
//  ViewController.m
//  Demo
//
//  Created by liuxingyu on 2017/4/11.
//  Copyright © 2017年 zhumengjiao. All rights reserved.
//

#import "MViewController.h"
#import "SeMonitorController.h"
#import "FViewController.h"
#import "MeasureViewController.h"
#import "SettingViewController.h"
#import "LineView.h"
#import "MNaviView.h"
#import "YYKit.h"
#import "unit_test_for_app.h"
#import "ViewController.h"
#import "MeasureManager.h"
#import "DeviceManager.h"
#import "MeasureAPI.h"
#import "MBProgressHUD.h"
#import "LockSignal.h"
#import "CheckByte_XOR.h"
#import "UIImage+memory.h"
#import "RFModel.h"


#define INITIALRATE 60000

@interface MViewController ()<MBProgressHUDDelegate, CBPeripheralDelegate> {
    
    CADisplayLink *_dataLink;
    
    LineView *_lineView_LB;
    LineView *_lineView_RB;
    LineView *_lineView_LT;
    LineView *_lineView_RT;
    
    NSTimer *_popDataTimer;
    NSTimer *_timer;
    
    float lastY;
    int   countDown;
    
    BOOL  isPauseOrderDidResponse_L_T;
    BOOL  isPauseOrderDidResponse_L_B;
    BOOL  isPauseOrderDidResponse_R_T;
    BOOL  isPauseOrderDidResponse_R_B;
    
    BOOL  isTimeStampOrderDidResponse_L_T;
    BOOL  isTimeStampOrderDidResponse_L_B;
    BOOL  isTimeStampOrderDidResponse_R_T;
    BOOL  isTimeStampOrderDidResponse_R_B;
    
    BOOL  isTimerStartOrderDidResponse_L_T;
    BOOL  isTimerStartOrderDidResponse_L_B;
    BOOL  isTimerStartOrderDidResponse_R_T;
    BOOL  isTimerStartOrderDidResponse_R_B;
    
    BOOL  isStopOrderDidResponse_L_T;
    BOOL  isStopOrderDidResponse_L_B;
    BOOL  isStopOrderDidResponse_R_T;
    BOOL  isStopOrderDidResponse_R_B;
    
    
    __block BOOL lb_sig;
    __block BOOL lt_sig;
    __block BOOL rb_sig;
    __block BOOL rt_sig;
    
    int lt_sigs;
    
    UIImage *foundImg;
    UIImage *unfoundImg;
    
    char *outf;
    uint32_t *array;
    int arrcount;
    
    NSInteger lb,lt,rb,rt;
}

@property (nonatomic, strong) MNaviView      *naviContainView;
@property (nonatomic, strong) ViewController *mainVC;
@property (nonatomic, strong) FViewController *home;
@property (nonatomic, strong) MeasureViewController *measureVC;
@property (nonatomic, strong) MeasureAPI     *api;
@property (nonatomic, strong) RFModel        *rfModel;
@property (nonatomic, strong) LockSignal     *ls;
@property (nonatomic, strong) MBProgressHUD  *hud;
@property (nonatomic, strong) UIImageView    *icon;
@property (nonatomic, strong) UILabel        *infoLabel;
@property (nonatomic, strong) UILabel        *timerLabel;
@property (nonatomic, strong) UIButton       *startMeasureBtn;
@property (nonatomic, strong) NSThread       *subThread;

@end

@implementation MViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    countDown = 480;
    foundImg = [UIImage imageNamed:@"found"];
    unfoundImg = [UIImage imageNamed:@"unfound"];
    lt_sigs = 0;
    
    [self reloadData];
    
    [self setLinks];
    
    [self setSubViews];
    
    [self setLineView];
    
    _ls = [[LockSignal alloc] init];
    //    [[SeMonitorController sharedInstance] startMonitor];
    
    
    outf=(char *)malloc(sizeof(char)*2000000);
    array=(uint32_t *)malloc(sizeof(uint32_t)*1000000);
    arrcount = 0;
    
    [self threadTest];
    [self performSelector:@selector(subThreadOpetion) onThread:self.subThread withObject:nil waitUntilDone:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self removeLinks];
    self.api = nil;
    [_lineView_LB removeFromSuperview];
    [_lineView_LT removeFromSuperview];
    [_lineView_RB removeFromSuperview];
    [_lineView_RT removeFromSuperview];
    _lineView_LB = nil;
    _lineView_LT = nil;
    _lineView_RB = nil;
    _lineView_RT = nil;
    
//    [MeasureManager defaultManager].lb_q_str = nil;
//    [MeasureManager defaultManager].lb_i_str = nil;
//    [MeasureManager defaultManager].lt_q_str = nil;
//    [MeasureManager defaultManager].lt_i_str = nil;
//    [MeasureManager defaultManager].rb_q_str = nil;
//    [MeasureManager defaultManager].rb_i_str = nil;
//    [MeasureManager defaultManager].rt_q_str = nil;
//    [MeasureManager defaultManager].rt_i_str = nil;
//    [[MeasureManager defaultManager].lb_rf_list removeAllObjects];
//    [[MeasureManager defaultManager].lt_rf_list removeAllObjects];
//    [[MeasureManager defaultManager].rb_rf_list removeAllObjects];
//    [[MeasureManager defaultManager].rt_rf_list removeAllObjects];
    [[MeasureManager defaultManager] clearAllCache];
    
//    self.view = nil;
    self.naviContainView = nil;
    self.icon = nil;
    self.infoLabel = nil;
    self.timerLabel = nil;
    self.startMeasureBtn = nil;
    [self.subThread cancel];
    self.subThread = nil;
    
    [_popDataTimer invalidate];
    _popDataTimer = nil;
    
    [_timer invalidate];
    _timer = nil;
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.view.backgroundColor = UIColorHex(eef8fa);
    
    // 注册通知
    // 获取时间戳之后，执行
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(pauseOrder:) name:PauseOrderDidResponseNotification object:nil];
    [center addObserver:self selector:@selector(getTimerStamp:) name:TimeStampDidResponseNotification object:nil];
    [center addObserver:self selector:@selector(timerStart:) name:TimeStartDidResponseNotification object:nil];
    [center addObserver:self selector:@selector(stopOrder:) name:StopOrderDidResponseNotification object:nil];
    
}

- (void)reloadData {
    [self.rfModel reloadData];
}

- (void)setSubViews {
    _naviContainView = [[MNaviView alloc] initWithFrame:CGRectMake(12, 12, self.view.width - 24, 44)];

    [self.view addSubview:_naviContainView];
    
    _icon = [[UIImageView alloc] initWithFrame:CGRectMake(20, 7, 30, 30)];
    _icon.image = self.rfModel.isMale?[UIImage imageWithMName:@"male"]:[UIImage imageWithMName:@"female"];
    [_naviContainView addSubview:_icon];
    
    _infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 0, 1000-80, 44)];
    _infoLabel.text = [self.rfModel getPatientInfoWithStep:MeasureStep_Advance];
    _infoLabel.font = [UIFont systemFontOfSize:15];
    _infoLabel.textColor = UIColorHex(999999);
    [_naviContainView addSubview:_infoLabel];
    
    _naviContainView.timerLabel.text = [NSString stringWithFormat:@"%d秒后结束找位", countDown];
    
    
    _mainVC = (ViewController *)self.parentViewController.parentViewController;
    [_mainVC.backBtn removeAllTargets];
    for (UIView *v in _mainVC.naviBarView.subviews) {
        if ([v isKindOfClass:[UIButton class]]) {
            v.hidden = NO;
            _mainVC.backBtn = (UIButton *)v;
            [_mainVC.backBtn addTarget:self action:@selector(commit) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    
}

- (void)setLineView {
    
    _lineView_LT = [[LineView alloc] initWithFrame:CGRectMake(12, CGRectGetMaxY(self.naviContainView.frame)+10, self.view.width - 24, 135) position:AidPosition_LT];
    _lineView_RT = [[LineView alloc] initWithFrame:CGRectMake(12, CGRectGetMaxY(_lineView_LT.frame)+5, self.view.width - 24, 135) position:AidPosition_RT];
    _lineView_LB = [[LineView alloc] initWithFrame:CGRectMake(12, CGRectGetMaxY(_lineView_RT.frame)+5, self.view.width - 24, 135) position:AidPosition_LB];
    _lineView_RB = [[LineView alloc] initWithFrame:CGRectMake(12, CGRectGetMaxY(_lineView_LB.frame)+5, self.view.width - 24, 135) position:AidPosition_RB];
    
    _startMeasureBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    _startMeasureBtn.frame = CGRectMake(self.view.width/2.0-140, CGRectGetMaxY(_lineView_RB.frame)+20, 280, 44);
    [_startMeasureBtn setBackgroundImage:[UIImage imageNamed:@"default"] forState:UIControlStateNormal];
    [_startMeasureBtn setTitle:@"开始测量" forState:UIControlStateNormal];
    [_startMeasureBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_startMeasureBtn addTarget:self action:@selector(startMeasure:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_lineView_LB];
    [self.view addSubview:_lineView_RB];
    [self.view addSubview:_lineView_LT];
    [self.view addSubview:_lineView_RT];
    [self.view addSubview:_startMeasureBtn];
}

- (void)setLinks {
    
//    _timer = [NSTimer scheduledTimerWithTimeInterval:0.1
//                                                     target:self
//                                                   selector:@selector(timerEvent_popData)
//                                                   userInfo:NULL
//                                                    repeats:YES];
//    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    
    _dataLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(timerEvent_popData)];
    [_dataLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)removeLinks {
    
    _dataLink == nil ?:[_dataLink invalidate];_dataLink = nil;
}

- (void)timerEvent_popData {
//    if (lb == [MeasureManager defaultManager].lb_rf_list.count) {
//        [[MeasureManager defaultManager].lb_rf_list addObject:[MeasureManager defaultManager].lb_rf_list[lb-1]];
//    }
//    if (lt == [MeasureManager defaultManager].lt_rf_list.count) {
//        [[MeasureManager defaultManager].lt_rf_list addObject:[MeasureManager defaultManager].lt_rf_list[lt-1]];
//    }
//    if (rb == [MeasureManager defaultManager].rb_rf_list.count) {
//        [[MeasureManager defaultManager].rb_rf_list addObject:[MeasureManager defaultManager].rb_rf_list[rb-1]];
//    }
//    if (rt == [MeasureManager defaultManager].rt_rf_list.count) {
//        [[MeasureManager defaultManager].rt_rf_list addObject:[MeasureManager defaultManager].rt_rf_list[rt-1]];
//    }
    
    [_lineView_LB startDrawWithOriginalData:[[MeasureManager defaultManager].lb_rf_list copy]];
    [_lineView_RB startDrawWithOriginalData:[[MeasureManager defaultManager].rb_rf_list copy]];
    [_lineView_LT startDrawWithOriginalData:[[MeasureManager defaultManager].lt_rf_list copy]];
    [_lineView_RT startDrawWithOriginalData:[[MeasureManager defaultManager].rt_rf_list copy]];

//    lb = [MeasureManager defaultManager].lb_rf_list.count;
//    lt = [MeasureManager defaultManager].lt_rf_list.count;
//    rb = [MeasureManager defaultManager].rb_rf_list.count;
//    rt = [MeasureManager defaultManager].rt_rf_list.count;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - 开始测量
- (void)startMeasure:(UIButton *)sender {
    // 暂停数据传输
    Byte byte[] = {0x0a,0x05,0x05,0x01,0x01,0x00,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xf0};
    NSData *data = [NSData dataWithBytes:byte length:sizeof(byte)];
    
    MeasureViewController *mea = (MeasureViewController *)self.parentViewController;
    [[DeviceManager defaultManager].L_T_CB_Peripheral setDelegate:mea];
    [[DeviceManager defaultManager].L_B_CB_Peripheral setDelegate:mea];
    [[DeviceManager defaultManager].R_T_CB_Peripheral setDelegate:mea];
    [[DeviceManager defaultManager].R_B_CB_Peripheral setDelegate:mea];
    // 暂停命令
    // 响应时间超时，二次重发
    NSLog(@"pause 0");
    [[DeviceManager defaultManager].L_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_T_CB_Characteristic type:1];
    [[DeviceManager defaultManager].L_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_B_CB_Characteristic type:1];
    [[DeviceManager defaultManager].R_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_T_CB_Characteristic type:1];
    [[DeviceManager defaultManager].R_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_B_CB_Characteristic type:1];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 1次重连
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!isPauseOrderDidResponse_L_T) {
                [[DeviceManager defaultManager].L_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_T_CB_Characteristic type:1];
                // 2次重连
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (!isPauseOrderDidResponse_L_T) {
                        [[DeviceManager defaultManager].L_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_T_CB_Characteristic type:1];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if(!isPauseOrderDidResponse_L_T) {
                                // Exit
                                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                hud.mode = MBProgressHUDModeText;
                                hud.labelText = @"左上肢贴片暂停指令响应超时";
                                [hud hide:YES afterDelay:1];
                                
                            }
                        });
                    }
                });
            }
            if (!isPauseOrderDidResponse_L_B) {
                [[DeviceManager defaultManager].L_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_B_CB_Characteristic type:1];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (!isPauseOrderDidResponse_L_B) {
                        [[DeviceManager defaultManager].L_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_B_CB_Characteristic type:1];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if(!isPauseOrderDidResponse_L_B) {
                                // Exit
                                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                hud.mode = MBProgressHUDModeText;
                                hud.labelText = @"左下踝贴片暂停指令响应超时";
                                [hud hide:YES afterDelay:1];
                                
                            }
                        });
                    }
                });
            }
            if (!isPauseOrderDidResponse_R_T) {
                [[DeviceManager defaultManager].R_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_T_CB_Characteristic type:1];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (!isPauseOrderDidResponse_R_T) {
                        [[DeviceManager defaultManager].R_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_T_CB_Characteristic type:1];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if(!isPauseOrderDidResponse_R_T) {
                                // Exit
                                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                hud.mode = MBProgressHUDModeText;
                                hud.labelText = @"右上肢贴片暂停指令响应超时";
                                [hud hide:YES afterDelay:1];
                                
                            }
                        });
                    }
                });
            }
            if (!isPauseOrderDidResponse_R_B) {
                [[DeviceManager defaultManager].R_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_B_CB_Characteristic type:1];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (!isPauseOrderDidResponse_R_B) {
                        [[DeviceManager defaultManager].R_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_B_CB_Characteristic type:1];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if(!isPauseOrderDidResponse_R_B) {
                                // Exit
                                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                hud.mode = MBProgressHUDModeText;
                                hud.labelText = @"右下踝贴片暂停指令响应超时";
                                [hud hide:YES afterDelay:1];
                                
                            }
                        });
                    }
                });
            }
            
        });
        
    });
    
    // 查询时间戳命令 500ms之后
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //
        Byte byte[] = {0x0a,0x04,0x09,0x00,0x0D,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xf0};
        NSData *data = [NSData dataWithBytes:byte length:sizeof(byte)];
        // 响应时间超时，二次重发
        NSLog(@"pause 0");
        
        [[DeviceManager defaultManager].L_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_T_CB_Characteristic type:1];
        [[DeviceManager defaultManager].L_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_B_CB_Characteristic type:1];
        [[DeviceManager defaultManager].R_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_T_CB_Characteristic type:1];
        [[DeviceManager defaultManager].R_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_B_CB_Characteristic type:1];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            // 1次重连
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!isTimeStampOrderDidResponse_L_T) {
                    [[DeviceManager defaultManager].L_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_T_CB_Characteristic type:1];
                    // 2次重连
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (!isTimeStampOrderDidResponse_L_T) {
                            [[DeviceManager defaultManager].L_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_T_CB_Characteristic type:1];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                if(!isTimeStampOrderDidResponse_L_T) {
                                    // Exit
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                    hud.mode = MBProgressHUDModeText;
                                    hud.labelText = @"左上肢贴片获取时间戳超时";
                                    [hud hide:YES afterDelay:1];
                                    
                                }
                            });
                        }
                    });
                }
                if (!isTimeStampOrderDidResponse_L_B) {
                    [[DeviceManager defaultManager].L_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_B_CB_Characteristic type:1];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (!isTimeStampOrderDidResponse_L_B) {
                            [[DeviceManager defaultManager].L_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_B_CB_Characteristic type:1];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                if(!isTimeStampOrderDidResponse_L_B) {
                                    // Exit
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                    hud.mode = MBProgressHUDModeText;
                                    hud.labelText = @"左下踝贴片获取时间戳超时";
                                    [hud hide:YES afterDelay:1];
                                    
                                }
                            });
                        }
                    });
                }
                if (!isTimeStampOrderDidResponse_R_T) {
                    [[DeviceManager defaultManager].R_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_T_CB_Characteristic type:1];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (!isTimeStampOrderDidResponse_R_T) {
                            [[DeviceManager defaultManager].R_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_T_CB_Characteristic type:1];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                if(!isTimeStampOrderDidResponse_R_T) {
                                    // Exit
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                    hud.mode = MBProgressHUDModeText;
                                    hud.labelText = @"右上肢贴片获取时间戳超时";
                                    [hud hide:YES afterDelay:1];
                                    
                                }
                            });
                        }
                    });
                }
                if (!isTimeStampOrderDidResponse_R_B) {
                    [[DeviceManager defaultManager].R_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_B_CB_Characteristic type:1];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (!isTimeStampOrderDidResponse_R_B) {
                            [[DeviceManager defaultManager].R_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_B_CB_Characteristic type:1];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                if(!isTimeStampOrderDidResponse_R_B) {
                                    // Exit
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                    hud.mode = MBProgressHUDModeText;
                                    hud.labelText = @"右下踝贴片获取时间戳超时";
                                    [hud hide:YES afterDelay:1];
                                    
                                }
                            });
                        }
                    });
                }
                
            });
            
        });
        
    });

    /*
    
     */
}

#pragma mark - 通知事件
#pragma mark 定时开始 之前 查询到时间戳
- (void)getTimerStamp:(NSNotification *)noti {
    NSArray *obj = noti.object;
    long long timestamp = [obj[0] longLongValue] + 50000;
    AidPosition positon = [obj[1] integerValue];
    
    
    switch (positon) {
        case AidPosition_LT:{
            isTimeStampOrderDidResponse_L_T = YES;
            break;
        }
        case AidPosition_LB:{
            isTimeStampOrderDidResponse_L_B = YES;
            break;
        }
        case AidPosition_RT:{
            isTimeStampOrderDidResponse_R_T = YES;
            break;
        }
        case AidPosition_RB:{
            isTimeStampOrderDidResponse_R_B = YES;
            break;
        }
        default:
            break;
    }
    
    if (isTimeStampOrderDidResponse_L_B && isTimeStampOrderDidResponse_L_T && isTimeStampOrderDidResponse_R_T && isTimeStampOrderDidResponse_R_B) { //
        NSString *timeStr   = [self int64ToHex:timestamp];
        for (int i = 0; i<=8-(int)timeStr.length+1; i++) {
            timeStr = [NSString stringWithFormat:@"0%@", timeStr];
        }
        NSLog(@"%lld - %@", timestamp, timeStr);
        
        Byte byte[] = {0x0a,0x0c,0x0a,0x08,0x0D,0xA5,0xA5,0xA5,0x24,0x9F,0x00,0x00,0x15,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xf0};
        int index = 7;
        for (int i = (int)timeStr.length-1; i >= 1; i-=2) {
            NSString *sub = [timeStr substringWithRange:NSMakeRange(i-1, 2)];
            
            // 16进制字符串 转 16进制 并赋值给byte指令
            int nvalue = 0;
            sscanf([sub cStringUsingEncoding:NSASCIIStringEncoding], "%x", &nvalue);
            byte[index]  = nvalue&0xff;
            
            index--;
        }
        
        // 异或校验
        byte[12] = [CheckByte_XOR XORByte:byte formByte:1 toByte:11];
        
        // 定时开始
        MeasureViewController *mea = (MeasureViewController *)self.parentViewController;
        [[DeviceManager defaultManager].L_T_CB_Peripheral setDelegate:mea];
        [[DeviceManager defaultManager].L_B_CB_Peripheral setDelegate:mea];
        [[DeviceManager defaultManager].R_T_CB_Peripheral setDelegate:mea];
        [[DeviceManager defaultManager].R_B_CB_Peripheral setDelegate:mea];
        NSData *data = [NSData dataWithBytes:byte length:sizeof(byte)];
        // 响应时间超时，二次重发
        NSLog(@"pause 0");
        [[DeviceManager defaultManager].L_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_T_CB_Characteristic type:1];
        [[DeviceManager defaultManager].L_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_B_CB_Characteristic type:1];
        [[DeviceManager defaultManager].R_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_T_CB_Characteristic type:1];
        [[DeviceManager defaultManager].R_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_B_CB_Characteristic type:1];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            // 1次重连
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (!isTimerStartOrderDidResponse_L_T) {
                    [[DeviceManager defaultManager].L_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_T_CB_Characteristic type:1];
                    // 2次重连
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (!isTimerStartOrderDidResponse_L_T) {
                            [[DeviceManager defaultManager].L_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_T_CB_Characteristic type:1];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                if(!isTimerStartOrderDidResponse_L_T) {
                                    // Exit
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                    hud.mode = MBProgressHUDModeText;
                                    hud.labelText = @"左上肢贴片定时指令响应超时";
                                    [hud hide:YES afterDelay:1];
                                    
                                }
                            });
                        }
                    });
                }
                if (!isTimerStartOrderDidResponse_L_B) {
                    [[DeviceManager defaultManager].L_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_B_CB_Characteristic type:1];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (!isTimerStartOrderDidResponse_L_B) {
                            [[DeviceManager defaultManager].L_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_B_CB_Characteristic type:1];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                if(!isTimerStartOrderDidResponse_L_B) {
                                    // Exit
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                    hud.mode = MBProgressHUDModeText;
                                    hud.labelText = @"左下踝贴片定时指令响应超时";
                                    [hud hide:YES afterDelay:1];
                                    
                                }
                            });
                        }
                    });
                }
                if (!isTimerStartOrderDidResponse_R_T) {
                    [[DeviceManager defaultManager].R_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_T_CB_Characteristic type:1];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (!isTimerStartOrderDidResponse_R_T) {
                            [[DeviceManager defaultManager].R_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_T_CB_Characteristic type:1];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                if(!isTimerStartOrderDidResponse_R_T) {
                                    // Exit
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                    hud.mode = MBProgressHUDModeText;
                                    hud.labelText = @"右上肢贴片定时指令响应超时";
                                    [hud hide:YES afterDelay:1];
                                    
                                }
                            });
                        }
                    });
                }
                if (!isTimerStartOrderDidResponse_R_B) {
                    [[DeviceManager defaultManager].R_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_B_CB_Characteristic type:1];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (!isTimerStartOrderDidResponse_R_B) {
                            [[DeviceManager defaultManager].R_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_B_CB_Characteristic type:1];
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                if(!isTimerStartOrderDidResponse_R_B) {
                                    // Exit
                                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                    hud.mode = MBProgressHUDModeText;
                                    hud.labelText = @"右下踝贴片定时指令响应超时";
                                    [hud hide:YES afterDelay:1];
                                    
                                }
                            });
                        }
                    });
                }
                
            });
            
        });

    }
    
}
#pragma mark 定时开始
- (void)timerStart:(NSNotification *)noti {
    AidPosition position = [noti.object integerValue];
    switch (position) {
        case AidPosition_LT:{
            isTimerStartOrderDidResponse_L_T = YES;
            break;
        }
        case AidPosition_LB:{
            isTimerStartOrderDidResponse_L_B = YES;
            break;
        }
        case AidPosition_RT:{
            isTimerStartOrderDidResponse_R_T = YES;
            break;
        }
        case AidPosition_RB:{
            isTimerStartOrderDidResponse_R_B = YES;
            break;
        }
        default:
            break;
    }
    
    if (isTimerStartOrderDidResponse_L_B && isTimerStartOrderDidResponse_L_T && isTimerStartOrderDidResponse_R_T && isTimerStartOrderDidResponse_R_B) {//
        // 推出正式测量控制器
        [_mainVC.backBtn removeAllTargets];
        
        _home = [[FViewController alloc]
                 init];
        _mainVC    = (ViewController *)self.parentViewController.parentViewController;
        _measureVC = (MeasureViewController *)self.parentViewController;
        [_measureVC addChildViewController:_home];
        _home.modalPresentationStyle = UIModalPresentationFormSheet;
        _home.preferredContentSize   = CGSizeMake(375, 678);
        _home.view.frame = CGRectMake(_mainVC.view.width, 0, _mainVC.view.width, self.view.height);
        _home.view.backgroundColor = [UIColor whiteColor];
        __weak typeof(_measureVC) meaself = _measureVC;
        __weak typeof(self) myself = self;
        _home.uploadBlock = ^{
            [meaself restartTimer];
            for (UIView *v in myself.mainVC.naviBarView.subviews) {
                if ([v isKindOfClass:[UIButton class]]) {
                    v.hidden = YES;
                }
            }
            _home = nil;
        };
        [_measureVC.view addSubview:_home.view];
        
        [UIView animateWithDuration:0.35 animations:^{
            _home.view.frame = CGRectMake(-120, 0, _mainVC.view.width, _mainVC.view.height);
        } completion:^(BOOL finished) {
            [self.view removeFromSuperview];
            [self removeFromParentViewController];
            
            
        }];
    }
}
#pragma mark 暂停指令得到响应
- (void)pauseOrder:(NSNotification *)noti {
    AidPosition positon = [noti.object integerValue];
    switch (positon) {
        case AidPosition_LT:{
            isPauseOrderDidResponse_L_T = YES;
            break;
        }
        case AidPosition_LB:{
            isPauseOrderDidResponse_L_B = YES;
            break;
        }
        case AidPosition_RT:{
            isPauseOrderDidResponse_R_T = YES;
            break;
        }
        case AidPosition_RB:{
            isPauseOrderDidResponse_R_B = YES;
            break;
        }
        default:
            break;
    }
    
}

#pragma mark 停止指令得到响应
- (void)stopOrder:(NSNotification *)noti {
    AidPosition positon = [noti.object integerValue];
    switch (positon) {
        case AidPosition_LT:{
            isStopOrderDidResponse_L_T = YES;
            break;
        }
        case AidPosition_LB:{
            isStopOrderDidResponse_L_B = YES;
            break;
        }
        case AidPosition_RT:{
            isStopOrderDidResponse_R_T = YES;
            break;
        }
        case AidPosition_RB:{
            isStopOrderDidResponse_R_B = YES;
            break;
        }
        default:
            break;
    }
}

#pragma mark - 10进制 转 16进制 字符串
- (NSString *)int64ToHex:(int64_t)tmpid
{
    NSString *nLetterValue;
    NSString *str =@"";
    int64_t ttmpig;
    for (int i = 0; i<19; i++) {
        ttmpig=tmpid%16;
        tmpid=tmpid/16;
        switch (ttmpig) {
            case 10:
                nLetterValue =@"a";break;
            case 11:
                nLetterValue =@"b";break;
            case 12:
                nLetterValue =@"c";break;
            case 13:
                nLetterValue =@"d";break;
            case 14:
                nLetterValue =@"e";break;
            case 15:
                nLetterValue =@"f";break;
            default:
                nLetterValue = [NSString stringWithFormat:@"%lld",ttmpig];
        }
        str = [nLetterValue stringByAppendingString:str];
        if (tmpid == 0) {
            break;
        }
    }
    return str;
}

#pragma mark - 子线程runloop
- (void)threadTest
{
    self.subThread = [[NSThread alloc] initWithTarget:self selector:@selector(subThreadEntryPoint) object:nil];
    [self.subThread setName:@"SignalThread"];
    [self.subThread start];
//    self.subThread = subThread;
}

/**
 子线程启动后，启动runloop
 */
- (void)subThreadEntryPoint
{
    @autoreleasepool {
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        //如果注释了下面这一行，子线程中的任务并不能正常执行
        [runLoop addPort:[NSMachPort port] forMode:NSRunLoopCommonModes];
//        NSLog(@"启动RunLoop前--%@",runLoop.currentMode);
        [runLoop run];
    }
}

/**
 子线程任务
 */
- (void)subThreadOpetion
{
    _popDataTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                     target:self
                                                   selector:@selector(checkLockSignal)
                                                   userInfo:NULL
                                                    repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:_popDataTimer forMode:NSDefaultRunLoopMode];
}

#pragma mark - 暂时模拟上传结果数据
- (void)commit {
    
    // 点击返回，停止通信
    Byte byte[] = {0x0a,0x04,0x04,0x00,0x00,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xA5,0xf0};
    // 异或校验
    byte[4] = [CheckByte_XOR XORByte:byte formByte:1 toByte:3];
    NSData *data = [NSData dataWithBytes:byte length:sizeof(byte)];
    
    MeasureViewController *mea = (MeasureViewController *)self.parentViewController;
    [[DeviceManager defaultManager].L_T_CB_Peripheral setDelegate:mea];
    [[DeviceManager defaultManager].L_B_CB_Peripheral setDelegate:mea];
    [[DeviceManager defaultManager].R_T_CB_Peripheral setDelegate:mea];
    [[DeviceManager defaultManager].R_B_CB_Peripheral setDelegate:mea];
    // 停止命令
    // 响应时间超时，二次重发
    NSLog(@"pause 0");
    [[DeviceManager defaultManager].L_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_T_CB_Characteristic type:1];
    [[DeviceManager defaultManager].L_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_B_CB_Characteristic type:1];
    [[DeviceManager defaultManager].R_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_T_CB_Characteristic type:1];
    [[DeviceManager defaultManager].R_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_B_CB_Characteristic type:1];
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 1次重连
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!isStopOrderDidResponse_L_T) {
                [[DeviceManager defaultManager].L_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_T_CB_Characteristic type:1];
                // 2次重连
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (!isStopOrderDidResponse_L_T) {
                        [[DeviceManager defaultManager].L_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_T_CB_Characteristic type:1];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if(!isStopOrderDidResponse_L_T) {
                                // Exit
                                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                hud.mode = MBProgressHUDModeText;
                                hud.labelText = @"左上肢贴片t停止指令响应超时";
                                [hud hide:YES afterDelay:1];
                                
                            }
                        });
                    }
                });
            }
            if (!isStopOrderDidResponse_L_B) {
                [[DeviceManager defaultManager].L_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_B_CB_Characteristic type:1];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (!isStopOrderDidResponse_L_B) {
                        [[DeviceManager defaultManager].L_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].L_B_CB_Characteristic type:1];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if(!isStopOrderDidResponse_L_B) {
                                // Exit
                                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                hud.mode = MBProgressHUDModeText;
                                hud.labelText = @"左下踝贴片停止指令响应超时";
                                [hud hide:YES afterDelay:1];
                                
                            }
                        });
                    }
                });
            }
            if (!isStopOrderDidResponse_R_T) {
                [[DeviceManager defaultManager].R_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_T_CB_Characteristic type:1];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (!isStopOrderDidResponse_R_T) {
                        [[DeviceManager defaultManager].R_T_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_T_CB_Characteristic type:1];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if(!isStopOrderDidResponse_R_T) {
                                // Exit
                                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                hud.mode = MBProgressHUDModeText;
                                hud.labelText = @"右上肢贴片停止指令响应超时";
                                [hud hide:YES afterDelay:1];
                                
                            }
                        });
                    }
                });
            }
            if (!isStopOrderDidResponse_R_B) {
                [[DeviceManager defaultManager].R_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_B_CB_Characteristic type:1];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (!isStopOrderDidResponse_R_B) {
                        [[DeviceManager defaultManager].R_B_CB_Peripheral writeValue:data forCharacteristic:[DeviceManager defaultManager].R_B_CB_Characteristic type:1];
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if(!isStopOrderDidResponse_R_B) {
                                // Exit
                                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
                                hud.mode = MBProgressHUDModeText;
                                hud.labelText = @"右下踝贴片停止指令响应超时";
                                [hud hide:YES afterDelay:1];
                                
                            }
                        });
                    }
                });
            }
            
        });
        
    });
    
    
    _hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _hud.labelText = @"正在上传数据";
    dispatch_async(dispatch_queue_create("conc", DISPATCH_QUEUE_CONCURRENT), ^{
        
        NSString *lb_mac = [DeviceManager defaultManager].L_B_Aid.macString;
        NSString *rb_mac = [DeviceManager defaultManager].R_B_Aid.macString;
        NSString *lt_mac = [DeviceManager defaultManager].L_T_Aid.macString;
        NSString *rt_mac = [DeviceManager defaultManager].R_T_Aid.macString;
        NSDictionary *lt_item =  @{
                                   @"place"    : @"LU",
                                   @"bt_mac"   : lt_mac,
                                   @"hw_name"  : @"aa",
                                   @"fw_ver"   : @"bb",
                                   @"mod_ver"  : @"cc",
                                   @"bio_rf_i" :
                                       [MeasureManager defaultManager].lt_i_str?[MeasureManager defaultManager].lt_i_str:@"",
                                   @"bio_rf_q" :
                                       [MeasureManager defaultManager].lt_q_str?[MeasureManager defaultManager].lt_q_str:@""
                                   };
        NSDictionary *rt_item =  @{
                                   @"place"    : @"RU",
                                   @"bt_mac"   : rt_mac,
                                   @"hw_name"  : @"aa",
                                   @"fw_ver"   : @"bb",
                                   @"mod_ver"  : @"cc",
                                   @"bio_rf_i" :
                                       [MeasureManager defaultManager].rt_i_str?[MeasureManager defaultManager].rt_i_str:@"",
                                   @"bio_rf_q" :
                                       [MeasureManager defaultManager].rt_q_str?[MeasureManager defaultManager].rt_q_str:@""
                                   };
        NSDictionary *lb_item =  @{
                                   @"place"    : @"LD",
                                   @"bt_mac"   : lb_mac,
                                   @"hw_name"  : @"aa",
                                   @"fw_ver"   : @"bb",
                                   @"mod_ver"  : @"cc",
                                   @"bio_rf_i" :
                                       [MeasureManager defaultManager].lb_i_str?[MeasureManager defaultManager].lb_i_str:@"",
                                   @"bio_rf_q" :
                                       [MeasureManager defaultManager].lb_q_str?[MeasureManager defaultManager].lb_q_str:@""
                                   };
        NSDictionary *rb_item =  @{
                                   @"place"    : @"RD",
                                   @"bt_mac"   : rb_mac,
                                   @"hw_name"  : @"aa",
                                   @"fw_ver"   : @"bb",
                                   @"mod_ver"  : @"cc",
                                   @"bio_rf_i" :
                                       [MeasureManager defaultManager].rb_i_str?[MeasureManager defaultManager].rb_i_str:@"",
                                   @"bio_rf_q" :
                                       [MeasureManager defaultManager].rb_q_str?[MeasureManager defaultManager].rb_q_str:@""
                                   };
        
        [self.api uploadResultWithResult:@[lb_item, rb_item, lt_item, rt_item] completion:^(BOOL success, id result, NSString *msg) {
            
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _hud.mode = MBProgressHUDModeText;
                    _hud.labelText = @"上传数据成功";
                    [_hud hide:YES afterDelay:0.75];
                });
                
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    _hud.mode = MBProgressHUDModeText;
                    _hud.labelText = @"上传数据失败";
                    [_hud hide:YES afterDelay:0.75];
                });
                
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismissCurrentViewController];
            });
        }];

    });
}
#pragma mark 将波形数据转为字符串
- (NSString *)stringConvertByData:(NSArray *)data {
    if (data.count == 0) {
        return @"";
    }
    int i = 0;
    NSString *str = [NSString stringWithFormat:@"%d", [data[0] intValue]];
    for (NSNumber *n in data) {
        if (i != 0) {
            str = [NSString stringWithFormat:@"%@,%d", str, n.intValue];
        }
        i += 1;
    }
    
    return str;
}

#pragma mark - dismiss 控制器
- (void)dismissCurrentViewController {
    [UIView animateWithDuration:0.35 animations:^{
        self.view.frame = CGRectMake(_mainVC.view.width, 0, _mainVC.view.width, _mainVC.view.height);
    } completion:^(BOOL finished) {
        for (ViewController *vc in [_mainVC childViewControllers]) {
            if ([vc isKindOfClass:[SettingViewController class]]) {
                vc.view.userInteractionEnabled = YES;
            }
        }
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        self.uploadBlock();
    }];
}

#pragma mark - 锁定算法
#pragma mark - 锁定算法
- (void)checkLockSignal {
    // 剩余找位时间
    countDown -= 1;
    
    if ([MeasureManager defaultManager].lt_quality>=2) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _lineView_LT.signalImg.image = foundImg;
            self.naviContainView.timerLabel.text = [NSString stringWithFormat:@"%d秒后结束找位", countDown];
        });
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            _lineView_LT.signalImg.image = unfoundImg;
            self.naviContainView.timerLabel.text = [NSString stringWithFormat:@"%d秒后结束找位", countDown];
        });
    }
    if ([MeasureManager defaultManager].lb_quality>=2) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _lineView_LB.signalImg.image = foundImg;
            self.naviContainView.timerLabel.text = [NSString stringWithFormat:@"%d秒后结束找位", countDown];
        });
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            _lineView_LB.signalImg.image = unfoundImg;
            self.naviContainView.timerLabel.text = [NSString stringWithFormat:@"%d秒后结束找位", countDown];
        });
    }
    if ([MeasureManager defaultManager].rt_quality>=2) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _lineView_RT.signalImg.image = foundImg;
            self.naviContainView.timerLabel.text = [NSString stringWithFormat:@"%d秒后结束找位", countDown];
        });
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            _lineView_RT.signalImg.image = unfoundImg;
            self.naviContainView.timerLabel.text = [NSString stringWithFormat:@"%d秒后结束找位", countDown];
        });
    }
    if ([MeasureManager defaultManager].rb_quality>=2) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _lineView_RB.signalImg.image = foundImg;
            self.naviContainView.timerLabel.text = [NSString stringWithFormat:@"%d秒后结束找位", countDown];
        });
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            _lineView_RB.signalImg.image = unfoundImg;
            self.naviContainView.timerLabel.text = [NSString stringWithFormat:@"%d秒后结束找位", countDown];
        });
    }
    
}

#pragma mark - MBProgressHudDelegate
- (void)hudWasHidden:(MBProgressHUD *)hud {
    [hud removeFromSuperview];
    hud = nil;
}

#pragma mark - private properties
- (MeasureAPI *)api {
    if (!_api) {
        _api = [MeasureAPI biz];
    }
    return _api;
}

- (RFModel *)rfModel {
    if (!_rfModel) {
        _rfModel = [[RFModel alloc] init];
    }
    return _rfModel;
}

@end
