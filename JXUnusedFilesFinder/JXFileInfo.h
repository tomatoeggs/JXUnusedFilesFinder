//
//  JXFileInfo.h
//  JXUnusedFilesFinder
//
//  Created by yancywang on 2017/4/12.
//  Copyright © 2017年 yancywang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JXFileInfo : NSObject

@property (nonatomic,strong) NSString *fileKey;
@property (nonatomic,strong) NSString *headerFilePath;
@property (nonatomic,strong) NSString *sourceFilePath;

@property (nonatomic,strong) NSMutableArray *parentFileKeyList;

@property (nonatomic,readonly) BOOL existSourceFile;

@end
