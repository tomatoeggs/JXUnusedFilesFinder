//
//  JXUnusedFilesFinder.h
//  JXUnusedFilesFinder
//
//  Created by yancywang on 2017/4/12.
//  Copyright © 2017年 yancywang. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, SearchOptions) {
    
    SearchOptionsIgnoreCategory = 1 << 0
};

typedef void(^SearchCompletionBlock)(NSArray *resultList);

@interface JXUnusedFilesFinder : NSObject

+(instancetype)sharedFinder;

-(void)startSearchInDirectory:(NSString *)directory withSearchOptions:(SearchOptions)searchOptions completion:(SearchCompletionBlock)completion;

@end
