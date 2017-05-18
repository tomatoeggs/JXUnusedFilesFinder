//
//  JXUnusedFilesFinder.m
//  JXUnusedFilesFinder
//
//  Created by yancywang on 2017/4/12.
//  Copyright © 2017年 yancywang. All rights reserved.
//

#import "JXUnusedFilesFinder.h"
#import "JXFileSearcher.h"
#import "NSString+Tools.h"
#import "JXFileInfo.h"

#define COMMENT_PATTERN_1 @"(/\\*([^/]|[^\\*]/)*\\*/)"  // pattern : /\*([^/]|[^\*]/)*\*/
#define COMMENT_PATTERN_2 @"(//[^\\n]*\\n)"   // pattern : ^([^/\n]|[^/\n]/)*(//[^\n]*\n)

#define IMPORT_PATTERN    @"#\\s*import\\s*\"([^\"]+/)?([a-zA-Z0-9\\+\\._-]+)\\.h\""
#define INCLUDE_PATTERN   @"#\\s*include\\s*\"([^\"]+/)?([a-zA-Z0-9\\+\\._-]+)\\.h\""
#define INCLUDE_PATTERN_2 @"#\\s*include\\s*<([^>]+/)?([a-zA-Z0-9\\+\\._-]+)\\.h>"
#define XIB_PATTERN       @" customClass=\"([a-zA-Z0-9_-]+)\""

@interface JXUnusedFilesFinder ()

@property (nonatomic,strong) NSMutableDictionary<NSString*,JXFileInfo*> *fileKeyDic;
@property (nonatomic,strong) NSMutableArray <NSString *> *resultList;

@end

@implementation JXUnusedFilesFinder

+(instancetype)sharedFinder
{
    static JXUnusedFilesFinder *_sharedObj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _sharedObj = [[JXUnusedFilesFinder alloc] init];
    });
    
    return _sharedObj;
}

-(instancetype)init
{
    self = [super init];
    if (self)
    {
        self.fileKeyDic = [NSMutableDictionary dictionary];
        self.resultList = [NSMutableArray array];
    }
    
    return self;
}

-(void)startSearchInDirectory:(NSString *)directory withSearchOptions:(SearchOptions)searchOptions completion:(SearchCompletionBlock)completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSArray *fileList = [JXFileSearcher filesInDirectory:directory excludeFolders:nil fileSuffixs:@[@"h",@"c",@"m",@"mm",@"cpp",@"pch",@"storyboard"]];
        
        //build file name key dic
        [self.fileKeyDic removeAllObjects];
        for (NSString *filePath in fileList)
        {
            if ([filePath rangeOfString:@".framework/"].length > 0)
            {
                continue;
            }
            
            NSString *fileName = [filePath lastPathComponent];
            NSString *filePathExtension = [fileName pathExtension];
            
            if ([filePathExtension isEqualToString:@"h"] ||
                [filePathExtension isEqualToString:@"pch"] ||
                [filePathExtension isEqualToString:@"storyboard"] ||
                [fileName isEqualToString:@"main.m"])
            {
                NSString *fileKey = [fileName stringByDeletingPathExtension];
                JXFileInfo *fileInfo = [[JXFileInfo alloc] init];
                fileInfo.fileKey = fileKey;
                fileInfo.headerFilePath = filePath;
                
                if ([filePathExtension isEqualToString:@"pch"] ||
                    [filePathExtension isEqualToString:@"storyboard"] ||
                    [fileName isEqualToString:@"main.m"])
                {
                    [fileInfo.parentFileKeyList addObject:@"__jx_system_hold"];
                }
                
                [self.fileKeyDic setObject:fileInfo forKey:fileKey];
            }
        }
        
        for (NSString *filePath in fileList)
        {
            NSString *fileName = [filePath lastPathComponent];
            NSString *filePathExtension = [fileName pathExtension];
            NSString *fileKey = [fileName stringByDeletingPathExtension];
            JXFileInfo *fileInfo = self.fileKeyDic[fileKey];
            if (!fileInfo)
            {
                continue;
            }
            
            if ([filePathExtension isEqualToString:@"c"] ||
                [filePathExtension isEqualToString:@"m"] ||
                [filePathExtension isEqualToString:@"mm"] ||
                [filePathExtension isEqualToString:@"cpp"])
            {
                fileInfo.sourceFilePath = filePath;
            }
            
            NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
            if (!content)
            {
                continue;
            }
            
            content = [content stringByReplacingMatchedComponentWithPattern:COMMENT_PATTERN_1 groupIndex:1 withString:@""];
            content = [content stringByReplacingMatchedComponentWithPattern:COMMENT_PATTERN_2 groupIndex:1 withString:@"\n"];
            if (content)
            {
                NSArray<NSString *> *importedFileName = [content getMatchedStringsWithPattern:IMPORT_PATTERN groupIndex:2];
                NSArray<NSString *> *includedFileName = [content getMatchedStringsWithPattern:INCLUDE_PATTERN groupIndex:2];
                NSArray<NSString *> *includedFileName_2 = [content getMatchedStringsWithPattern:INCLUDE_PATTERN_2 groupIndex:2];
                NSArray<NSString *> *xibHoldFileName = nil;
                if ([filePathExtension isEqualToString:@"storyboard"])
                {
                    xibHoldFileName = [content getMatchedStringsWithPattern:XIB_PATTERN groupIndex:1];
                }
                
                NSArray<NSString*> *subFileNameKeyList = [NSArray array];
                subFileNameKeyList = [subFileNameKeyList arrayByAddingObjectsFromArray:importedFileName];
                subFileNameKeyList = [subFileNameKeyList arrayByAddingObjectsFromArray:includedFileName];
                subFileNameKeyList = [subFileNameKeyList arrayByAddingObjectsFromArray:includedFileName_2];
                subFileNameKeyList = [subFileNameKeyList arrayByAddingObjectsFromArray:xibHoldFileName];
                
                for (NSString *subFileKey in subFileNameKeyList)
                {
                    if ([fileKey isEqualToString:subFileKey])
                    {
                        continue;
                    }
                    
                    JXFileInfo *subFileInfo = self.fileKeyDic[subFileKey];
                    if (subFileInfo)
                    {
                        [subFileInfo.parentFileKeyList addObject:fileKey];
                    }
                }
            }
        }
        
        [self.resultList removeAllObjects];
        [self findUnusedFilesWithOptions:searchOptions completion:(SearchCompletionBlock)completion];
    });
}

-(void)findUnusedFilesWithOptions:(SearchOptions)options completion:(SearchCompletionBlock)completion
{
    NSMutableArray *needDeleteKeyList = [NSMutableArray array];
    
    NSArray *keyList = [self.fileKeyDic.allKeys copy];
    for (NSString *key in keyList)
    {
        if ((options & SearchOptionsIgnoreCategory) > 0)
        {
            if ([key rangeOfString:@"+"].length > 0)
            {
                continue;
            }
        }
        
        JXFileInfo *fileInfo = self.fileKeyDic[key];
        
        if (fileInfo.parentFileKeyList.count == 0 &&
            fileInfo.existSourceFile == YES)
        {
            [self.resultList addObject:fileInfo.headerFilePath];
            [self.resultList addObject:fileInfo.sourceFilePath];
            
            [self.fileKeyDic removeObjectForKey:key];
            [needDeleteKeyList addObject:key];
        }
    }
    
    if (needDeleteKeyList.count > 0)
    {
        for (NSString *needDeleteKey in needDeleteKeyList)
        {
            for (JXFileInfo *fileInfo in self.fileKeyDic.allValues)
            {
                [fileInfo.parentFileKeyList removeObject:needDeleteKey];
            }
        }
        
        [self findUnusedFilesWithOptions:options completion:(SearchCompletionBlock)completion];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (completion)
            {
                completion(self.resultList);
            }
        });
    }
}

@end
