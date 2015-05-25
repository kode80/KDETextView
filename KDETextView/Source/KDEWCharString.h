//
//  KDEWCharString.h
//  KDETextView
//
//  Created by Benjamin S Hopkins on 5/24/15.
//  Copyright (c) 2015 kode80. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NSString+wchar.h"


@interface KDEWCharString : NSObject

@property (nonatomic, readonly, assign) wchar_t *wcharString;
@property (nonatomic, readonly, strong) NSString *string;

+ (instancetype) wcharString:(NSString *)string;

@end
