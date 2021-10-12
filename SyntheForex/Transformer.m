//
//  Transformer.m
//  SyntheForex
//
//  Created by 佐山 隆裕 on 12/01/01.
//  Copyright (c) 2012年 tanuki-project. All rights reserved.
//

#import     "Transformer.h"
#include    "build.h"

@implementation Transformer

+ (Class)transformedValueClass
{
    return [NSString self];
}

+ (BOOL)allowsReverseTransformation
{
    return NO;
}

- (id)transformedValue:(id)beforeObject
{
    if (beforeObject == nil) {
        return nil;   
    }
    //NSLog(@"transformedValue: %@", beforeObject);
    NSString *path = [[[NSString alloc] initWithFormat:@"flag%@.png", beforeObject] autorelease];
    id resourcePath = [[NSBundle mainBundle] resourcePath];
    NSLog(@"resourcePath: %@", [resourcePath stringByAppendingPathComponent:path]);
    return [resourcePath stringByAppendingPathComponent:path];
}

@end
