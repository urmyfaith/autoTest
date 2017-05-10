//
//  ResultView.h
//  Mavic
//
//  Created by XiaoQiang on 2017/4/28.
//  Copyright © 2017年 LoHas-Tech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SignalQualityView.h"
@interface ResultView : UIView

@property (weak, nonatomic) IBOutlet UIView *currentResultContainer;

@property (weak, nonatomic) IBOutlet UIView *historyResultContainer;

@property (weak, nonatomic) IBOutlet UIView *currentSignalQualityContainer;

@property (weak, nonatomic) IBOutlet UIView *currentInfoContainer;

@property (strong, nonatomic) WKEchartsView *historyCharts;

@property (weak, nonatomic) IBOutlet UIImageView *baPWVCoordinationView;


@property (weak, nonatomic) IBOutlet UIView *realCoordinateView;

@property (weak, nonatomic) IBOutlet UIImageView *leftAnchor;

@property (weak, nonatomic) IBOutlet UIImageView *rightAnchor;

@property (weak, nonatomic) IBOutlet SignalQualityView *lt_qualityProgress;

@property (weak, nonatomic) IBOutlet SignalQualityView *lb_qualityProgress;

@property (weak, nonatomic) IBOutlet SignalQualityView *rt_qualityProgress;

@property (weak, nonatomic) IBOutlet SignalQualityView *rb_qualityProgress;

@property (weak, nonatomic) IBOutlet UILabel *center_upper_limbs;

@property (weak, nonatomic) IBOutlet UILabel *center_lower_limbs;

@property (weak, nonatomic) IBOutlet UILabel *upper_lower_limbs;

@property (weak, nonatomic) IBOutlet UILabel *left_baPWV;
@property (weak, nonatomic) IBOutlet UILabel *left_baPWV_Type;

@property (weak, nonatomic) IBOutlet UILabel *right_baPWV;
@property (weak, nonatomic) IBOutlet UILabel *right_baPWV_Type;

@property (weak, nonatomic) IBOutlet UIButton *printBtn;

@property (weak, nonatomic) IBOutlet UIView *result_success;

@property (weak, nonatomic) IBOutlet UIView *result_fail;

@property (weak, nonatomic) IBOutlet UIButton *remeasureBtn;



@end
