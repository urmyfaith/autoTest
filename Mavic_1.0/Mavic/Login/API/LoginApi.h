//
//  LoginApi.h
//  Mavic
//
//  Created by zhangxiaoqiang on 2017/3/31.
//  Copyright © 2017年 LoHas-Tech. All rights reserved.
//

#import "DCBiz.h"
#import "LoginEntities.h"
#import "CommonEntities.h"
@interface LoginApi : DCBiz

- (void)loginWithUserName:(NSString *)name pwd:(NSString *)password completion:(void(^)(BOOL, id, NSString *))complete;
- (void)registerWithPhone:(NSString *)phone pwd:(NSString *)pwd compeletion:(void(^)(BOOL, NSString *))complete;
- (void)checkValidationCodeWithPhone:(NSString *)phone authCode:(NSString *)auth_code type:(NSInteger)type compeletion:(void(^)(BOOL, NSString *))complete;
- (void)checkMobileDuplicate:(NSString *)phone compeletion:(void(^)(BOOL, NSString *))complete;
- (void)getValidationCodeWithPhoneNumber:(NSString *)phone completion:(void(^)(BOOL, NSString *))complete;

/*
 ** 修改服务器用户信息
 */
- (void)saveCurrentPatient:(Patient *)patient completion:(void(^)(BOOL,NSString *))complete;

- (void)saveCurrentUser:(User *)user;

- (void)saveCurrentPatient:(Patient *)patient;

- (User *)getCurrentUserFormMainDB;

- (NSArray *)getUsersFormMainDB;

- (Patient *)getCurrentPatientFormMainDB;

/*
 ** 清空 患者数据库
 */
- (void)deletePatientDatabase;

@end
