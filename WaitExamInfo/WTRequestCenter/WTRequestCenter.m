//
//  WTRequestCenter.m
//  TestCache
//
//  Created by song on 14-7-19.
//  Copyright (c) Mike song(mailto:275712575@qq.com). All rights reserved.
//  site:https://github.com/swtlovewtt/WTRequestCenter

#import "WTRequestCenter.h"

#define FORM_FLLE_INPUT @"image"

@implementation WTRequestCenter


#pragma mark - 请求队列和缓存
//请求队列
static NSOperationQueue *sharedQueue = nil;
+(NSOperationQueue*)sharedQueue
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedQueue = [[NSOperationQueue alloc] init];
        [sharedQueue setSuspended:NO];
        [sharedQueue setMaxConcurrentOperationCount:10];
        sharedQueue.name = @"WTRequestCentersharedQueue";
    });
    return sharedQueue;
}


//缓存
+(NSURLCache*)sharedCache
{
    NSURLCache *cache = [NSURLCache sharedURLCache];
    //    最大内存空间
    [cache setMemoryCapacity:1024*1024*20];//20M
    //    最大储存（硬盘）空间
    [cache setDiskCapacity:1024*1024*300];//300M
    return cache;
}


#pragma mark - 配置设置

-(BOOL)isRequesting
{
    BOOL requesting = NO;
    NSOperationQueue *sharedQueue = [WTRequestCenter sharedQueue];
    
    if ([sharedQueue operationCount]!=0) {
        requesting = YES;
    }
    return requesting;
}

+(NSUserDefaults*)sharedUserDefaults
{
    UIDevice *currentDevice = [UIDevice currentDevice];
    NSUserDefaults *myUserDefaults = nil;
    if (currentDevice.systemVersion.floatValue>=7.0) {
//        使用新方法
       myUserDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"WTRequestCenter"];
    }else
    {
//    使用旧方法
        myUserDefaults = [[NSUserDefaults alloc] initWithUser:@"WTRequestCenter"];
    }
    return myUserDefaults;
}

//设置失效日期
+(void)setExpireTimeInterval:(NSTimeInterval)expireTime
{
    NSUserDefaults *myUserDefaults = [WTRequestCenter sharedUserDefaults];
    [myUserDefaults setFloat:expireTime forKey:@"WTRequestCenterExpireTime"];
    [myUserDefaults synchronize];
}

//失效日期
+(NSTimeInterval)expireTimeInterval
{
    
    NSUserDefaults *myUserDefaults = [WTRequestCenter sharedUserDefaults];
    CGFloat time = [myUserDefaults floatForKey:@"WTRequestCenterExpireTime"];
    if (time==0) {
//        默认时效日期一天
        time = 3600*24;
    }
    return time;
}

+(BOOL)checkRequestIsExpired:(NSHTTPURLResponse*)request
{
//    NSHTTPURLResponse *res = (NSHTTPURLResponse*)response.response;
    NSDictionary *allHeaderFields = request.allHeaderFields;
    
    NSString *dateString = [allHeaderFields valueForKey:@"Date"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"eee, dd MMM yyyy HH:mm:ss VVVV"];
    [formatter setLocale:[NSLocale currentLocale]];
    NSDate *now = [NSDate date];
    //            NSString *string = [formatter stringFromDate:now];
    //            NSLog(@"%@",string);
    NSDate *date = [formatter dateFromString:dateString];
    //            NSLog(@"%@",date);
    
    NSTimeInterval delta = [now timeIntervalSince1970] - [date timeIntervalSince1970];
    NSTimeInterval expireTimeInterval = [WTRequestCenter expireTimeInterval];
    if (delta<expireTimeInterval) {
//        没有失效
        return NO;
    }else
    {
//        失效了
        return YES;
    }
    
}


//清除所有缓存
+(void)clearAllCache
{
    NSURLCache *cache = [WTRequestCenter sharedCache];
    [cache removeAllCachedResponses];

}

//当前缓存大小
+(NSUInteger)currentDiskUsage
{
    NSURLCache *cache = [WTRequestCenter sharedCache];
    return [cache currentDiskUsage];
}

+(void)cancelAllRequest
{
    [[WTRequestCenter sharedQueue] cancelAllOperations];
}


//清除请求的缓存
+(void)removeRequestCache:(NSURLRequest*)request
{
    NSURLCache *cache = [WTRequestCenter sharedCache];
    [cache removeCachedResponseForRequest:request];
}
#pragma mark - 辅助
+(id)JSONObjectWithData:(NSData*)data
{
    if (!data) {
        return nil;
    }
//    容器解析成可变的，string解析成可变的，并且允许顶对象不是dict或者array
    return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingMutableLeaves|NSJSONReadingAllowFragments error:nil];
}



#pragma mark - Get

//get请求
//Available in iOS 5.0 and later.
+(NSURLRequest*)getWithURL:(NSURL*)url parameters:(NSDictionary*)parameters completionHandler:(void (^)(NSURLResponse* response,NSData *data,NSError *error))handler
{
    NSURLCache *cache = [WTRequestCenter sharedCache];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30.0];
    if (parameters) {
        NSMutableString *paramString = [[NSMutableString alloc] init];
        for (NSString *key in [parameters allKeys]) {
            NSString *value = [parameters valueForKey:key];
            NSString *str = [NSString stringWithFormat:@"%@=%@",key,value];
            [paramString appendString:str];
            [paramString appendString:@"&"];
        }
        NSMutableString *urlString = [[NSMutableString alloc] initWithFormat:@"%@?%@",url,paramString];
        urlString = [[[urlString copy] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] mutableCopy];
        request.URL = [NSURL URLWithString:urlString];
    }
   
    NSCachedURLResponse *response =[cache cachedResponseForRequest:request];
    
    if (!response) {
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[WTRequestCenter sharedQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError)
         {
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 if (handler) {
                     handler(response,data,connectionError);
                 }
             });
         }];
    }else
    {
        //NSDateFormatter 在iOS7.0以后是线程安全的，为了保证5.0可用，在这里用主线程括起来
        
            
            if ([response.response isKindOfClass:[NSHTTPURLResponse class]]) {
                
                BOOL isExpired = [WTRequestCenter checkRequestIsExpired:(NSHTTPURLResponse*)response.response];
                if (isExpired) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                    if (handler) {
                        handler(response.response,response.data,nil);
                    }
                    });
                    [WTRequestCenter removeRequestCache:request];
                    [WTRequestCenter getWithURL:url parameters:parameters completionHandler:handler];
                }else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                    if (handler) {
                        handler(response.response,response.data,nil);
                    }
                    });
                }
                
                
                
            }
            
        
    }
    
    return request;
}



#pragma mark - POST
// post 请求
//Available in iOS 5.0 and later.
//parameters
+(NSURLRequest*)postWithURL:(NSURL*)url parameters:(NSDictionary*)parameters completionHandler:(void (^)(NSURLResponse* response,NSData *data,NSError *error))handler
{
    NSURLCache *cache = [WTRequestCenter sharedCache];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url
                cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:10.0];
    [request setHTTPMethod:@"POST"];
    
    NSMutableString *paramString = [[NSMutableString alloc] init];
    for (NSString *key in [parameters allKeys]) {
        NSString *value = [parameters valueForKey:key];
        NSString *str = [NSString stringWithFormat:@"%@=%@",key,value];
        [paramString appendString:str];
        [paramString appendString:@"&"];
    }
    NSLog(@"\nurl:\n%@  \nparameters:\n%@",url,parameters);
    paramString = [[paramString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    
    NSData *postData = [paramString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:postData];
    
    NSCachedURLResponse *response =[cache cachedResponseForRequest:request];

    //        如果不存在，重新请求
    if (!response) {

        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[WTRequestCenter sharedQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   
                   dispatch_async(dispatch_get_main_queue(), ^{
                       
                       if (handler) {
               handler(response,data,connectionError);
                       }

                       
                       
                   });//end main
 
        }];
    }else
    {
        //NSDateFormatter 在iOS7.0以后是线程安全的，为了保证5.0可用，在这里用主线程括起来
        
            
            if ([response.response isKindOfClass:[NSHTTPURLResponse class]]) {
                
                BOOL isExpired = [WTRequestCenter checkRequestIsExpired:(NSHTTPURLResponse*)response.response];
                if (isExpired) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                    if (handler) {
                        handler(response.response,response.data,nil);
                    }
                    });
                    [WTRequestCenter removeRequestCache:request];
                    [WTRequestCenter postWithURL:url parameters:parameters completionHandler:handler];
                }else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                    if (handler) {
                        handler(response.response,response.data,nil);
                    }
                     });
                }
                
                
                
            }
            
            
       
    }

    return request;
}

+(NSURLRequest*)postWithoutCacheURL:(NSURL*)url parameters:(NSDictionary*)parameters completionHandler:(void (^)(NSURLResponse* response,NSData *data,NSError *error))handler
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
                                                                //cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30.0];
    [request setHTTPMethod:@"POST"];
    
    NSMutableString *paramString = [[NSMutableString alloc] init];
    for (NSString *key in [parameters allKeys]) {
        NSString *value = [parameters valueForKey:key];
        NSString *str = [NSString stringWithFormat:@"%@=%@",key,value];
        [paramString appendString:str];
        [paramString appendString:@"&"];
    }
    
    paramString = [[paramString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    
    NSData *postData = [paramString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:postData];
    [self removeRequestCache:request];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[WTRequestCenter sharedQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) {
        handler(response,data,connectionError);
            }
        });
        
    }];
                       
    return request;
}

+(NSURLRequest*)postImageWithoutCacheURL:(NSURL*)url parameters:(NSDictionary*)parameters imgpath:(NSString *)imgpath completionHandler:(void (^)(NSURLResponse* response,NSData *data,NSError *error))handler
{
    
    ////
    NSString *TWITTERFON_FORM_BOUNDARY = @"0xKhTmLbOuNdArY";
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url
                                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    //分界线 --AaB03x
    NSString *MPboundary=[[NSString alloc]initWithFormat:@"--%@",TWITTERFON_FORM_BOUNDARY];
    //结束符 AaB03x--
    NSString *endMPboundary=[[NSString alloc]initWithFormat:@"%@--",MPboundary];
    //得到图片的data
    NSData* data;
    if(imgpath){
        
        UIImage *image=[UIImage imageWithContentsOfFile:imgpath];
        //判断图片是不是png格式的文件
        if (UIImagePNGRepresentation(image)) {
            //返回为png图像。
            data = UIImagePNGRepresentation(image);
        }else {
            //返回为JPEG图像。
            data = UIImageJPEGRepresentation(image, 1.0);
        }
    }
    
    //http body的字符串
    NSMutableString *body=[[NSMutableString alloc]init];
    //参数的集合的所有key的集合
    NSArray *keys= [parameters allKeys];
    
    //遍历keys
    for(int i=0;i<[keys count];i++)
    {
        //得到当前key
        NSString *key=[keys objectAtIndex:i];
        
        //添加分界线，换行
        [body appendFormat:@"%@\r\n",MPboundary];
        //添加字段名称，换2行
        [body appendFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",key];
        //添加字段的值
        [body appendFormat:@"%@\r\n",[parameters objectForKey:key]];
        
        //NSLog(@"添加字段的值==%@",[parameters objectForKey:key]);
    }
    
    if(imgpath){
        ////添加分界线，换行
        [body appendFormat:@"%@\r\n",MPboundary];
        
        NSString *fileName = @"image";
        //声明pic字段，文件名为boris.png
        [body appendFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n",FORM_FLLE_INPUT,fileName];
        //声明上传文件的格式
        [body appendFormat:@"Content-Type: image/jpge,image/gif, image/jpeg, image/pjpeg, image/pjpeg\r\n\r\n"];
    }
    
    //声明结束符：--AaB03x--
    NSString *end=[[NSString alloc]initWithFormat:@"\r\n%@",endMPboundary];
    //声明myRequestData，用来放入http body
    NSMutableData *myRequestData=[NSMutableData data];
    
    //将body字符串转化为UTF8格式的二进制
    [myRequestData appendData:[body dataUsingEncoding:NSUTF8StringEncoding]];
    if(parameters){
        //将image的data加入
        [myRequestData appendData:data];
    }
    //加入结束符--AaB03x--
    [myRequestData appendData:[end dataUsingEncoding:NSUTF8StringEncoding]];
    
    //设置HTTPHeader中Content-Type的值
    NSString *content=[[NSString alloc]initWithFormat:@"multipart/form-data; boundary=%@",TWITTERFON_FORM_BOUNDARY];
    //设置HTTPHeader
    [request setValue:content forHTTPHeaderField:@"Content-Type"];
    //设置Content-Length
    [request setValue:[NSString stringWithFormat:@"%d", [myRequestData length]] forHTTPHeaderField:@"Content-Length"];
    //设置http body
    [request setHTTPBody:myRequestData];
    //http method
    [request setHTTPMethod:@"POST"];
    ////
    
    
    [NSURLConnection sendAsynchronousRequest:request queue:[WTRequestCenter sharedQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) {
                handler(response,data,connectionError);
            }
        });
        
    }];
    
    return request;
}

#pragma mark - Image
+(NSURLRequest *)uploadRequestWithURL: (NSURL *)url

                               data: (NSData *)data
                           fileName: (NSString*)fileName
{
    
    // from http://www.cocoadev.com/index.pl?HTTPFileUpload
    
    //NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] init] ;
    urlRequest.URL = url;
    
    [urlRequest setHTTPMethod:@"POST"];
    
    NSString *myboundary = @"---------------------------14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",myboundary];
    [urlRequest addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    
    //[urlRequest addValue: [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundry] forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *postData = [NSMutableData data]; //[NSMutableData dataWithCapacity:[data length] + 512];
    [postData appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", myboundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"userfile\"; filename=\"%@\"\r\n", fileName]dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[NSData dataWithData:data]];
    [postData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", myboundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [urlRequest setHTTPBody:postData];
    return urlRequest;
}


//图片上传
+(void)upLoadImageWithURL:(NSURL*)url
                     data:(NSData *)data
                 fileName:(NSString*)fileName
completionHandler:(void (^)(NSURLResponse* response,NSData *data,NSError *error))handler
{
    NSURLRequest *request = [WTRequestCenter uploadRequestWithURL:url data:data fileName:fileName];
    [NSURLConnection sendAsynchronousRequest:request queue:[WTRequestCenter sharedQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) {
                handler(response,data,connectionError);
            }
        });
    }];
}



//多图片上传
+(void)upLoadImageWithURL:(NSURL*)url
                    datas:(NSArray*)datas
                fileNames:(NSArray*)names
        completionHandler:(void (^)(NSURLResponse* response,NSData *data,NSError *error))handler
{
    for (int i=0; i<[datas count]; i++) {
        NSData *data = datas[i];
        NSString *name = names[i];
        [WTRequestCenter upLoadImageWithURL:url data:data fileName:name completionHandler:handler];
    }
}
 


//下载图片  Download  (Cache)
+(void)getImageWithURL:(NSURL*)url
     completionHandler:(void(^) (UIImage* image))handler
{
    NSURLCache *cache = [WTRequestCenter sharedCache];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:30.0];
    NSCachedURLResponse *response =[cache cachedResponseForRequest:request];
    if (response) {
        if (handler) {
            UIImage *image = [UIImage imageWithData:response.data];
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(image);
            });
            
        }
    }else
    {
        [NSURLConnection sendAsynchronousRequest:request queue:[WTRequestCenter sharedQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            if (handler) {
                UIImage *image = [UIImage imageWithData:data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(image);
                });
            }
        }];
    }
   
}



#pragma mark - URL

+(BOOL)setBaseURL:(NSString*)url
{
    NSUserDefaults *a = [self sharedUserDefaults];
    [a setValue:url forKey:@"baseURL"];
    return [a synchronize];
}

+(NSString *)baseURL
{
    NSUserDefaults *a = [self sharedUserDefaults];
    NSString *url = [a valueForKey:@"baseURL"];
    if (url) {
        return @"http://www.xxx.com";
    }
    return url;

}
//实际应用示例
+(NSString*)urlWithIndex:(NSInteger)index
{
    NSMutableArray *urls = [[NSMutableArray alloc] init];
//    0-9
    [urls addObject:@"article/detail"];
    [urls addObject:@"interface1"];
    [urls addObject:@"interface2"];
    [urls addObject:@"interface3"];
    [urls addObject:@"interface0"];
    [urls addObject:@"interface0"];
    [urls addObject:@"interface0"];
    [urls addObject:@"interface0"];
    [urls addObject:@"interface0"];
    [urls addObject:@"interface0"];
    
//  10-19
    [urls addObject:@"interface0"];
    [urls addObject:@"interface0"];
    [urls addObject:@"interface0"];
    [urls addObject:@"interface0"];
    [urls addObject:@"interface0"];
    [urls addObject:@"interface0"];
    [urls addObject:@"interface0"];
    [urls addObject:@"interface0"];
    [urls addObject:@"interface0"];
    [urls addObject:@"interface0"];
    
    
    
    NSString *url = urls[index];
    NSString *urlString = [NSString stringWithFormat:@"%@/%@",[WTRequestCenter baseURL],url];
    return urlString;
}


+ (NSString *)debugDescription
{
    return @"just a joke";
}

@end
