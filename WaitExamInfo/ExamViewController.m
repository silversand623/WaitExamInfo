//
//  ExamViewController.m
//  WaitExamInfo
//
//  Created by lyn on 14-10-8.
//
//

#import "ExamViewController.h"
#import "WTRequestCenter.h"
#import "RMMapper.h"
#import "UserInfo.h"
#import "StationInfo.h"
#import "AppDelegate.h"
#import "ViewController.h"


@interface ExamViewController ()

@end

@implementation ExamViewController

#define ROWHEIGHT 60
#define FONTSIZE 32

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self customiseAppearance];
    
    _myTag = NO;
    _timeTag = NO;
    _myTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkExam) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_myTimer forMode:NSRunLoopCommonModes];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:[UIApplication sharedApplication]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(startTime)
                                                 name:@"startTime"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clearData)
                                                 name:@"clearData"
                                               object:nil];
    _sChanged = @"未知";
}

- (void)applicationWillEnterForeground {
    _myTag = NO;
    [self getUserInfo];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(CGFloat)getLabelHeight:(NSString *)sContent {
    // 列寬
    CGFloat contentWidth = 700;
    // 用何種字體進行顯示
    
    // 計算出顯示完內容需要的最小尺寸
    UILabel * label = [self examContent];
    //CGSize size = [sContent sizeWithFont:font constrainedToSize:CGSizeMake(contentWidth, 1000.0f) lineBreakMode:UILineBreakModeWordWrap];
    CGRect rect = [sContent boundingRectWithSize:CGSizeMake(contentWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: label.font} context:nil];
    
    double height = ceil(rect.size.height);
    
    label.frame = CGRectMake(label.frame.origin.x, label.frame.origin.y, label.frame.size.width, MAX(height, 48));
    return MAX(height, 48)+72;
}

- (void)customiseAppearance {
    [_remainTime setBoldFont:[UIFont fontWithName:@"HelveticaNeue" size:FONTSIZE]];
    [_remainTime setRegularFont:[UIFont fontWithName:@"HelveticaNeue" size:FONTSIZE]];
    
    // The font property of the label is used as the font for H,M,S and MS
    [_remainTime setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:28]];
    
    // Default label properties
    //_counterLabel.textColor = [UIColor darkGrayColor];
    [_remainTime setDisplayMode:kDisplayModeSeconds];
    _remainTime.countDirection = kCountDirectionDown;
    _remainTime.countdownDelegate = self;
    // After making any changes we need to call update appearance
    [_remainTime setTextAlignment:NSTextAlignmentLeft];
    [_remainTime updateApperance];
    
    [_curTime setBoldFont:[UIFont fontWithName:@"HelveticaNeue" size:FONTSIZE]];
    [_curTime setRegularFont:[UIFont fontWithName:@"HelveticaNeue" size:FONTSIZE]];
    
    // The font property of the label is used as the font for H,M,S and MS
    [_curTime setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:28]];
    
    // Default label properties
    //_counterLabel.textColor = [UIColor darkGrayColor];
    [_curTime setDisplayMode:kDisplayModeSeconds];
    _curTime.countDirection = kCountDirectionUp;
    //_remainTime.countdownDelegate = self;
    // After making any changes we need to call update appearance
    [_curTime setTextAlignment:NSTextAlignmentLeft];
    [_curTime updateApperance];
}

- (void)countdownDidEndForSource:(TTCounterLabel *)source {
    _myTag = NO;
    //[self getUserInfo];
    if (_remainTime.isRunning) {
        [_remainTime stop];
        
    }
    [self clearData];
}

-(void)clearData
{
    if (_remainTime.isRunning) {
        [_remainTime stop];
        
    }
    
    [[self curStudent] setText:@""];
    [[self examTime] setText:@""];
    [[self examStatus] setText:@""];
    [[self nextStation] setText:@""];
    [[self examSubject] setText:@""];
    [[self examContent] setText:@""];
    //[[self nextStudent] setText:@""];
    [[self stuName] setText:@""];
    //[[self nextName] setText:@""];
}

-(void)checkExam
{
    _nCount++;
    if ((_nCount%30) <= 5 || (_nCount%30) >=25) {
        _myTag = NO;
        
    }else
    {
        _myTag = YES;
    }
    if (_myTag==NO) {
        [self getExamState];
        
    }
}

-(void) getExamState
{
    //NSLog(@"start get exam=====");
    
    
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    NSMutableDictionary *params=[[NSMutableDictionary alloc] init];
    if ([defaults objectForKey:@"Room"] == nil || [defaults objectForKey:@"IPConfig"]==nil) {
        return;
    }
    [params setObject:[defaults objectForKey:@"Room"] forKey:@"RoomName"];
    
    NSString *BaseUrl=[defaults objectForKey:@"IPConfig"];
    NSString *url=@"http://";
    url=[url stringByAppendingString:BaseUrl];
    url=[url stringByAppendingFormat:@"%@",@"/AppDataInterface/ExamInfoShow.aspx/SendExamState"];
    NSURL *TempUrl = [NSURL URLWithString:url];
    
    [WTRequestCenter postWithoutCacheURL:TempUrl
                              parameters:params completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                  if (!error) {
                                      NSError *jsonError = nil;
                                      //[HUD hide:YES afterDelay:1];
                                      
                                      id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                                      if (!jsonError) {
                                          ///
                                          
                                          NSString *state = [obj objectForKey:@"UpdateState"];
                                          //NSLog(@"start get exam1111=====%@",state);
                                          //if ([state isEqualToString:@"1"] ) {
                                              //NSLog(@"start get getUserInfo ok=====");
                                              [self getUserInfo];
                                          //}
                                          
                                          
                                          ////
                                      }else
                                      {
                                          NSLog(@"jsonError:%@",jsonError);
                                          //UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"json格式错误" message:[jsonError localizedDescription] delegate:nil cancelButtonTitle:@"确//定" otherButtonTitles:nil];
                                          //[alert show];
                                      }
                                      
                                  }else
                                  {
                                      /*//[HUD hide:YES];
                                      UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"网络连接错误" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                                      [alert show];
                                      NSLog(@"error:%@",error);*/
                                  }
                                  
                              }];
}

-(void)startTime
{
    
    AppDelegate *appDelegate=[[UIApplication sharedApplication] delegate];
    StationInfo *Station = appDelegate.gStationInfo;
    if (Station != nil) {
        NSLocale* local =[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        NSDateFormatter* formater = [[NSDateFormatter alloc] init];
        [formater setLocale: local];
        [formater setDateFormat:@"HH:mm:ss"];
        NSDate* date = [formater dateFromString:Station.SystemTime];
        NSCalendar*calendar = [NSCalendar currentCalendar];
        NSDateComponents*comps;
        comps =[calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit |NSSecondCalendarUnit) fromDate:date];
        
        NSInteger hour = [comps hour];
        
        NSInteger minute = [comps minute];
        
        NSInteger second = [comps second];
        _nCount = second;
        if ([_curTime isRunning]) {
            [_curTime stop];
        }
        [_curTime setStartValue:(hour*60*60+minute*60+second)*1000];
        [_curTime start];
       //NSLog(@"start total time%@=====",Station.SystemTime);
        //_sChanged = @"未知";
        [[self examSubject] setText:[Station.Curriculum stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [[self examContent] setText:[Station.Content stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        //NSString *str = [Station.Content stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self getUserInfo];
        [[self tableView] reloadData];
    }
    
}

-(void) getUserInfo
{
    AppDelegate *appDelegate=[[UIApplication sharedApplication] delegate];
    appDelegate.gUID = nil;
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    NSMutableDictionary *params=[[NSMutableDictionary alloc] init];
    if ([defaults objectForKey:@"Room"] == nil || [defaults objectForKey:@"IPConfig"]==nil) {
        return;
    }
    [params setObject:[defaults objectForKey:@"Room"] forKey:@"RoomName"];
    
    NSString *BaseUrl=[defaults objectForKey:@"IPConfig"];
    NSString *url=@"http://";
    url=[url stringByAppendingString:BaseUrl];
    url=[url stringByAppendingFormat:@"%@",@"/AppDataInterface/ExamInfoShow.aspx/GetUserInfo"];
    NSURL *TempUrl = [NSURL URLWithString:url];
    
    [WTRequestCenter postWithoutCacheURL:TempUrl
                              parameters:params completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                  if (!error) {
                                      NSError *jsonError = nil;
                                      //[HUD hide:YES afterDelay:1];
                                      
                                      id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                                      if (!jsonError) {
                                          ///
                                          
                                        
                                        NSString *str = [obj objectForKey:@"result"];
                                          //NSLog(@"start get userinfo ====%@",str);
                                              if (str != nil) {
                                              int nResult = [str intValue];
                                              if (nResult == 1) {
                                                  
                                                  AppDelegate *appDelegate=[[UIApplication sharedApplication] delegate];
                                                  StationInfo *Station = appDelegate.gStationInfo;
                                                  
                                                  
                                                  UserInfo* Info = [RMMapper objectWithClass:[UserInfo class]
                                                                              fromDictionary:obj];
                                                  [[self curStudent] setText:Info.UName];
                                                  //[[self curStudent] setText:[NSString stringWithFormat:@"考号: %@",Info.StuExamNumber]];
                                                  //[[self stuName] setText:[NSString stringWithFormat:@"姓名: %@",Info.UName]];
                                                  [[self examStatus] setText:Info.StuState];
                                                  [[self nextStation] setText:[Info.NextESName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                                                  //[[self nextStudent] setText:Info.NextStuExamNumber];
                                                  //[[self nextStudent] setText:[NSString stringWithFormat:@"考号: %@",Info.NextStuExamNumber]];
                                                  //[[self nextName] setText:[NSString stringWithFormat:@"姓名: %@",Info.NextUName]];
                                                  [[self examSubject] setText:[Station.Curriculum stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                                                  [[self examContent] setText:[Station.Content stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                                                  
                                                  id obj = [self parentViewController];
                                                  ViewController *myView = (ViewController*)obj;
                                                  
                                                  [[myView nextStudent] setText:[Info.NextUName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                                                  
                                                  NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
                                                  NSString *BaseUrl=[defaults objectForKey:@"IPConfig"];
                                                  NSString *url=@"http://";
                                                  url=[url stringByAppendingString:BaseUrl];
                                                  url=[url stringByAppendingFormat:@"/AppDataInterface/HandScore.aspx/SearchStudentPhoto?U_ID=%@",Info.CurrentUID];
                                                  NSURL *TempUrl = [NSURL URLWithString:url];
                                                  [WTRequestCenter getImageWithURL:TempUrl completionHandler:^(UIImage *image) {
                                                      if (image != nil) {
                                                          [[myView netPhoto] setImage:image];
                                                      }
                                                      else {
                                                          NSString *path = [[NSBundle mainBundle] pathForResource:@"studentphoto" ofType:@"jpg"];
                                                          [[myView netPhoto] setImage:[UIImage imageWithContentsOfFile:path]];
                                                      }
                                                      
                                                  }];
                                                  
                                                  appDelegate.gUID = Info.CurrentUID;
                                                  
                                                  _myTag = YES;
                                                  
                                                  double nSec = 0.0f;
                                                  double nSecExam = 0.0f;
                                                  double nSecScore = 0.0f;
                                                  
                                                  
                                                  
                                                  [[self examTime] setText:[NSString stringWithFormat:@"%@--%@",Info.StuStartTime,Info.StuEndTime]];
                                                  BOOL bChanged = YES;
                                                  
                                                  if ([Info.StuState isEqualToString:@"评分中"]) {
                                                      NSLog(@"start pingfenzhong====");
                                                      nSecScore = [Station.StationScoreTime doubleValue];
                                                      nSec=nSecScore;
                                                      
                                                  }
                                                  if ([Info.StuState isEqualToString:@"考试中"]) {
                                                      nSecExam = [Station.StationExamTime doubleValue];
                                                      nSec = nSecExam;
                                                      
                                                  }
                                                  
                                                  //NSLog(@"清除图片qianqianqianqian===%@====%@===",_sChanged,Info.StuState);
                                                  
                                                  if (![_sChanged isEqualToString:Info.StuState]) {
                                                      _sChanged = Info.StuState;
                                                      //NSLog(@"清除图片===%@====%@===",_sChanged,Info.StuState);
                                                      bChanged = YES;
                                                      if ([Info.StuState isEqualToString:@"考试中"]) {
                                                          NSString *path = [[NSBundle mainBundle] pathForResource:@"studentphoto" ofType:@"jpg"];
                                                          [[myView curPhoto] setImage:[UIImage imageWithContentsOfFile:path]];
                                                          [[myView txtHit] setHidden:NO];
                                                      }
                                                  }
                                                  NSLog(@"bchaged, bfresh ====%d",bChanged);
                                                  
                                                  if (bChanged) {
                                                      NSLocale* local =[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
                                                      NSDateFormatter* formater = [[NSDateFormatter alloc] init];
                                                      [formater setLocale: local];
                                                      [formater setDateFormat:@"HH:mm:ss"];
                                                      NSDate* date = [formater dateFromString:Info.StuStartTime];
                                                      NSCalendar*calendar = [NSCalendar currentCalendar];
                                                      NSDateComponents*comps;
                                                      comps =[calendar components:(NSHourCalendarUnit | NSMinuteCalendarUnit |NSSecondCalendarUnit) fromDate:date];
                                                      
                                                      NSInteger hour = [comps hour];
                                                      
                                                      NSInteger minute = [comps minute];
                                                      
                                                      double second = [comps second];
                                                      
                                                      double dInterval = [_curTime currentValue]/1000;
                                                      BOOL bFreshTag = YES;
                                                      NSLog(@"time interval is ======%f",dInterval);
                                                      if (dInterval > 0.1) {
                                                          if (nSecExam > 0) {
                                                              second = nSecExam*60+second;
                                                          }
                                                          if (nSecScore > 0) {
                                                              second = nSecScore*60+[Station.StationExamTime doubleValue]*60+second;
                                                          }
                                                          //NSLog(@"second is  ======%d",second);
                                                          nSec = fabs((hour*60*60+minute*60+second)-dInterval);
                                                          if (nSecExam > 0) {
                                                              if (nSec > (nSecExam*60+5)) {
                                                                  bFreshTag = NO;
                                                              }
                                                          }
                                                          
                                                          if (nSecScore > 0) {
                                                              if (nSec > (nSecScore*60+5)) {
                                                                  bFreshTag = NO;
                                                              }
                                                          }
                                                          //NSLog(@"dao jishi is ========%f===%d===%f",fabs(_remainTime.currentValue/1000 - nSec),_remainTime.currentValue/1000,nSec);
                                                          if (fabs(_remainTime.currentValue/1000 - nSec) <2.0f)
                                                          {
                                                              bFreshTag = NO;
                                                          }
                                                      }
                                                      
                                                      
                                                      if (bFreshTag) {
                                                          NSLog(@"dao jishi is ========%f",nSec);
                                                          if (_remainTime.isRunning) {
                                                              [_remainTime stop];
                                                              
                                                          }
                                                          
                                                              [_remainTime setStartValue:nSec*1000];
                                                              [_remainTime start];
                                                          
                                                      }
                                                      
                                                      
                                                      
                                                      bChanged = NO;
                                                  }
                                                  
                                              }
                                          }
                                          
                                          ////
                                      }else
                                      {
                                          //NSLog(@"jsonError:%@",jsonError);
                                          //UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"json格式错误" message:[jsonError localizedDescription] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                                          //[alert show];
                                      }
                                      
                                  }else
                                  {
                                      //[HUD hide:YES];
                                      //UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"网络连接错误" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                                      //[alert show];
                                      NSLog(@"error:%@",error);
                                  }
                                  
                              }];
}

-(int)dealError:(NSString *) result{
    int nCase = [result integerValue];
    switch (nCase) {
        case 1:
        {
            UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"用户名密码错误" message:@"用户名输入错误" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            break;
        }
        case 2:
        {
            UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"用户名密码错误" message:@"密码输入错误" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            break;
        }
        case 3:
        {
            UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"考试信息" message:@"当前时间没有考试" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            break;
        }
        case 4:
        {
            break;
        }
        default:
        {
            UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"其它错误" message:@"其他内部错误" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            break;
        }
    }
    
    return nCase;
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if ([indexPath section] == 1)
    {
        //return 200;
        NSString * content = [self.examContent text];
        if (content != nil) {
            
            return [self getLabelHeight:content];
        }
    }
    
    // 這裏返回需要的高度
    return ROWHEIGHT;
}           

//页面将要进入前台，开启定时器
-(void)viewWillAppear:(BOOL)animated
{
    //开启定时器
    //[_myTimer setFireDate:[NSDate distantPast]];
    //_myTag = NO;
}

//页面消失，进入后台不显示该页面，关闭定时器
-(void)viewDidDisappear:(BOOL)animated
{
    //关闭定时器
    //[_myTimer setFireDate:[NSDate distantFuture]];
}

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
