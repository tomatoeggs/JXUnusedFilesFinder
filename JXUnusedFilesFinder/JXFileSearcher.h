//
//  JXFileSearcher.h
//  JXUnusedFilesFinder
//
//  Created by yancywang on 2017/4/12.
//  Copyright © 2017年 yancywang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JXFileSearcher : NSObject

+(NSArray *)filesInDirectory:(NSString *)directoryPath excludeFolders:(NSArray *)excludeFolders fileSuffixs:(NSArray *)fileSuffixs;

@end
