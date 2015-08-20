//
//  ExamViewController.h
//  WaitExamInfo
//
//  Created by lyn on 14-10-8.
//
//

#import <UIKit/UIKit.h>
#import "TTCounterLabel.h"

@interface ExamViewController : UITableViewController <TTCounterLabelDelegate>
@property (weak, nonatomic) IBOutlet UILabel *curStudent;
@property (weak, nonatomic) IBOutlet UILabel *examTime;
@property (weak, nonatomic) IBOutlet UILabel *examStatus;
@property (weak, nonatomic) IBOutlet TTCounterLabel *remainTime;
@property (weak, nonatomic) IBOutlet UILabel *nextStation;
@property (weak, nonatomic) IBOutlet UILabel *examSubject;
@property (weak, nonatomic) IBOutlet UILabel *examContent;
@property (weak, nonatomic) IBOutlet TTCounterLabel *curTime;
@property (weak, nonatomic) IBOutlet UILabel *stuName;

@property (strong, nonatomic) NSTimer *myTimer;
@property (strong, nonatomic) NSString *sChanged;
@property BOOL myTag;
@property BOOL timeTag;
@property int nCount;

@end
