//
//  RFModel.m
//  Mavic
//
//  Created by XiaoQiang on 2017/4/28.
//  Copyright © 2017年 LoHas-Tech. All rights reserved.
//

#import "RFModel.h"
#import "LoginManager.h"


@interface RFModel ()

@property (nonatomic, strong) LoginManager *loginManager;
@property (nonatomic, strong) Patient      *patient;

@end

@implementation RFModel

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)reloadData {
    [self.loginManager getLastPatientInfo];
    self.patient = self.loginManager.currentPatient;
}

- (NSString *)getPatientInfo {
    if (self.patient) {
        
        NSString *ages = [self.patient.age componentsSeparatedByString:@"("].lastObject;
        NSString *age  = [ages componentsSeparatedByString:@")"].firstObject;
        
        return [NSString stringWithFormat:
                @"ID：%@      姓名：%@      性别：%@      年龄：%@      身高：%ldcm      体重：%ldkg", self.patient.Id, self.patient.name, self.patient.gender, age, self.patient.height, self.patient.weight];
    }
    else {
        return [NSString stringWithFormat:
         @"ID：%@      姓名：%@      性别：%@      年龄：%@      身高：%@      体重：%@", @"-------", @"---", @"男", @"30", @"156cm", @"65kg"];
    }
    
}

#pragma mark - properties
- (LoginManager *)loginManager {
    return [LoginManager defaultManager];
}

@end
