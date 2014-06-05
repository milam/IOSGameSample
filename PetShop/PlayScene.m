//
//  PlayScene.m
//  PetShop
//
//  Created by M Dobbins on 5/21/14.
//  Copyright (c) 2014 MDobbins. All rights reserved.
//

#import "PlayScene.h"
#import "MainMenuScene.h"



#define TIME 1.5

static const uint32_t basketCategory            =  0x1 << 0;
static const uint32_t petCategory               =  0x1 << 1;
static const uint32_t conveyorCategory          =  0x1 << 2;
static const uint32_t nullColliderCategory1     =  0x1 << 3;


@interface PlayScene()
{
    NSTimeInterval _dt;
    float bottomScrollerHeight;
}
@property BOOL sceneCreated;
@property int score;
@property int topScore;
@property int petCount;
@property int petsCaught;
@property SKSpriteNode *selectedNode;
@property (nonatomic) NSTimeInterval lastSpawnTimeInterval;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;

@end

@implementation PlayScene
int convPosition = 0;
float BG_VELOCITY                  = (TIME * 60);


#pragma mark score methods

-(void) saveScore:(NSNumber*)score currentTopScore:(NSNumber*)topScore
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([score intValue]>=[topScore intValue])
    {
    [defaults setValue:score forKey:@"Top_Score"];
    }
    [defaults setValue:topScore forKey:@"Last_Score"];

    //Save changes
    [defaults synchronize];
}

-(int)loadScore
{   int score;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    score = [[defaults objectForKey:@"Last_Score"] intValue];
    self.topScore = [[defaults objectForKey:@"Top_Score"] intValue];
    
    return score;
}




#pragma mark Methods for moving sprites

static inline CGPoint CGPointAdd(const CGPoint a, const CGPoint b)
{
    return CGPointMake(a.x + b.x, a.y + b.y);
}

static inline CGPoint CGPointMultiplyScalar(const CGPoint a, const CGFloat b)
{
    return CGPointMake(a.x * b, a.y * b);
}

- (void)didMoveToView:(SKView *)view
{
    if (!self.sceneCreated)
    {
        self.score = 0;
        self.petCount = 100;
        BG_VELOCITY*=1.05;  //increases speed by 5% every level
    
        UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
        [[self view] addGestureRecognizer:gestureRecognizer];
        [self initPlayScene];
        self.sceneCreated = YES;
        SKNode *scoreNode = [self createScoreNode];
        
        [self addChild:scoreNode];
        
    }
}



- (void)selectNodeForTouch:(CGPoint)touchLocation {
    
    
   
    SKSpriteNode *touchedNode = (SKSpriteNode *)[self nodeAtPoint:touchLocation];
    
    
    if(([[touchedNode name] isEqualToString:@"petNode"])||([[touchedNode name] isEqualToString:@"petNodeGrabbed"])){
    
  
	if(![self.selectedNode isEqual:touchedNode]) {
		[self.selectedNode removeAllActions];
		[self.selectedNode runAction:[SKAction rotateToAngle:0.0f duration:0.1]];
        
		self.selectedNode = touchedNode;

			SKAction *sequence = [SKAction sequence:@[[SKAction rotateByAngle:degToRad(-4.0f) duration:0.1],
													  [SKAction rotateByAngle:0.0 duration:0.1],
													  [SKAction rotateByAngle:degToRad(4.0f) duration:0.1]]];
			[self.selectedNode runAction:[SKAction repeatActionForever:sequence]];
    }
    }

}

float degToRad(float degree) {
	return degree / 180.0f * M_PI;
}

- (CGPoint)boundLayerPos:(CGPoint)newPos {
    CGSize winSize = self.size;
    CGPoint retval = newPos;
    retval.x = MIN(retval.x, 0);
    retval.x = MAX(retval.x, -self.frame.size.width+ winSize.width);
    retval.y = [self position].y;
    return retval;
}

- (void)panForTranslation:(CGPoint)translation {
    CGPoint position = [self.selectedNode position];
    if([[self.selectedNode name] isEqualToString:@"petNode"]) {
        [self.selectedNode setPosition:CGPointMake(position.x + translation.x, position.y + translation.y)];
    }
}

#pragma mark init methods
- (void) initPlayScene
{
    self.backgroundColor = [SKColor grayColor];
    self.scaleMode = SKSceneScaleModeAspectFill;
    self.physicsWorld.contactDelegate = self;
    
    self.physicsWorld.gravity = CGVectorMake(0, 0);
    
    
    SKAction *releasePets = [SKAction sequence:@[
                                                  [SKAction performSelector:@selector(createConveyorNode)
                                                                   onTarget:self],
                                                  [SKAction waitForDuration:.7]
                                                  ]];
    
    SKAction *releaseBaskets = [SKAction sequence:@[
                                                 [SKAction performSelector:@selector(createBasketNode)
                                                                  onTarget:self],
                                                 [SKAction waitForDuration:1]
                                                 ]];
    
    [self runAction: [SKAction repeatAction:releasePets
                                      count:self.petCount/2]completion:^{
        [self gameOver];}];
    [self runAction: [SKAction repeatAction:releaseBaskets
                                      count:self.petCount/3]];

    
}

- (void)update:(NSTimeInterval)currentTime
{
    if (self.lastUpdateTimeInterval)
    {
        _dt = currentTime - _lastUpdateTimeInterval;
    }
    else
    {
        _dt = 0;
    }
    
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    self.lastUpdateTimeInterval = currentTime;
    if (timeSinceLast > TIME)
    {
        timeSinceLast = 1.0 / (TIME * 60.0);
        self.lastUpdateTimeInterval = currentTime;
    }
    
    
    [self updateWithTimeSinceLastUpdate:timeSinceLast];
    
    [self moveBottomScroller];
    
    if (self.score > 0) {
        [[self childNodeWithName:@"scoreNode"] removeFromParent];
        SKNode *scoreNode = [self createScoreNode];
        
        [self addChild:scoreNode];
    }

}

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast
{
    self.lastSpawnTimeInterval += timeSinceLast;
    if (self.lastSpawnTimeInterval > TIME)
    {
        self.lastSpawnTimeInterval = 0;
        //[self createBasket]; //was used for infinite baskets
    }
}



- (void)moveBottomScroller
{
    [self enumerateChildNodesWithName:@"conveyorNode" usingBlock: ^(SKNode *node, BOOL *stop)
     {
         SKSpriteNode *conveyorBelt = (SKSpriteNode *) node;
         CGPoint bgVelocity = CGPointMake(BG_VELOCITY, 0);
         CGPoint amtToMove = CGPointMultiplyScalar(bgVelocity,_dt);
         conveyorBelt.position = CGPointAdd(conveyorBelt.position, amtToMove);

     }];
    
    [self enumerateChildNodesWithName:@"petNode" usingBlock: ^(SKNode *node, BOOL *stop)
     {
         SKSpriteNode *conveyorBelt = (SKSpriteNode *) node;
         if (conveyorBelt != self.selectedNode) {
         CGPoint bgVelocity = CGPointMake(BG_VELOCITY, 0);
         CGPoint amtToMove = CGPointMultiplyScalar(bgVelocity,_dt);
         conveyorBelt.position = CGPointAdd(conveyorBelt.position, amtToMove);
         }

     }];
    
    [self enumerateChildNodesWithName:@"basketNode" usingBlock: ^(SKNode *node, BOOL *stop)
     {
         SKSpriteNode *conveyorBelt = (SKSpriteNode *) node;
         CGPoint bgVelocity = CGPointMake(-BG_VELOCITY, 0);
         CGPoint amtToMove = CGPointMultiplyScalar(bgVelocity,_dt);
         conveyorBelt.position = CGPointAdd(conveyorBelt.position, amtToMove);
         

     }];
}

#pragma mark Collision
////////collision
- (void)pet:(SKSpriteNode *)pet didCollideWithBasket:(SKSpriteNode *)basket
{
    SKNode *labelBasket = [basket childNodeWithName:@"labelNode"];
    SKNode *labelPet = [pet childNodeWithName:@"labelNode"];
    pet.name = ((SKLabelNode*)labelPet).text;
    NSString *basketLabel = ((SKLabelNode*)labelBasket).text;
    
    
    NSLog(@"%@ and %@", pet.name, basketLabel);
    
    if([pet.name isEqualToString:basketLabel])
    {
    self.score++;
        [pet removeFromParent];
        [basket removeFromParent];
    }
    
//    [pet removeFromParent];
//    [basket removeFromParent];
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody, *secondBody;
    
    if ((contact.bodyA ==self.selectedNode.physicsBody)) {
        firstBody = self.selectedNode.physicsBody;
        secondBody = contact.bodyB;
    }else{
        firstBody = self.selectedNode.physicsBody;
        secondBody = contact.bodyA;}
    
    
    
    [self pet:(SKSpriteNode *) firstBody.node didCollideWithBasket:(SKSpriteNode *) secondBody.node];
}





#pragma mark Create Sprites
- (void)createBasketNode
{
    SKSpriteNode *basketNode =
    [[SKSpriteNode alloc] initWithImageNamed:@"Basket50.png"];
    
    basketNode.name = @"basketNode";
    basketNode.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:basketNode.frame.size.height/3];
    basketNode.physicsBody.categoryBitMask = basketCategory;
    basketNode.physicsBody.collisionBitMask = nullColliderCategory1;
    basketNode.physicsBody.contactTestBitMask = petCategory;
    
    basketNode.position =
    CGPointMake(CGRectGetMaxX(self.frame) + 15,
                CGRectGetMidY(self.frame)/4);

    
    SKLabelNode *labelNode = [[SKLabelNode alloc] initWithFontNamed:@"Times New Roman"];
    
    

    
    int typeOfPet = randomBetween(0, 5.0);
    
    switch ((int)typeOfPet) {
        case 0:
            labelNode.text = @"Bird";
            
            break;
        case 1:
            labelNode.text = @"Cat";
            
            
            break;
        case 2:
            labelNode.text = @"Dog";
            
            break;
        case 3:
            labelNode.text = @"Fish";
            
            break;
        case 4:
            labelNode.text = @"Turtle";
            
            break;
        default:
            break;
    }
    labelNode.name = @"labelNode";
    //NSLog(@"%@", labelNode.name);//debug
    
    
    labelNode.fontSize = 14;
    labelNode.fontColor = [SKColor blueColor];
    
    
    [basketNode addChild:labelNode];
    labelNode.position = CGPointMake(0, 3);

    
    [self addChild:basketNode];
    
}

- (void)createConveyorNode
{
    

    
    SKSpriteNode *conveyorNode =
    [[SKSpriteNode alloc] initWithImageNamed:@"Wagon.png"];
    
    int adjYPos = 20;
    int adjXPos = -60;
    switch ((convPosition)%3) {
        case 0:
        conveyorNode.position = CGPointMake(adjXPos, CGRectGetMidY(self.frame)*1.5);
            break;
        case 1:
        conveyorNode.position = CGPointMake(adjXPos, CGRectGetMidY(self.frame) + adjYPos);
        break;
        case 2:
        conveyorNode.position = CGPointMake(adjXPos, CGRectGetMidY(self.frame)*.5 + adjYPos+15);
            
        break;
        
        default:
            break;
    }
    convPosition++;
    
    conveyorNode.name = @"conveyorNode";
    
    SKSpriteNode *petNode = [self createPetNode:CGPointMake(conveyorNode.position.x-22.0, conveyorNode.position.y+25.0)];
    

    conveyorNode.physicsBody =
    [SKPhysicsBody bodyWithCircleOfRadius:conveyorNode.frame.size.height/3];
    
    conveyorNode.physicsBody.usesPreciseCollisionDetection = NO;
    conveyorNode.physicsBody.categoryBitMask = conveyorCategory;
    conveyorNode.physicsBody.collisionBitMask = nullColliderCategory1;
    conveyorNode.physicsBody.affectedByGravity = NO;
    petNode.physicsBody.usesPreciseCollisionDetection = YES;
    petNode.physicsBody.affectedByGravity = NO;
    
    
    [self addChild: conveyorNode];
    [self addChild: petNode];
    
}



- (SKSpriteNode *)createPetNode:(CGPoint)Position
{
    CGFloat typeOfPet = randomBetween(0, 5.0);
    NSString *petType;
    NSString *petName;
    
    /////
    
    SKLabelNode *labelNode = [[SKLabelNode alloc] initWithFontNamed:@"Times New Roman"];

    
    
    ////
    switch ((int)typeOfPet) {
        case 0:
            petType = @"pet_bird";
            petName = @"Bird";
            break;
        case 1:
            petType = @"pet_cat";
            petName = @"Cat";
            break;
        case 2:
            petType = @"pet_dog";
            petName = @"Dog";
            break;
        case 3:
            petType = @"pet_fish";
            petName = @"Fish";
            break;
        case 4:
            petType = @"pet_turtle";
            petName = @"Turtle";
            break;
        default:
            break;
    }
    
    labelNode.text = petName;
    labelNode.name = @"labelNode";
    
    SKSpriteNode *petNode =
    [[SKSpriteNode alloc] initWithImageNamed:petType];
    
    petNode.name = @"petNode";
    
    petNode.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:petNode.frame.size];
    
    petNode.position = Position;
    
    petNode.physicsBody.categoryBitMask = petCategory;
    
    petNode.physicsBody.collisionBitMask = nullColliderCategory1;
    
    petNode.physicsBody.contactTestBitMask = basketCategory;
    
    
    //
    labelNode.fontSize = 14;
    labelNode.fontColor = [SKColor darkGrayColor];

    
    [petNode addChild:labelNode];
    labelNode.position = CGPointMake(0, 3);
    //
    
    
    return petNode;
}




static inline CGFloat randomFloat()
{
    return rand() / (CGFloat) RAND_MAX;
}

static inline CGFloat randomBetween(CGFloat low, CGFloat high)
{
    return randomFloat() * (high - low) + low;
}


- (SKNode *) createScoreNode
{
    SKNode *scoreText = [SKNode node];
    SKLabelNode *a = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
    a.fontSize = 36;
    a.fontColor = [SKColor yellowColor];
    NSString *st1 =[NSString stringWithFormat:@"Score: %i", self.score];
    a.text = st1;
    [scoreText addChild:a];
    scoreText.name = @"scoreNode";
    scoreText.position = CGPointMake(self.frame.size.width*.6, self.frame.size.height*.9);

    

    
    return scoreText;
}


- (SKNode *) createFinalScoreNode
{
    SKNode *scoreText = [SKNode node];
    SKLabelNode *a = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
    a.fontSize = 36;
    a.fontColor = [SKColor yellowColor];
    SKLabelNode *b = [SKLabelNode labelNodeWithFontNamed:@"Arial"];
    b.fontSize = 36;
    b.fontColor = [SKColor yellowColor];
    NSString *st1 =[NSString stringWithFormat:@"Score: %i", self.score];
    NSString *st2 =[NSString stringWithFormat:@"Top Score: %i", self.topScore];
    b.position = CGPointMake(b.position.x, b.position.y - 50);
    a.text = st1;
    b.text = st2;
    [scoreText addChild:a];
    [scoreText addChild:b];
    scoreText.name = @"scoreNode";
    scoreText.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    
    
    
    
    return scoreText;
}

#pragma mark Handle interactions

- (void)handlePanFrom:(UIPanGestureRecognizer *)recognizer {
	if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        CGPoint touchLocation = [recognizer locationInView:recognizer.view];
        
        touchLocation = [self convertPointFromView:touchLocation];
        
        [self selectNodeForTouch:touchLocation];
        
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [recognizer translationInView:recognizer.view];
        translation = CGPointMake(translation.x, -translation.y);
        [self panForTranslation:translation];
        [recognizer setTranslation:CGPointZero inView:recognizer.view];
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
            [self.selectedNode removeFromParent];
    }
}

CGPoint mult(const CGPoint v, const CGFloat s) {
	return CGPointMake(v.x*s, v.y*s);
}

#pragma mark Create end game condition
- (void) gameOver
{
    [self saveScore:[NSNumber numberWithInt: self.score] currentTopScore:[NSNumber numberWithInt: self.loadScore]];
    SKNode *scoreNode = [self createFinalScoreNode];
    
    [self addChild:scoreNode];
    
    SKAction *fadeOut = [SKAction sequence:@[[SKAction
                                              waitForDuration:3.0],
                                             [SKAction fadeOutWithDuration:3.0]]];
    
    SKAction *welcomeReturn = [SKAction runBlock:^{
        
        SKTransition *transition =
        [SKTransition revealWithDirection:SKTransitionDirectionDown
                                 duration:1.0];
        
        //  WelcomeScene *welcomeScene =
        // [[WelcomeScene alloc] initWithSize:self.size];
        PlayScene *myScene = [[PlayScene alloc]initWithSize:self.size];
        
        [self.scene.view presentScene: myScene //change this to welcomeScene
                           transition:transition];
    }];
    
    SKAction *sequence = [SKAction sequence:@[fadeOut, welcomeReturn]];
    
    [self runAction:sequence];
}



@end
