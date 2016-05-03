//
//  UserInfo.h
//  WaitExamInfo
//
//  Created by lyn on 14-10-16.
//
//

#import <Foundation/Foundation.h>

@interface UserInfo : NSObject

@property (strong,nonatomic) NSString *result;
@property (strong,nonatomic) NSString *ExamState;
@property (strong,nonatomic) NSString *StuState;
@property (strong,nonatomic) NSString *StuExamNumber;
@property (strong,nonatomic) NSString *CurrentUID;
@property (strong,nonatomic) NSString *UName;
@property (strong,nonatomic) NSString *NextESName;
@property (strong,nonatomic) NSString *StuStartTime;
@property (strong,nonatomic) NSString *StuEndTime;
@property (strong,nonatomic) NSString *NextStuExamNumber;
@property (strong,nonatomic) NSString *NextUName;
@property (strong,nonatomic) NSString *NextRoomName;
@property (strong,nonatomic) NSString *strSystemTime;
@property (strong,nonatomic) NSString *strStudentStartTime;
@property (strong,nonatomic) NSString *strStationExamTime;
@property (strong,nonatomic) NSString *strStationScoreTime;

@end
