//
//  StationInfo.h
//  WaitExamInfo
//
//  Created by lyn on 14-10-16.
//
//

#import <Foundation/Foundation.h>

@interface StationInfo : NSObject

@property (strong,nonatomic) NSString *result;
@property (strong,nonatomic) NSString *ExamName;
@property (strong,nonatomic) NSString *Curriculum;
@property (strong,nonatomic) NSString *Content;
@property (strong,nonatomic) NSString *ExamKind;
@property (strong,nonatomic) NSString *StationExamTime;
@property (strong,nonatomic) NSString *StationScoreTime;
@property (strong,nonatomic) NSString *EsName;
@property (strong,nonatomic) NSString *RoomName;
@property (strong,nonatomic) NSString *ShortStationExamTime;
@property (strong,nonatomic) NSString *ShortStationScoreTime;
@property (strong,nonatomic) NSString *SystemTime;

@end
