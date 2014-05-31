//
//  ViewController.m
//  PetShop
//
//  Created by M Dobbins on 5/21/14.
//  Copyright (c) 2014 MDobbins. All rights reserved.
//

#import "ViewController.h"
#import "MainMenuScene.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    
    
    MainMenuScene *mainMenu = [[MainMenuScene alloc]
                             initWithSize:CGSizeMake(skView.bounds.size.width,
                                                     skView.bounds.size.height)];
    
    [skView presentScene:mainMenu];
    

}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
