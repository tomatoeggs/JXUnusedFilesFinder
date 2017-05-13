//
//  JXFileInfo.m
//  JXUnusedFilesFinder
//
//  Created by yancywang on 2017/4/12.
//  Copyright © 2017年 yancywang. All rights reserved.
//

#import "JXFileInfo.h"

@implementation JXFileInfo

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        self.parentFileKeyList = [NSMutableArray array];
    }
    
    return self;
}

-(BOOL)existSourceFile
{
    return (self.sourceFilePath && self.sourceFilePath.length > 0);
}

@end
