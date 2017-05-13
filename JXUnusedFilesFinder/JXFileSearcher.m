//
//  JXFileSearcher.m
//  JXUnusedFilesFinder
//
//  Created by yancywang on 2017/4/12.
//  Copyright © 2017年 yancywang. All rights reserved.
//

#import "JXFileSearcher.h"

@implementation JXFileSearcher

+(NSArray *)filesInDirectory:(NSString *)directoryPath excludeFolders:(NSArray *)excludeFolders fileSuffixs:(NSArray *)fileSuffixs
{
    if (directoryPath.length == 0 || fileSuffixs.count == 0)
    {
        return nil;
    }
    
    NSMutableArray *resources = [NSMutableArray array];
    
    for (NSString *fileType in fileSuffixs)
    {
        NSArray *pathList = [self searchDirectory:directoryPath excludeFolders:excludeFolders forFiletype:fileType];
        
        if (pathList.count)
        {
            [resources addObjectsFromArray:pathList];
        }
    }
    
    return resources;
}

+(NSArray *)searchDirectory:(NSString *)directoryPath excludeFolders:(NSArray *)excludeFolders forFiletype:(NSString *)filetype
{
    // Create a find task
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/bin/find"];
    
    // Search for all files
    NSMutableArray *argvals = [NSMutableArray array];
    [argvals addObject:directoryPath];
    [argvals addObject:@"-name"];
    [argvals addObject:[NSString stringWithFormat:@"*.%@", filetype]];
    
    for (NSString *folder in excludeFolders)
    {
        [argvals addObject:@"!"];
        [argvals addObject:@"-path"];
        [argvals addObject:[NSString stringWithFormat:@"*/%@/*", folder]];
    }
    
    [task setArguments: argvals];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    NSFileHandle *file = [pipe fileHandleForReading];
    
    // Run task
    [task launch];
    
    // Read the response
    NSData *data = [file readDataToEndOfFile];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // See if we can create a lines array
    if (string.length)
    {
        NSArray *lines = [string componentsSeparatedByString:@"\n"];
        return lines;
    }
    
    return nil;
}

// Toooooo Sloooooow
+(NSArray *)searchDirectory:(NSString *)directoryPath excludeFolders:(NSArray *)excludeFolders forFiletypes:(NSArray *)filetypes
{
    // find -E . -iregex ".*\.(html|plist)" ! -path "*/Movies/*" ! -path "*/Downloads/*" ! -path "*/Music/*"
    // Create a find task
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/usr/bin/find"];
    
    // Search for all files
    NSMutableArray *argvals = [NSMutableArray array];
    [argvals addObject:@"-E"];
    [argvals addObject:directoryPath];
    [argvals addObject:@"-iregex"];
    
    [argvals addObject:[NSString stringWithFormat:@".*\\.(%@)", [filetypes componentsJoinedByString:@"|"]]];
    
    for (NSString *folder in excludeFolders)
    {
        [argvals addObject:@"!"];
        [argvals addObject:@"-path"];
        [argvals addObject:[NSString stringWithFormat:@"*/%@/*", folder]];
    }
    
    [task setArguments: argvals];
    
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    NSFileHandle *file = [pipe fileHandleForReading];
    
    // Run task
    [task launch];
    
    // Read the response
    NSData *data = [file readDataToEndOfFile];
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    // See if we can create a lines array
    if (string.length)
    {
        NSArray *lines = [string componentsSeparatedByString:@"\n"];
        return lines;
    }
    
    return nil;
}

@end
