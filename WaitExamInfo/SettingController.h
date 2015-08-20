//
//  SettingController.h
//  WaitExamInfo
//
//  Created by lyn on 14-12-18.
//
//

#import <UIKit/UIKit.h>
@class ComboxView;

@protocol PassValueDelegate
// 必选方法
- (void)passValue:(NSInteger )value;
@end

@interface SettingController : UIViewController <PassValueDelegate>
@property (weak, nonatomic) IBOutlet UITextField *txtServerIP;

@property NSInteger nValue;

- (IBAction)confirmIP:(id)sender;

@property(nonatomic,retain) ComboxView *comView;

@property(nonatomic,retain) NSMutableArray* RoomArray;

@end
