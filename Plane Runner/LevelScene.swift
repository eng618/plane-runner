//
//  LevelScene.swift
//  Plane Runner
//
//  Created by Eric Garcia on 4/29/15.
//  Copyright (c) 2015 Garcia Enterprise. All rights reserved.
//

import SpriteKit
import AVFoundation

class LevelScene: SKScene {
    
    // World Node
    let worldNode = SKNode()
    // Moving Node
    let movingNodes = SKNode()
    // Tutorial Node
    let tutorialNode = SKNode()
    
    // Level Dictionary
    var levelPlistString: String!
    var levelPlist: String!
    var levelData: NSDictionary!
    
    // Win distance
    var endLevelX = 0
    var sceneLength: CGFloat!
    
    // Audio Player
    private var audioPlayer = AVAudioPlayer()
    
    // Level Textures
    private let backgroundTexture = SKTexture(imageNamed: BackgroundImage)
    private let groundTexture = SKTexture(imageNamed: GroundGrassImage)
    private let rockTexture = SKTexture(imageNamed: RockGrassImage)
    private let rockDownTexture = SKTexture(imageNamed: RockGrassDownImage)
    private let planeTexture = SKTexture(imageNamed: PlaneOneImage)
    private let planeTexture1 = SKTexture(imageNamed: PlaneTwoImage)
    private let planeTexture2 = SKTexture(imageNamed: PlaneThreeImage)
    private let gameOverTexture = SKTexture(imageNamed: TextGameOver)
    private let pauseTexture = SKTexture(imageNamed: ButtonSmallImage)
    private let pauseIconTexture = SKTexture(imageNamed: PauseIconImage)
    private let tapTexture = SKTexture(imageNamed: TapTick)
    private let starTexture = SKTexture(imageNamed: StarGold)
    
    // Level Image Nodes
    private var backgroundLevelNode: SKSpriteNode!
    private var foregroundLevelNode: SKSpriteNode!
    private var plane: SKSpriteNode!
    private var gameOverText: SKSpriteNode!
    
    // HUD
    private var hud = SKNode()
    private var hudDistanceLabel = SKLabelNode(fontNamed: GameFont)
    private var distanceFlown = 0
    private var hudPauseButn = SKNode()
    private var hudStarNode = SKNode()
    private var hudStarLabel = SKLabelNode(fontNamed: GameFont)
    private var starsCollected = 0
    
    // Sound Actions
    var planeCrashFX: SKAction!
    var distanceIncreasFX: SKAction!
    var planeFlyingFX: SKAction!
    var starFX: SKAction!
    var clickFX: SKAction!
    
    // Labels
    private var labelHolderGameOver = SKSpriteNode()
    private var labelHolderGetReady = SKSpriteNode()
    
    // Booleans
    private var gameStarted = false
    private var gamePaused = false
    private var gameOver = false
    private var isTouching = false
    private var levelWon = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    required init(size: CGSize, level: String) {
        super.init(size: size)
        levelPlistString =  level
        levelPlist = NSBundle.mainBundle().pathForResource(level, ofType: "plist")!
        levelData = NSDictionary(contentsOfFile: levelPlist)
    }
}

// MARK: Lifecycle methods
extension LevelScene {
    
    override func didMoveToView(view: SKView) {
        // Add world node to main scene
        addChild(worldNode)
        // Add moving nodes to world
        worldNode.addChild(movingNodes)
        // Add gameover node
        worldNode.addChild(labelHolderGameOver)
        // Add tutorial node
        worldNode.addChild(tutorialNode)
        
        // Assign contact delegate to current class
        self.physicsWorld.contactDelegate = self
        
        // Change gravity
        self.physicsWorld.gravity = CGVectorMake(0, -2.0)
        self.physicsBody?.restitution = 0.0
        
        // Obtaine prepared audio player from helper class
        audioPlayer = LevelHelper.prepareAudioPlayer(view)
        // Insure its prepared and start playing background audio.
        if audioPlayer.prepareToPlay() {
            audioPlayer.play()
        }
        
        loadResouces()
        createHUD(view)
        createBoundry(view)
        createBackground(view)
        createGround(view)
        createObsticles(view)
        createClouds(view)
        createDistanceMarkers(view)
        createPlane(view)
        createTutorial(view)
        createStars(view)
    }
}

// MARK: Level setup
extension LevelScene {
    
    func loadResouces(){
        // Get total length of level from dictionary
        endLevelX = levelData["EndX"]!.integerValue!
        sceneLength = CGFloat(endLevelX)
        
        // Create scene background
        backgroundLevelNode = SKSpriteNode()
        backgroundLevelNode.zPosition = ZLevel.Background
        // Create scene foreground
        foregroundLevelNode = SKSpriteNode()
        foregroundLevelNode.zPosition = ZLevel.Foreground
        
        // Plane crash sound effect
        planeCrashFX = SKAction.repeatAction(SKAction.playSoundFileNamed(PlaneCrashSoundFX, waitForCompletion: true), count: 1)
        
        // Distance increase sound effect
        distanceIncreasFX = SKAction.repeatAction(SKAction.playSoundFileNamed(DistanceIncreaseSoundFX, waitForCompletion: true), count: 1)
        
        // Plane flying sound effect
        planeFlyingFX = SKAction.repeatAction(SKAction.playSoundFileNamed(PlaneFlyingSoundFX, waitForCompletion: true), count: 1)
        
        // Star sound effect
        starFX = SKAction.repeatAction(SKAction.playSoundFileNamed(StarFX, waitForCompletion: true), count: 1)
        
        // Click sound effect
        clickFX = SKAction.repeatAction(SKAction.playSoundFileNamed(ClickFX, waitForCompletion: true), count: 1)
        
        // Game Over
        gameOverText = SKSpriteNode(texture: gameOverTexture)
    }
    
    func createHUD(view: SKView) {
        // Create pause button
        let pauseButton = SKSpriteNode(texture: pauseTexture)
        pauseButton.setScale(1.4)
        pauseButton.position = CGPoint(x: view.frame.width - pauseButton.size.width / 2 - 10, y: view.frame.height - pauseButton.size.height / 2 - 10)
        
        // Create pause icon
        let pauseIcon = SKSpriteNode(texture: pauseIconTexture)
        pauseIcon.position = CGPoint(x: view.frame.width - pauseButton.size.width / 2 - 10, y: view.frame.height - pauseButton.size.height / 2 - 10)
        
        hudPauseButn.addChild(pauseButton)
        hudPauseButn.addChild(pauseIcon)
        
        // Add to hud
        hud.addChild(hudPauseButn)
        
        // Create distance label
        hudDistanceLabel.text = "Distance: \(distanceFlown) meters"
        hudDistanceLabel.fontColor = SKColor.blackColor()
        hudDistanceLabel.fontSize = 14
        hudDistanceLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        hudDistanceLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Top
        hudDistanceLabel.position = CGPoint(x: 10, y: CGRectGetMaxY(self.frame) - 10)
        
        // Add to hud
        hud.addChild(hudDistanceLabel)
        
        // Create star lable
        let star = SKSpriteNode(texture: starTexture)
        star.position = CGPoint(x: 10 + star.size.width / 2, y: view.frame.height - hudDistanceLabel.frame.height - 20)
        
        hudStarLabel.text = "= \(starsCollected)"
        hudStarLabel.fontColor = SKColor.blackColor()
        hudStarLabel.fontSize = 14
        hudStarLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        hudStarLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        hudStarLabel.position = CGPoint(x: 10 + star.size.width, y: view.frame.height - hudDistanceLabel.frame.height - 20)
        
        hudStarNode.addChild(star)
        hudStarNode.addChild(hudStarLabel)
        
        // Add to hud
        hud.addChild(hudStarNode)
        
        hud.zPosition = ZLevel.HUD
        worldNode.addChild(hud)
    }
    
    func createBoundry(view: SKView) {
        let boundry = SKNode()
        boundry.physicsBody = SKPhysicsBody(edgeLoopFromRect: view.frame)
        boundry.physicsBody?.dynamic = false
        boundry.physicsBody?.restitution = 0.0
        boundry.physicsBody?.categoryBitMask = PhysicsCategory.Boundary
        
        worldNode.addChild(boundry)
    }
    
    func createBackground(view: SKView) {
        
        // Set up variables for while loop
        var i: CGFloat = 0
        
        // Number of backgrounds created
        var numBgCreated = 0
        
        while i < sceneLength + view.frame.width {
            numBgCreated++
            
            let bg = SKSpriteNode(texture: backgroundTexture)
            bg.size = view.frame.size
            bg.position = CGPoint(x: i, y: view.frame.height/2)
            bg.zPosition = ZLevel.Background
            
            backgroundLevelNode.addChild(bg)
            
            i = i + bg.size.width
        }
        
        println("Number of backgrounds created \(numBgCreated)")
        movingNodes.addChild(backgroundLevelNode)
    }
    
    func createGround(view: SKView) {
        var i: CGFloat = 0
        
        var numGroundCreated = 0
        
        while i < sceneLength + view.frame.width {
            numGroundCreated++
            
            let ground = SKSpriteNode(texture: groundTexture)
            ground.position = CGPoint(x: i, y: ground.frame.height/2)
            ground.zPosition = ZLevel.Ground
            
            // Set physics
            ground.physicsBody = SKPhysicsBody(rectangleOfSize: ground.size)
            ground.physicsBody?.dynamic = false
            ground.physicsBody?.restitution = 0.0
            ground.physicsBody?.categoryBitMask = PhysicsCategory.Ground
            
            foregroundLevelNode.addChild(ground)
            
            i = i + ground.size.width
        }
        println("Number of grounds created \(numGroundCreated)")
    }
    
    func createObsticles(view: SKView) {
        
        // Create lower rocks
        let rocksDictionary = levelData["Rocks"] as! NSDictionary
        let rocksArray = rocksDictionary["Positions"] as! [NSDictionary]
        
        for rock in rocksArray {
            
            
            let rockNode = SKSpriteNode(texture: rockTexture)
            rockNode.setScale(2.0)
            
            let x = rock["x"]?.floatValue
            let y = rock["y"]?.floatValue
            let xPosition = CGFloat(x!) - rockNode.size.width/2
            let yPosition = CGFloat(y!) + rockNode.size.height/2
            
            rockNode.position = CGPoint(x: xPosition, y: yPosition)
            rockNode.zPosition = ZLevel.Rocks
            
            println("Rock postion x:\(xPosition) y:\(yPosition)")
            
            // Set physics
            rockNode.physicsBody = SKPhysicsBody(rectangleOfSize: rockNode.size)
            rockNode.physicsBody?.dynamic = false
            rockNode.physicsBody?.restitution = 0.0
            rockNode.physicsBody?.categoryBitMask = PhysicsCategory.Collidable
            
            foregroundLevelNode.addChild(rockNode)
        }
        
        // Create upper rocks
        let rocksDownDictionary = levelData["RocksDown"] as! NSDictionary
        let rocksDownArray = rocksDownDictionary["Positions"] as! [NSDictionary]
        
        for rockDown in rocksDownArray {
            
            let rockDownNode = SKSpriteNode(texture: rockDownTexture)
            rockDownNode.setScale(2.0)
            
            let x = rockDown["x"]?.floatValue
            let xPosition = CGFloat(x!) - rockDownNode.size.width/2
            let yPosition = view.frame.height - rockDownNode.size.height/2
            
            rockDownNode.position = CGPoint(x: xPosition, y: yPosition)
            rockDownNode.zPosition = ZLevel.Rocks
            
            println("RockDown postion x:\(xPosition) y:\(yPosition)")
            
            // Set physics
            rockDownNode.physicsBody = SKPhysicsBody(rectangleOfSize: rockDownNode.size)
            rockDownNode.physicsBody?.dynamic = false
            rockDownNode.physicsBody?.restitution = 0.0
            rockDownNode.physicsBody?.categoryBitMask = PhysicsCategory.Collidable
            
            foregroundLevelNode.addChild(rockDownNode)
        }
        movingNodes.addChild(foregroundLevelNode)
    }
    
    func createStars(view: SKView) {
        let starDictionary = levelData["Stars"] as! NSDictionary
        let positionsArray = starDictionary["Positions"] as! [NSDictionary]
        
        for star in positionsArray {
            let starNode = SKSpriteNode(texture: starTexture)
            starNode.setScale(2.0)
            
            let x = star["x"]?.floatValue
            let y = star["y"]?.floatValue
            let xPositoin = CGFloat(x!)
            let yPosition = CGFloat(y!)
            
            println("Star postioion x:\(xPositoin) y:\(yPosition)")
            starNode.position = CGPoint(x: xPositoin, y: yPosition)
            
            // Set physics
            starNode.physicsBody = SKPhysicsBody(rectangleOfSize: starNode.size)
            starNode.physicsBody?.dynamic = false
            starNode.physicsBody?.categoryBitMask = PhysicsCategory.Stars
            starNode.physicsBody?.contactTestBitMask = PhysicsCategory.Plane
            
            foregroundLevelNode.addChild(starNode)
        }
    }
    
    func createClouds(view: SKView) {
        // TODO: Create clouds
    }
    
    func createDistanceMarkers(view: SKView) {
        var i: CGFloat = view.frame.width / 4 + planeTexture.size().width/2 + 10
        
        while i < sceneLength + view.frame.width {
            let distanceMarkerNode = SKNode()
            distanceMarkerNode.physicsBody = SKPhysicsBody(edgeFromPoint: CGPoint(x: i, y: 0), toPoint: CGPoint(x: i, y: view.frame.height))
            distanceMarkerNode.physicsBody?.dynamic = false
            distanceMarkerNode.physicsBody?.categoryBitMask = PhysicsCategory.Distance
            distanceMarkerNode.physicsBody?.contactTestBitMask = PhysicsCategory.Plane
            
            foregroundLevelNode.addChild(distanceMarkerNode)
            
            i = i + 10
        }
    }
    
    func createPlane(view: SKView) {
        plane = SKSpriteNode(texture: planeTexture)
        plane.position = CGPoint(x: view.frame.width/4, y: view.frame.height/2)
        plane.zPosition = ZLevel.Plane
        
        // Set physics
        plane.physicsBody = SKPhysicsBody(rectangleOfSize: plane.size)
        plane.physicsBody?.dynamic = true
        plane.physicsBody?.allowsRotation = false
        plane.physicsBody?.restitution = 0.0
        plane.physicsBody?.categoryBitMask = PhysicsCategory.Plane
        plane.physicsBody?.collisionBitMask = PhysicsCategory.Collidable | PhysicsCategory.Boundary | PhysicsCategory.Ground
        plane.physicsBody?.contactTestBitMask = PhysicsCategory.Collidable | PhysicsCategory.Boundary | PhysicsCategory.Ground | PhysicsCategory.Distance | PhysicsCategory.Stars
        
        plane.physicsBody?.pinned = true
        
        worldNode.addChild(plane)
    }
    
    func createTutorial(view: SKView) {
        let scaleUp = SKAction.resizeByWidth(50, height: 50, duration: 0.5)
        let scaleDown = SKAction.resizeByWidth(-50, height: -50, duration: 0.5)
        let repeatScaling = SKAction.repeatActionForever(SKAction.sequence([scaleUp, scaleDown]))
        
        
        let tapTick = SKSpriteNode(texture: tapTexture)
        tapTick.position = CGPoint(x: view.frame.width / 2, y: view.frame.height / 2)
        tapTick.zPosition = ZLevel.Tutorial
        
        tapTick.runAction(repeatScaling)
        
        tutorialNode.addChild(tapTick)
    }
}

// MARK: Game Events
extension LevelScene {
    
    func play(){
        // Action to move background
        let moveBg = SKAction.moveByX(-sceneLength, y: 0, duration: NSTimeInterval(sceneLength/50))
        backgroundLevelNode.runAction(moveBg)
        
        // Action to move foreground
        let moveFg = SKAction.moveByX(-sceneLength, y: 0, duration: NSTimeInterval(sceneLength/150))
        foregroundLevelNode.runAction(moveFg)
        
        // Animate plans propeller
        let animation = SKAction.animateWithTextures([planeTexture, planeTexture1, planeTexture2], timePerFrame: 0.05)
        let makePropellerSpin = SKAction.repeatActionForever(animation)
        plane.runAction(makePropellerSpin)
        
        plane.physicsBody?.pinned = false
        
        tutorialNode.removeFromParent()
    }
    
    func pause() {
        gamePaused = true
        // pause physics
        self.paused = true
        if audioPlayer.playing{
            audioPlayer.pause()
        }
    }
    
    func resume() {
        gamePaused = false
        // Unpause physics
        self.paused = false
        if !audioPlayer.playing {
            audioPlayer.play()
        }
    }
    
    func updateDistance() {
        //        runAction(distanceIncreasFX)
        distanceFlown++
        hudDistanceLabel.text = "Distance: \(distanceFlown) meters"
    }
    
    func collectStar(star: SKNode) {
        star.removeFromParent()
        hudStarNode.addChild(star)
        star.physicsBody = nil
        
        star.position = CGPoint(x: self.frame.size.width / 3, y: 100)
        
        
        self.runAction(starFX)
        
        let moveStar = SKAction.moveTo(CGPoint(x: 10, y: view!.frame.height - 20), duration: 1.5)
//        let shrinkStar = SKAction.scaleXTo(0.5, duration: 1.5)
        let shrinkStar = SKAction.resizeToWidth(star.frame.width / 2, height: star.frame.height / 2, duration: 1.5)
        let moveAndShring = SKAction.group([moveStar, shrinkStar])
        let removeStar = SKAction.removeFromParent()
        let moveAndRemoveStar = SKAction.sequence([moveAndShring, removeStar])
        
        star.runAction(moveAndRemoveStar)
        
        starsCollected++
        hudStarLabel.text = "= \(starsCollected)"
    }
    
    func won() {
        // TODO: Setup won conditions
        println("WON!!")
        levelWon = true
        movingNodes.speed = 0
        isTouching = false
        plane.physicsBody?.pinned = true
        plane.removeAllActions()
        
        // TODO: Create Win animation
        let wonText = SKLabelNode(fontNamed: GameFont)
        wonText.fontColor = SKColor.blackColor()
        wonText.fontSize = 60
        wonText.text = "YOU WON!!"
        wonText.position = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)
        self.addChild(wonText)
    }
    
    func lost() {
        // TODO: Setup lost condition
    }
}

// MARK: Input methods
extension LevelScene {
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        // TODO: Setup touches
        if !gameStarted {
            gameStarted = true
            play()
        }
        
        for touch: AnyObject in touches {
            let location = touch.locationInNode(self)
            if hudPauseButn.containsPoint(location) {
                self.runAction(clickFX)
                println("Pause/Play")
                if self.paused {
                    resume()
                } else {
                    pause()
                }
            } else {
                if gameOver {
                    // Reset scene
                    let scene = LevelScene(size: size, level: levelPlistString)
                    self.view?.presentScene(scene)
                } else if !self.paused {
                    // Used for contiuous flying while touching screen.
                    isTouching = true
                    runAction(planeFlyingFX)
                    
                    // Uncomment for single tap mode.
                    // plane.physicsBody?.velocity = CGVectorMake(0, 0)
                    // plane.physicsBody?.applyImpulse(CGVectorMake(0, 10))
                }
            }
        }
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        isTouching = false
    }
    
    override func update(currentTime: NSTimeInterval) {
        if isTouching {
            plane.physicsBody?.applyForce(CGVectorMake(0, 50))
        }
        
        if distanceFlown >= Int(sceneLength) / 10 {
            if !levelWon {
                won()
            }
        }
    }
}

// MARK: SKPhysicsContactDelegate
extension LevelScene: SKPhysicsContactDelegate {
    func didBeginContact(contact: SKPhysicsContact) {
        var notPlane = SKPhysicsBody()
        var notPlaneNode = SKNode()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            notPlane = contact.bodyB
            notPlaneNode = contact.bodyB.node!
        } else {
            notPlane = contact.bodyA
            notPlaneNode = contact.bodyA.node!
        }
        
        switch notPlane.categoryBitMask {
        case PhysicsCategory.Distance:
            println("distance increased")
            updateDistance()
        case PhysicsCategory.Stars:
            println("Touched a star")
            collectStar(notPlaneNode)
        default:
            println("Plane crashed")
            
            runAction(planeCrashFX)
            plane.physicsBody?.velocity = CGVectorMake(0, 0)
            plane.physicsBody?.applyImpulse(CGVectorMake(0, -50))
            
            
            if gameOver == false {
                gameOver = true
                movingNodes.speed = 0
                
                isTouching = false
                
                // Stop propeller spinning
                plane.removeAllActions()
                
                gameOverText.setScale(2.0)
                gameOverText.zPosition = ZLevel.Label
                gameOverText.position = CGPoint(x: view!.frame.width / 2, y: view!.frame.height / 2)
                
                labelHolderGameOver.addChild(gameOverText)
            }
        }
    }
}









