//
//  AddUserInfo.h
//  Mavic
//
//  Created by XiaoQiang on 2017/4/23.
//  Copyright © 2017年 LoHas-Tech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonEntities.h"
@interface AddUserInfo : UIView

@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (weak, nonatomic) IBOutlet UIDatePicker *timePicker;

@property (weak, nonatomic) IBOutlet UIPickerView *contentPicker;

@property (weak, nonatomic) IBOutlet UITextField *phoneText;

@property (weak, nonatomic) IBOutlet UITextField *nameText;

@property (weak, nonatomic) IBOutlet UIButton *genderBtn;

@property (weak, nonatomic) IBOutlet UIButton *ageBtn;

@property (weak, nonatomic) IBOutlet UIButton *heightBtn;

@property (weak, nonatomic) IBOutlet UIButton *weightBtn;

@property (weak, nonatomic) IBOutlet UIButton *saveInfoBtn;

@property (weak, nonatomic) IBOutlet UILabel *title;

@property (assign, nonatomic) BOOL isAddedPatient;

@property (strong, nonatomic) Patient *currentPatient;

@end
