//
//  DropDown.m
//  UICombox
//
//  Created by Ralbatr on 14-3-17.
//  Copyright (c) 2014年 Ralbatr. All rights reserved.
//

#define HEIGHT 48

#import "ComboxView.h"
#import "RoomInfo.h"

@implementation ComboxView

-(id)initWithFrame:(CGRect)frame
{
    if (frame.size.height<250) {
        frameHeight = 250;
    }else{
        frameHeight = frame.size.height;
    }
    tabheight = frameHeight-HEIGHT;
    
    frame.size.height = HEIGHT;
    
    self = [super initWithFrame:frame];
    
    if(self){
        showList = NO; //默认不显示下拉框
        
        [self creatTableView:frame];
        
        _textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, HEIGHT)];
        _textField.font = [UIFont systemFontOfSize:27.0f];
        _textField.borderStyle=UITextBorderStyleLine;//设置文本框的边框风格
        _textField.inputView=[[UIView alloc]initWithFrame:CGRectZero];
        _textField.delegate = self;
        [self addSubview:_textField];
        
    }
    return self;
}

- (void)creatTableView:(CGRect)frame
{
    _dropTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, HEIGHT, frame.size.width, 0)];
    _dropTableView.delegate = self;
    _dropTableView.dataSource = self;
    _dropTableView.hidden = YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [self dropdown];
    return NO;
}

- (void)closeTableView
{
    if (showList) {
        [self.dropTableView setHidden:YES];
         [_dropTableView removeFromSuperview];
         showList = NO;
         
    }
}

-(void)dropdown{

    if (showList)
    {//如果下拉框已显示，什么都不做
        return;
    }
    else
    {//如果下拉框尚未显示，则进行显示
        
        CGRect sf = self.frame;
        sf.size.height = frameHeight;
        [self addSubview:_dropTableView];        
        //把dropdownList放到前面，防止下拉框被别的控件遮住
        [self.superview bringSubviewToFront:self];
        _dropTableView.hidden = NO;
        showList = YES;//显示下拉框
        
        CGRect frame = _dropTableView.frame;
        frame.size.height = 0;
        _dropTableView.frame = frame;
        frame.size.height = tabheight;
        [UIView beginAnimations:@"ResizeForKeyBoard" context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        self.frame = sf;
        _dropTableView.frame = frame;
        [UIView commitAnimations];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_tableArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    RoomInfo * info = (RoomInfo*)[_tableArray objectAtIndex:[indexPath row]];
    NSString *strExam = nil;
    if ([info.State isEqualToString:@"1"]) {
        strExam = @"(有考试)";
    } else
    {
        strExam = @"(没有考试)";
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@%@", [info.RoomName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],strExam ];
    cell.textLabel.font = [UIFont systemFontOfSize:27.0f];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
    
    return cell;
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return HEIGHT;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    RoomInfo * info = (RoomInfo*)[_tableArray objectAtIndex:[indexPath row]];
    NSString *strExam = nil;
    if ([info.State isEqualToString:@"1"]) {
        strExam = @"(有考试)";
    } else
    {
        strExam = @"(没有考试)";
    }
    //_textField.text = [NSString stringWithFormat:@"%@%@", [info.RoomName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding],strExam ];
    _textField.text = [info.RoomName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    showList = NO;
    _dropTableView.hidden = YES;
    
    CGRect sf = self.frame;
    sf.size.height = HEIGHT;
    self.frame = sf;
    CGRect frame = _dropTableView.frame;
    frame.size.height = 0;
    _dropTableView.frame = frame;
    //选择完后，移除
    [_dropTableView removeFromSuperview];
    
    [[self delegate] passValue:indexPath.row];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


@end
