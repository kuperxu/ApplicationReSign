//
//  main.m
//  AplicationReSign
//
//  Created by 徐纪光 on 2020/3/16.
//  Copyright © 2020 kuperxu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FakeAppDelegate.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([FakeAppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
