//
//  FastPdfKitLibraryAppDelegate.h
//  FastPdfKitLibrary
//
//  Created by Nicolò Tosi on 7/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MenuViewController;

@interface FastPdfKitLibraryAppDelegate : NSObject <UIApplicationDelegate> {

    MenuViewController * menuViewController;
    UINavigationController * navigationController;
}
@property (nonatomic, strong) UINavigationController * navigationController;
@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) MenuViewController * menuViewController;

@end
