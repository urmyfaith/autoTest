//
//  MainView.m
//  Mavic
//
//  Created by zhangxiaoqiang on 2017/4/1.
//  Copyright © 2017年 LoHas-Tech. All rights reserved.
//

#import "MainView.h"
#import "YYKit.h"

@interface MainView ()<UIPickerViewDelegate, UIPickerViewDataSource>
{
    NSMutableArray *dataArray;
}
@property (weak, nonatomic) IBOutlet UIView *table_container;

@property (weak, nonatomic) IBOutlet UIView *body_container;
@property (weak, nonatomic) IBOutlet UILabel *nobindL;
@property (weak, nonatomic) IBOutlet UILabel *uncnnectedL;
@property (weak, nonatomic) IBOutlet UILabel *connectedL;

@end

@implementation MainView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    UITextField *searchField        = [_searchBar valueForKey:@"_searchField"];
    searchField.borderStyle         = UITextBorderStyleNone;
    searchField.backgroundColor     = [UIColor whiteColor];
    searchField.layer.cornerRadius  = 8.0;
    searchField.layer.borderWidth   = 0.5;
    searchField.layer.borderColor   = UIColorHex(cccccc).CGColor;
    searchField.layer.masksToBounds = YES;
    
    _searchBar.layer.shadowColor    = UIColorHex(000000).CGColor;
    _searchBar.layer.shadowOffset   = CGSizeMake(0, 2);
    _searchBar.layer.shadowRadius   = 1;
    _searchBar.layer.shadowOpacity  = 0.09;
    
    
    
    _addUserView = [[AddUserInfo alloc] initWithFrame:_table_container.bounds];
    _addUserView.hidden = YES;
    [_addUserView.timePicker addTarget:self action:@selector(dateChanged) forControlEvents:UIControlEventValueChanged];
    _addUserView.contentPicker.delegate = self;
    _addUserView.contentPicker.dataSource = self;
    
    [_addUserView.genderBtn addTarget:self action:@selector(genderBtnDidClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_addUserView.ageBtn addTarget:self action:@selector(ageBtnDidClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_addUserView.heightBtn addTarget:self action:@selector(heightBtnDidClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_addUserView.weightBtn addTarget:self action:@selector(weightBtnDidClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_table_container addSubview:_addUserView];
    
    
    _deviceListView = [[DeviceList alloc] initWithFrame:CGRectMake(0, -38, 280, 675)];
    _deviceListView.hidden = YES;
    [_table_container addSubview:_deviceListView];
    
    _body_container.layer.cornerRadius  = 8.0;
    _body_container.layer.masksToBounds = YES;
    _body_container.clipsToBounds       = NO;
    _body_container.layer.borderColor   = UIColorHex(cccccc).CGColor;
    _body_container.layer.shadowColor   = UIColorHex(000000).CGColor;
    _body_container.layer.shadowOffset  = CGSizeMake(0, 2);
    _body_container.layer.shadowRadius  = 1;
    _body_container.layer.shadowOpacity = 0.09;

    
    _nobindL.textColor        = UIColorHex(999999);
    _connectedL.textColor     = UIColorHex(32d250);
    _uncnnectedL.textColor    = UIColorHex(ff8a00);
    
    _startBtn.layer.cornerRadius  = 118.0;
    _startBtn.layer.masksToBounds = YES;
    
    
    _layerAnimaView.layer.cornerRadius  = 8.0;
    _layerAnimaView.layer.masksToBounds = YES;
    _layerAnimaView.clipsToBounds       = YES;
    
    
    CALayer * spreadLayer;
    spreadLayer = [CALayer layer];
    CGFloat diameter = 300;  //扩散的大小
    spreadLayer.bounds = CGRectMake(0,0, diameter, diameter);
    spreadLayer.cornerRadius = diameter/2; //设置圆角变为圆形
    spreadLayer.borderWidth = 2;
    spreadLayer.borderColor = [UIColorHex(32d250) CGColor];
    spreadLayer.position = CGPointMake(_layerAnimaView.width, _layerAnimaView.height);
    spreadLayer.backgroundColor = [[UIColor clearColor] CGColor];
    [_layerAnimaView.layer insertSublayer:spreadLayer below:_startBtn.layer];//把扩散层放到头像按钮下面
    CAMediaTimingFunction * defaultCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    CAAnimationGroup * animationGroup = [CAAnimationGroup animation];
    animationGroup.duration = 3;
    animationGroup.repeatCount = INFINITY;//重复无限次
    animationGroup.removedOnCompletion = NO;
    animationGroup.timingFunction = defaultCurve;
    //尺寸比例动画
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.xy"];
    scaleAnimation.fromValue = @0.78;//开始的大小
    scaleAnimation.toValue = @1.0;//最后的大小
    scaleAnimation.duration = 3;//动画持续时间
    //透明度动画
    CAKeyframeAnimation *opacityAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.duration = 3;
    opacityAnimation.values = @[@1, @0.9,@0];//透明度值的设置
    opacityAnimation.keyTimes = @[@0, @0.5,@1];//关键帧
    opacityAnimation.removedOnCompletion = NO;
    animationGroup.animations = @[scaleAnimation, opacityAnimation];//添加到动画组
    [spreadLayer addAnimation:animationGroup forKey:@"pulse"];
    
    [self performSelector:@selector(animation) withObject:nil afterDelay:1.87];
    
    
    dataArray = [NSMutableArray array];
}

- (void)animation {
    CALayer * spreadLayer;
    spreadLayer = [CALayer layer];
    CGFloat diameter = 300;  //扩散的大小
    spreadLayer.bounds = CGRectMake(0,0, diameter, diameter);
    spreadLayer.cornerRadius = diameter/2; //设置圆角变为圆形
    spreadLayer.borderWidth = 2;
    spreadLayer.borderColor = [UIColorHex(32d250) CGColor];
    spreadLayer.position = CGPointMake(_layerAnimaView.width, _layerAnimaView.height);
    spreadLayer.backgroundColor = [[UIColor clearColor] CGColor];
    [_layerAnimaView.layer insertSublayer:spreadLayer below:_startBtn.layer];//把扩散层放到头像按钮下面
    CAMediaTimingFunction * defaultCurve = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionDefault];
    CAAnimationGroup * animationGroup = [CAAnimationGroup animation];
    animationGroup.duration = 3;
    animationGroup.repeatCount = INFINITY;//重复无限次
    animationGroup.removedOnCompletion = NO;
    animationGroup.timingFunction = defaultCurve;
    //尺寸比例动画
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.xy"];
    scaleAnimation.fromValue = @0.78;//开始的大小
    scaleAnimation.toValue = @1.0;//最后的大小
    scaleAnimation.duration = 3;//动画持续时间
    //透明度动画
    CAKeyframeAnimation *opacityAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.duration = 3;
    opacityAnimation.values = @[@1, @0.9,@0];//透明度值的设置
    opacityAnimation.keyTimes = @[@0, @0.5,@1];//关键帧
    opacityAnimation.removedOnCompletion = NO;
    animationGroup.animations = @[scaleAnimation, opacityAnimation];//添加到动画组
    [spreadLayer addAnimation:animationGroup forKey:@"pulse"];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
}


- (void)genderBtnDidClicked:(UIButton *)sender {
    
    [_addUserView.nameText resignFirstResponder];
    [_addUserView.phoneText resignFirstResponder];
    
    _addUserView.timePicker.hidden = YES;
    _addUserView.contentPicker.hidden = NO;
    
    [dataArray removeAllObjects];
    [dataArray addObjectsFromArray:@[@"未设置",@"男",@"女",@"其他"]];
    [_addUserView.contentPicker reloadAllComponents];
    [_addUserView.contentPicker selectRow:0 inComponent:0 animated:YES];
    _addUserView.contentPicker.tag = 111;
}

- (void)ageBtnDidClicked:(UIButton *)sender {
    [_addUserView.nameText resignFirstResponder];
    [_addUserView.phoneText resignFirstResponder];
    
    _addUserView.timePicker.hidden = NO;
    _addUserView.contentPicker.hidden = YES;
    
    [_addUserView.ageBtn setTitleColor:UIColorHex(007aff) forState:UIControlStateNormal];
    //实例化一个NSDateFormatter对象
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    //用[NSDate date]可以获取系统当前时间
    NSString *ageDateStr = [dateFormatter stringFromDate:_addUserView.timePicker.date];
    NSString *currentDateStr = [dateFormatter stringFromDate:[NSDate date]];
    NSInteger ageYear = [[ageDateStr substringToIndex:4] integerValue];
    NSInteger currentYear = [[currentDateStr substringToIndex:4] integerValue];
    [sender setTitle:[NSString stringWithFormat:@"%@ (%ld)",ageDateStr, currentYear-ageYear] forState:UIControlStateNormal];
}

- (void)heightBtnDidClicked:(UIButton *)sender {
    _addUserView.timePicker.hidden = YES;
    _addUserView.contentPicker.hidden = NO;
    
    [dataArray removeAllObjects];
    [dataArray addObject:@"未设置"];
    for (int i = 140; i <= 200; i++) {
        NSString *string = [NSString stringWithFormat:@"%d cm", i];
        [dataArray addObject:string];
    }
    [_addUserView.contentPicker reloadAllComponents];
    [_addUserView.contentPicker selectRow:26 inComponent:0 animated:YES];
    [sender setTitle:@"165 cm" forState:UIControlStateNormal];
    _addUserView.contentPicker.tag = 112;
}

- (void)weightBtnDidClicked:(UIButton *)sender {
    _addUserView.timePicker.hidden = YES;
    _addUserView.contentPicker.hidden = NO;
    
    [dataArray removeAllObjects];
    [dataArray addObject:@"未设置"];
    for (int i = 40; i <= 120; i++) {
        NSString *string = [NSString stringWithFormat:@"%d kg", i];
        [dataArray addObject:string];
    }
    [_addUserView.contentPicker reloadAllComponents];
    [_addUserView.contentPicker selectRow:16 inComponent:0 animated:YES];
    [sender setTitle:@"55 kg" forState:UIControlStateNormal];
    _addUserView.contentPicker.tag = 113;
}

- (void)dateChanged
{
    [_addUserView.ageBtn setTitleColor:UIColorHex(007aff) forState:UIControlStateNormal];
    //实例化一个NSDateFormatter对象
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    //用[NSDate date]可以获取系统当前时间
    NSString *ageDateStr = [dateFormatter stringFromDate:_addUserView.timePicker.date];
    NSString *currentDateStr = [dateFormatter stringFromDate:[NSDate date]];
    NSInteger ageYear = [[ageDateStr substringToIndex:4] integerValue];
    NSInteger currentYear = [[currentDateStr substringToIndex:4] integerValue];
    [_addUserView.ageBtn setTitle:[NSString stringWithFormat:@"%@ (%ld)",ageDateStr, currentYear-ageYear].stringByTrim forState:UIControlStateNormal];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return dataArray.count;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return dataArray[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSString *content = dataArray[row];
    if (pickerView.tag == 111) {
        if (row != 0) {
            [_addUserView.genderBtn setTitleColor:UIColorHex(007aff) forState:UIControlStateNormal];
        }
        else {
            [_addUserView.genderBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        }
        [_addUserView.genderBtn setTitle:content.stringByTrim forState:UIControlStateNormal];
    }
    else if (pickerView.tag == 112) {
        if (row != 0) {
            [_addUserView.heightBtn setTitleColor:UIColorHex(007aff) forState:UIControlStateNormal];
        }
        else {
            [_addUserView.heightBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        }
       [_addUserView.heightBtn setTitle:content.stringByTrim forState:UIControlStateNormal];
    }
    else if (pickerView.tag == 113) {
        if (row != 0) {
            [_addUserView.weightBtn setTitleColor:UIColorHex(007aff) forState:UIControlStateNormal];
        }
        else {
            [_addUserView.weightBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        }
        [_addUserView.weightBtn setTitle:content.stringByTrim forState:UIControlStateNormal];
    }
}

@end
