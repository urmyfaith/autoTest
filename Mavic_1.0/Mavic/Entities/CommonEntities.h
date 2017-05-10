//
//  CommonEntities.h
//  Mavic
//
//  Created by zhangxiaoqiang on 2017/4/5.
//  Copyright © 2017年 LoHas-Tech. All rights reserved.
//

#import "DCObject.h"
#import "DCDatabaseObject.h"
#import "BLEManager.h"
#import "LoginEntities.h"

typedef enum : NSUInteger {
    UnKnown,
    L_T_Aid,
    L_B_Aid,
    R_T_Aid,
    R_B_Aid,
} Location;

@interface Peripheral : DCDatabaseObject

NS_ASSUME_NONNULL_BEGIN

@property (nonatomic, strong) NSString *macString;
@property (nonatomic)         Location location;
@property (nonatomic, strong) NSString *identifier NS_AVAILABLE(NA, 7_0);
@property (nonatomic, strong) NSString *name;
@property (nonatomic)         CBPeripheralState   state;
@property (nonatomic, strong) NSString *serviceUUID;

- (instancetype)initWithCBPeripheral:(CBPeripheral *)peripheral;

NS_ASSUME_NONNULL_END

@end

@interface Patient : DCDatabaseObject

NS_ASSUME_NONNULL_BEGIN


@property (copy) NSString *Id;
@property (copy) NSString *name;//" : "18515982821",
@property (copy) NSString *mobile;//" : "18515982821",

@property (copy) NSString *gender;//" : "男",
@property (copy) NSString  *age;//" : 43,
@property        NSInteger height;//" : 170,
@property        NSInteger weight;//" : 70,

@property        BOOL      isLastAdd;

- (instancetype)initWithUser:(User *)user;

NS_ASSUME_NONNULL_END

@end
