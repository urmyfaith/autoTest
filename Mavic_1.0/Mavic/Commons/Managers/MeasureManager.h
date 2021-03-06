//
//  MeasureManager.h
//  Mavic
//
//  Created by zhangxiaoqiang on 2017/4/7.
//  Copyright © 2017年 LoHas-Tech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MeasureManager : NSObject

@property(atomic, strong) NSMutableArray *lt_ecg_list;
@property(atomic, strong) NSMutableArray *lt_rf_list;
@property(atomic, strong) NSMutableString *lt_q_str;
@property(atomic, strong) NSMutableString *lt_i_str;
@property(atomic, assign) int lt_quality;

@property(atomic, strong) NSMutableArray *rt_ecg_list;
@property(atomic, strong) NSMutableArray *rt_rf_list;
@property(atomic, strong) NSMutableString *rt_q_str;
@property(atomic, strong) NSMutableString *rt_i_str;
@property(atomic, assign) int rt_quality;

@property(atomic, strong) NSMutableArray *lb_ecg_list;
@property(atomic, strong) NSMutableArray *lb_rf_list;
@property(atomic, strong) NSMutableString *lb_q_str;
@property(atomic, strong) NSMutableString *lb_i_str;
@property(atomic, assign) int lb_quality;

@property(atomic, strong) NSMutableArray *rb_ecg_list;
@property(atomic, strong) NSMutableArray *rb_rf_list;
@property(atomic, strong) NSMutableString *rb_q_str;
@property(atomic, strong) NSMutableString *rb_i_str;
@property(atomic, assign) int rb_quality;

@property(atomic, strong) NSMutableArray *lt_logs;
@property(atomic, strong) NSMutableArray *lb_logs;
@property(atomic, strong) NSMutableArray *rt_logs;
@property(atomic, strong) NSMutableArray *rb_logs;

/**
 * 单例
 */

+ (instancetype)defaultManager;

/*
 ** 清除数据
 */
- (void)clearAllCache;

@end
