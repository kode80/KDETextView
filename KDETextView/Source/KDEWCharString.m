//
//  KDEWCharString.m
//  KDETextView
//
//  Created by Benjamin S Hopkins on 5/24/15.
//  Copyright (c) 2015 kode80. All rights reserved.
//

#import "KDEWCharString.h"


@interface KDEWCharString ()

@property (nonatomic, readwrite, assign) wchar_t *wcharString;
@property (nonatomic, readwrite, strong) NSString *string;

@end


@implementation KDEWCharString

- (void) dealloc
{
    if( _wcharString)
    {
        free( _wcharString);
        _wcharString = NULL;
    }
}

+ (instancetype) wcharString:(NSString *)string
{
    KDEWCharString *wcharString = [self new];
    wcharString.wcharString = [string createWCharString];
    wcharString.string = [string copy];
    return wcharString;
}

@end
