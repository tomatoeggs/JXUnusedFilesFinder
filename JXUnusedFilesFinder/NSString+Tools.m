//
//  NSString+Tools.m
//  JXUnusedFilesFinder
//
//  Created by yancywang on 2017/4/12.
//  Copyright © 2017年 yancywang. All rights reserved.
//

#import "NSString+Tools.h"

@implementation NSString (Tools)

-(NSArray *)getMatchedStringsWithPattern:(NSString*)pattern groupIndex:(NSInteger)index
{
    NSRegularExpression* regexExpression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive|NSRegularExpressionAnchorsMatchLines error:nil];
    NSArray* matchs = [regexExpression matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    
    if (matchs.count)
    {
        NSMutableArray *list = [NSMutableArray array];
        for (NSTextCheckingResult *checkingResult in matchs)
        {
            NSString *res = [self substringWithRange:[checkingResult rangeAtIndex:index]];
            [list addObject:res];
        }
        
        return list;
    }
    
    return nil;
}

-(NSString *)stringByReplacingMatchedComponentWithPattern:(NSString*)pattern groupIndex:(NSInteger)index withString:(NSString *)string
{
    NSArray *needDeleteStringList = [self getMatchedStringsWithPattern:pattern groupIndex:index];
    
    NSString *newString = [self copy];
    for (NSString *needDeleteString in needDeleteStringList)
    {
        newString = [newString stringByReplacingOccurrencesOfString:needDeleteString withString:string];
    }
    
    return newString;
}

-(NSString *)stringByDeletingPathExtension
{
    return [self stringByReplacingOccurrencesOfString:[@"." stringByAppendingString:[self pathExtension]] withString:@""];
}

@end
