//
//  MainMenuScene.m
//  PetShop
//
//  Created by M Dobbins on 5/21/14.
//  Copyright (c) 2014 MDobbins. All rights reserved.
//

#import "MainMenuScene.h"
#import "PlayScene.h"

@interface MainMenuScene()
@property BOOL sceneCreated;
@end
@implementation MainMenuScene

- (void) didMoveToView:(SKView *)view
{
    if (!self.sceneCreated)
    {
        self.backgroundColor = [SKColor blackColor];
        self.scaleMode = SKSceneScaleModeAspectFill;
        [self addChild: [self createMenuNode]];
        self.sceneCreated = YES;
    }
}


- (SKLabelNode *) createMenuNode
{
    SKLabelNode *menuNode =
    [SKLabelNode labelNodeWithFontNamed:@"Comic Sans"];
    
    menuNode.name = @"menuNode";
    menuNode.text = @"Animal Shelter Rescue - Tap Screen to Play";
    menuNode.fontSize = 14;
    menuNode.fontColor = [SKColor yellowColor];
    
    menuNode.position =
    CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    
    return menuNode;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    SKNode *menuNode = [self childNodeWithName:@"menuNode"];
    
    if (menuNode != nil)
    {
        SKAction *fadeAway = [SKAction fadeOutWithDuration:1.0];
        
        [menuNode runAction:fadeAway completion:^{
            SKScene *playScene =
            [[PlayScene alloc]initWithSize:self.size];
            
            SKTransition *doors =
            [SKTransition doorwayWithDuration:1.0];
            
            [self.view presentScene:playScene transition:doors];
        }
         ];
    }
}



@end
