//
//  ViewController.h
//  WaitExamInfo
//
//  Created by lyn on 14-9-28.
//
//

#import <UIKit/UIKit.h>
#import "SCNavigationController.h"

@interface ViewController : UIViewController <SCNavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIImageView *netPhoto;
@property (weak, nonatomic) IBOutlet UIImageView *curPhoto;
@property (weak, nonatomic) IBOutlet UIButton *btnTakePhoto;
@property (weak, nonatomic) IBOutlet UILabel *examInfo;
@property (weak, nonatomic) IBOutlet UILabel *stationInfo;
@property (weak, nonatomic) IBOutlet UIButton *btnUpload;
@property (weak, nonatomic) IBOutlet UIButton *btnSettings;
@property (weak, nonatomic) IBOutlet UILabel *txtHit;
@property (weak, nonatomic) IBOutlet UIButton *btnRefresh;
@property (weak, nonatomic) IBOutlet UILabel *nextStudent;
@property (weak, nonatomic) IBOutlet UILabel *nextName;

@property (strong, nonatomic) NSTimer *myTimer;

@property (strong, nonatomic) NSString *imgPath;

@property BOOL myTag;
@property int nCount;


- (IBAction)takePhoto:(id)sender;
- (IBAction)uploadPhoto:(id)sender;
- (IBAction)settingPage:(id)sender;
- (IBAction)refreshImage:(id)sender;

@end
