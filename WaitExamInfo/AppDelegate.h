//
//  AppDelegate.h
//  WaitExamInfo
//
//  Created by lyn on 14-9-28.
//
//

#import <UIKit/UIKit.h>
@class StationInfo;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property(nonatomic,strong) StationInfo *gStationInfo;
@property(nonatomic,strong) NSString *gUID;

@end
