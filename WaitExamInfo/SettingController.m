//
//  SettingController.m
//  WaitExamInfo
//
//  Created by lyn on 14-12-18.
//
//

#import "SettingController.h"
#import "ComboxView.h"
#import "WTRequestCenter.h"
#import "RoomInfo.h"
#import "RMMapper.h"

@interface SettingController ()

@end

@implementation SettingController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    NSString *BaseUrl=[defaults objectForKey:@"IPConfig"];
    if (BaseUrl != nil) {
        _txtServerIP.text = BaseUrl;
    }
    
    
    _RoomArray = [[NSMutableArray alloc] init];
    
    _comView = [[ComboxView alloc] initWithFrame:CGRectMake(302, 210, 300, 100)];
    [self.view addSubview:_comView];
    
    if ([defaults objectForKey:@"Room"] != nil)
    {
        _comView.textField.text = [defaults objectForKey:@"Room"];
    }
    
    [self getRoomInfo];
}

-(void) getRoomInfo
{
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    NSMutableDictionary *params=[[NSMutableDictionary alloc] init];
    
    if ([defaults objectForKey:@"IPConfig"]==nil) {
        return;
    }
    //[params setObject:[defaults objectForKey:@"Room"] forKey:@"RoomName"];
    
    NSString *BaseUrl=[defaults objectForKey:@"IPConfig"];
    NSString *url=@"http://";
    url=[url stringByAppendingString:BaseUrl];
    url=[url stringByAppendingFormat:@"%@",@"/AppDataInterface/ExamInfoShow.aspx/GetRoomInfoUTF8"];
    NSURL *TempUrl = [NSURL URLWithString:url];
    
    [WTRequestCenter postWithoutCacheURL:TempUrl
                              parameters:params completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                                  if (!error) {
                                      NSError *jsonError = nil;
                                      //[HUD hide:YES afterDelay:1];
                                      
                                      id obj = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                                      if (!jsonError) {
                                          ///
                                          
                                          /*
                                          NSString *str = [obj objectForKey:@"result"];
                                          if (str != nil) {
                                              int nResult = [str integerValue];
                                              if (nResult == 1) {
                                                  NSMutableArray* Info = [RMMapper mutableArrayOfClass:[RoomInfo class]
                                                                                    fromArrayOfDictionary:obj];
                                                  for (int i=0;i<Info.count;i++){
                                                      [_RoomArray addObject:Info[i]];
                                                      
                                                  }
                                                  
                                      
                                              }
                                          } */
                                          
                                          NSMutableArray* Info = [RMMapper mutableArrayOfClass:[RoomInfo class]
                                                                         fromArrayOfDictionary:obj];
                                          for (int i=0;i<Info.count;i++){
                                              [_RoomArray addObject:Info[i]];
                                              
                                          }
                                          _comView.tableArray = _RoomArray;
                                          _comView.delegate = self;
                                          //_comView.textField.text = [defaults objectForKey:@"Room"];
                                          [_comView.dropTableView reloadData];
                                          ////
                                      }else
                                      {
                                          NSLog(@"jsonError:%@",jsonError);
                                          UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"json格式错误" message:[jsonError localizedDescription] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                                          [alert show];
                                      }
                                      
                                  }else
                                  {
                                      //[HUD hide:YES];
                                      UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"网络连接错误" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                                      [alert show];
                                      NSLog(@"error:%@",error);
                                  }
                                  
                              }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)passValue:(NSInteger )value{
    _nValue = value;
    UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"选择房间提示信息" message:@"是否确认选择当前房间" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消",nil ] ;
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex==0){
        NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
        //[self presentViewController:SettingController animated:YES completion:nil];
        RoomInfo * info = (RoomInfo*)[_RoomArray objectAtIndex:_nValue];
        [defaults setObject:[info.RoomName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:@"Room"];
        [defaults synchronize];
    }
}

- (IBAction)quitSetting:(id)sender {
}

- (IBAction)confirmIP:(id)sender {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    [defaults setObject:_txtServerIP.text forKey:@"IPConfig"];
    [defaults synchronize];
    [self getRoomInfo];
}
@end
