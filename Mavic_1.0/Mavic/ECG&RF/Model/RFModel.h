//
//  RFModel.h
//  Mavic
//
//  Created by XiaoQiang on 2017/4/28.
//  Copyright © 2017年 LoHas-Tech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RFModel : NSObject

/*
 ** 加载数据
 */
- (void)reloadData;

/*
 ** 获取患者 全部信息
 */
- (NSString *)getPatientInfo;

@end
