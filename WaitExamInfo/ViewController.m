//
//  ViewController.m
//  WaitExamInfo
//
//  Created by lyn on 14-9-28.
//
//

#import "ViewController.h"
#import "WTRequestCenter.h"
#import "StationInfo.h"
#import "RMMapper.h"
#import "AppDelegate.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _myTag = NO;
    //[self getStationInfo];
    //1 minitures timer
    _myTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkStation) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_myTimer forMode:NSRunLoopCommonModes];
    //[TGCamera setOption:kTGCameraOptionSaveImageToDevice value:NO];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)takePhoto:(id)sender {
    //TGCameraNavigationController *navigationController = [TGCameraNavigationController newWithCameraDelegate:self];
    //[self presentViewController:navigationController animated:YES completion:nil];
    SCNavigationController *nav = [[SCNavigationController alloc] init];
    nav.scNaigationDelegate = self;
    [nav showCameraWithParentController:self];
    
}


-(void)checkStation
{
    _nCount++;
    if ((_nCount%60) <= 5 || (_nCount%60) >=55) {
        _myTag = NO;
        
    }else
    {
        _myTag = YES;
    }
    if (_myTag==NO) {
        [self getStationInfo];
    }
}

- (IBAction)uploadPhoto:(id)sender {
    [self addPhoto];
}

- (IBAction)settingPage:(id)sender {
    UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"设置IP和房间号" message:@"请输入IP地址和房间号" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消",nil ] ;
    alert.alertViewStyle=UIAlertViewStyleLoginAndPasswordInput;
    UITextField *tf=[alert textFieldAtIndex:0];
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    
    tf.keyboardType=UIKeyboardTypeNumberPad;
    [tf setPlaceholder:@"请输入ip，例如192.168.4.132:8080"];      
    tf.text=[defaults objectForKey:@"IPConfig"];
    
    UITextField *tfRoom=[alert textFieldAtIndex:1];
    tfRoom.keyboardType = UIKeyboardTypeNumberPad;
    [tfRoom setSecureTextEntry:NO];
    [tfRoom setPlaceholder:@"请输入房间号，例如602"];
    tfRoom.text = [defaults objectForKey:@"Room"];
    [alert show];
}

- (IBAction)refreshImage:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"studentphoto" ofType:@"jpg"];
    [[self curPhoto] setImage:[UIImage imageWithContentsOfFile:path]];
    [[self txtHit] setHidden:NO];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex==0){
        UITextField *tf=[alertView textFieldAtIndex:0];
        UITextField *tfRoom=[alertView textFieldAtIndex:1];
        NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
        [defaults setObject:tf.text forKey:@"IPConfig"];
        [defaults setObject:tfRoom.text forKey:@"Room"];
        [defaults synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"clearData" object:nil];
        [self clearData];
        [self getStationInfo];
    }
}


-(void)clearData
{
    [[self examInfo] setText:@""];
    [[self stationInfo] setText:@""];
    _imgPath=nil;
}

-(void)savePic:(UIImage *)image
{
    NSString *uuidFile = [NSString stringWithFormat:@"%@.png", [[NSUUID UUID] UUIDString]];
    _imgPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:uuidFile];
    //保存png的图片到app下的Document/
    UIImage *saveImg = [self scaleImage:image toScale:0.3];
    [UIImagePNGRepresentation(saveImg) writeToFile:_imgPath atomically:YES];
}

- (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize

{
    
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scaleSize, image.size.height * scaleSize));
                                [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height * scaleSize)];
                                UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
                                UIGraphicsEndImageContext();
                                
                                return scaledImage;
                                
}

-(void) addPhoto
{
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    NSMutableDictionary *params=[[NSMutableDictionary alloc] init];
    if ([defaults objectForKey:@"Room"] == nil || [defaults objectForKey:@"IPConfig"]==nil || _imgPath == nil) {
        return;
    }
    
    AppDelegate *appDelegate=[[UIApplication sharedApplication] delegate];
    
    [params setObject:[defaults objectForKey:@"Room"] forKey:@"RoomName"];
    
    if (appDelegate.gUID == nil) {
        return;
    }
    
    [params setObject:appDelegate.gUID forKey:@"UID"];
    
    NSString *BaseUrl=[defaults objectForKey:@"IPConfig"];
    NSString *url=@"http://";
    url=[url stringByAppendingString:BaseUrl];
    url=[url stringByAppendingFormat:@"%@",@"/AppDataInterface/ExamInfoShow.aspx/SaveCurrentUserPhoto"];
    NSURL *TempUrl = [NSURL URLWithString:url];
    
    [WTRequestCenter postImageWithoutCacheURL:TempUrl
                                   parameters:params imgpath:self.imgPath completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                       if (!error) {
                                           NSError *jsonError = nil;
                                           
                                           id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                                           if (!jsonError) {
                                               ///
                                               NSString *str = [obj objectForKey:@"result"];
                                               if (str != nil) {
                                                   //int nResult = [self dealError:str];
                                                   //if (nResult == 1) {
                                                       
                                                   
                                                   //}
                                               }
                                               
                                               ////
                                           }else
                                           {
                                               NSLog(@"jsonError:%@",jsonError);
                                               //UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"json格式错误" message:[jsonError localizedDescription] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                                               //[alert show];
                                           }
                                           
                                       }else
                                       {
                                           //UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"网络连接错误" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                                           //[alert show];
                                           NSLog(@"error:%@",error);
                                       }
                                       
                                   }];
}

-(void) getStationInfo
{
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    NSMutableDictionary *params=[[NSMutableDictionary alloc] init];
    
    if ([defaults objectForKey:@"Room"] == nil || [defaults objectForKey:@"IPConfig"]==nil) {
        return;
    }
    [params setObject:[defaults objectForKey:@"Room"] forKey:@"RoomName"];
    
    NSString *BaseUrl=[defaults objectForKey:@"IPConfig"];
    NSString *url=@"http://";
    url=[url stringByAppendingString:BaseUrl];
    url=[url stringByAppendingFormat:@"%@",@"/AppDataInterface/ExamInfoShow.aspx/GetStationInfoUTF8"];
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
                                           if (str != nil) {
                                           int nResult = [str integerValue];
                                           if (nResult == 1) {
                                           
                                               StationInfo* Info = [RMMapper objectWithClass:[StationInfo class]
                                                                              fromDictionary:obj];
                                               
                                               [[self examInfo] setText:[Info.ExamName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                                               [[self stationInfo] setText:[Info.EsName  stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                                               
                                               AppDelegate *appDelegate=[[UIApplication sharedApplication] delegate];
                                               appDelegate.gStationInfo = Info;
                                               
                                               [[NSNotificationCenter defaultCenter] postNotificationName:@"startTime" object:nil];
                                               _myTag = YES;
                                               }
                                           }
                                          
                                          ////
                                      }else
                                      {
                                          NSLog(@"jsonError:%@",jsonError);
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

#pragma mark -
#pragma mark - TGCameraDelegate

- (void)didTakePicture:(SCNavigationController *)navigationController image:(UIImage *)image
{
    _curPhoto.image = image;
    [[self txtHit] setHidden:YES];
    [self savePic:image];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraDidCancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cameraWillTakePhoto
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}


@end
