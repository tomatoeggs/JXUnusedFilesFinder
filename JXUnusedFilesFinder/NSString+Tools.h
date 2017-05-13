//
//  NSString+Tools.h
//  JXUnusedFilesFinder
//
//  Created by yancywang on 2017/4/12.
//  Copyright © 2017年 yancywang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Tools)

-(NSArray *)getMatchedStringsWithPattern:(NSString*)pattern groupIndex:(NSInteger)index;

-(NSString *)stringByReplacingMatchedComponentWithPattern:(NSString*)pattern groupIndex:(NSInteger)index withString:(NSString *)string;

-(NSString *)stringByDeletingPathExtension;

@end
