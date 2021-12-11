import SpriteKit
import AppKit
import Foundation
import AVFAudio

// collision types:
enum BodyType:UInt32 {
    
    case player = 1 // player
    case platformObject = 2 // platform
    case enemyTypeR = 4 // red enemy
    case enemyTypeB = 8 // blue enemy
    case ground = 16 // floor
    case water = 32 // water
    case playerTypeR = 64 // player red shots
    case playerTypeB = 128 // player blue shots
    case rainTypeR = 256 // kunai red
    case rainTypeB = 512 // kunai blue
    case bulletTypeR = 513 // bullet red
    case bulletTypeB = 514 // bullet blue
}

// type of generated section
enum LevelType:UInt32 {
    
    case ground, water
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // audio controller
    var footstepSoundPlayer:AVAudioPlayer?
    var backgroundSoundPlayer:AVAudioPlayer?
    var soundPlayed1 = true
    var soundPlayed2 = true
    var soundPlayed3 = true
    let metalOnMetalSound = SKAction.playSoundFileNamed("metalOnMetalSound.wav", waitForCompletion: true)
    let gameOverSound = SKAction.playSoundFileNamed("gameOverSound.wav", waitForCompletion: true)
    let gettingFasterSound = SKAction.playSoundFileNamed("gettingFasterSound.wav", waitForCompletion: true)
    let jumpSound1 = SKAction.playSoundFileNamed("jumpSound1.wav", waitForCompletion: true)
    let jumpSound2 = SKAction.playSoundFileNamed("jumpSound2.wav", waitForCompletion: true)
    let jumpSound3 = SKAction.playSoundFileNamed("jumpSound3.wav", waitForCompletion: true)
    let plusThreeSound = SKAction.playSoundFileNamed("plusThreeSound.wav", waitForCompletion: true)
    let throwSound = SKAction.playSoundFileNamed("throwSound.wav", waitForCompletion: true)
    
    // level generation var's
    var levelUnitCounter:CGFloat = 0
    var levelUnitWidth:CGFloat = 0
    var levelUnitHeight:CGFloat = 0
    var initialUnits:Int = 2

    // screen dimensions
    var screenWidth:CGFloat = 0
    var screenHeight:CGFloat = 0
    
    // world node to move level towards player
    let worldNode:SKNode = SKNode()
    
    // player's character
    let thePlayer:Player = Player(imageNamed: "run1")
    
    // looping gackground images
    let loopingBG:SKSpriteNode = SKSpriteNode(imageNamed: "looping_BG1")
    let loopingBG2:SKSpriteNode = SKSpriteNode(imageNamed: "looping_BG1")
    
    // score var's/labels
    var scoreLabel = SKLabelNode()
    var score = SKLabelNode()
    var highscoreLabel = SKLabelNode()
    var scoreData = -3
    var savedData = UserDefaults.standard
   
    // determine which generated level player is in
    var levelUnitCurrentlyOn:LevelUnit?
    
    // is player dead?
    var isDead:Bool = false
   
    // is player on platform?
    var onPlatform:Bool = false
    var currentPlatform:SKSpriteNode?
    
    // where player starts
    let startingPosition:CGPoint = CGPoint(x: 50, y: 0)
    
    // mouse location
    var mouseLocation:CGPoint = CGPoint(x: 0, y: 0)
    
    let footSteps = SKEmitterNode(fileNamed: "FootSteps.sks")
    
    override func didMove(to view: SKView) {
        
        // set up footstep audio
        if let path = Bundle.main.path(forResource: "footstepsSound", ofType: "wav") {
            do {
                footstepSoundPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                footstepSoundPlayer?.numberOfLoops = -1
                footstepSoundPlayer?.enableRate = true
                footstepSoundPlayer?.rate = 2.0 // playback speed
            } catch {
                print("error loading footstep sounds")
            }
        }
        
        // start background sounds
        playBackgroundSound()
        
        //set custom cursor
        self.view!.resetCursorRects()
        
        // set default highscore of 0 if none is saved
        savedData.register(defaults: ["highscore": 0])
        
        // set background/screen
        self.backgroundColor = NSColor.black
        screenWidth = self.view!.bounds.width
        screenHeight = self.view!.bounds.height
        levelUnitWidth = screenWidth
        levelUnitHeight = screenHeight
        
        // physics gravity
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx:0, dy:-7.8)
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        addChild(worldNode)
        
        // player is placed in worldNode
        worldNode.addChild(thePlayer)
        thePlayer.position = startingPosition
        thePlayer.zPosition = 101
        
        // set up score label
        scoreLabel.text = "Score: "
        scoreLabel.fontSize = 40
        scoreLabel.zPosition = 1000
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.verticalAlignmentMode = .top
        scoreLabel.position = CGPoint(x: -740.0, y: 335.0)
        addChild(scoreLabel)
        score.text = "0"
        score.fontSize = 40
        score.zPosition = 1000
        score.horizontalAlignmentMode = .left
        score.verticalAlignmentMode = .top
        score.position = CGPoint(x: -630.0, y: 333.0)
        addChild(score)
        
        // set up highscore label
        highscoreLabel.text = "Highscore: " + String(savedData.integer(forKey: "highscore"))
        highscoreLabel.fontSize = 40
        highscoreLabel.zPosition = 1000
        highscoreLabel.horizontalAlignmentMode = .left
        highscoreLabel.verticalAlignmentMode = .top
        highscoreLabel.position = CGPoint(x: -740.0, y: 375.0)
        addChild(highscoreLabel)
        
        // generate 2 levels in front of player
        addLevelUnits()
        
        // add looping backgrounds
        addChild(loopingBG)
        addChild(loopingBG2)
        
        // set backgrounds in background
        loopingBG.zPosition = -200
        loopingBG2.zPosition = -200
        
        // begin looping backgrounds
        startLoopingBackground()
        
        worldNode.addChild(footSteps!)
        
    }
    
    func startLoopingBackground() {
        
        resetLoopingBackground()
        
        // action sequence to move backgrounds
        let move:SKAction = SKAction.moveBy(x: -loopingBG2.size.width, y: 0, duration: 20)
        let moveBack:SKAction = SKAction.moveBy(x: loopingBG2.size.width, y: 0, duration: 0)
        let seq:SKAction = SKAction.sequence([move, moveBack])
        let `repeat`:SKAction = SKAction.repeatForever(seq)
        loopingBG.run(`repeat`)
        loopingBG2.run(`repeat`)
    }
    
    // register keyboard input
    override func keyDown(with event: NSEvent) {
        
        // player must be alive
        // key must be spacebar(49)
        // key cannot register more than once on a single press
        if (isDead == false && event.keyCode == 49 && !event.isARepeat) {
            
            // player must be touching platform or floor
            if thePlayer.isGrounded {
                
                // player jumps
                thePlayer.jump()
                
                // play random jump sound effect
                let jumpSound = arc4random_uniform(2)
                if (jumpSound == 0) {
                    run(jumpSound1)
                } else if (jumpSound == 1) {
                    run(jumpSound2)
                } else if (jumpSound == 2) {
                    run(jumpSound3)
                }
            }
        }
        
        // R key will reset highscore
        if (event.keyCode == 15) {
            
            // set new score as highscore
            savedData.set(0, forKey: "highscore")
            
            // update highscore label
            highscoreLabel.text = "Highscore: " + String(savedData.integer(forKey: "highscore"))
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        
        // shoot blue shuriken
        mouseLocation = event.locationInWindow
        run(throwSound)
        shoot(shotType: 0)
    }
    
    override func rightMouseDown(with event: NSEvent) {
        // shoot red shuriken
        mouseLocation = event.locationInWindow
        run(throwSound)
        shoot(shotType: 1)
        
    }

    func shoot(shotType type: Int) {
        
        let bulletTexture:SKTexture
        // create bullet:
        if (type == 0) {
            bulletTexture = SKTexture(imageNamed: "shurikenB")
        } else {
            bulletTexture = SKTexture(imageNamed: "shurikenR")
        }
        let bullet:PlayerBullet = PlayerBullet(texture: bulletTexture, size: CGSize(width: 28.5, height: 28.5))
        bullet.position = thePlayer.position
        bullet.zPosition = 90
        let body:SKPhysicsBody = SKPhysicsBody(circleOfRadius: bulletTexture.size().width , center:CGPoint(x: 0, y: 0))
        body.affectedByGravity = false
        body.allowsRotation = true
        body.restitution = 0.0
        body.contactTestBitMask = BodyType.ground.rawValue | BodyType.platformObject.rawValue | BodyType.playerTypeB.rawValue | BodyType.playerTypeR.rawValue
        body.collisionBitMask = BodyType.ground.rawValue | BodyType.platformObject.rawValue
        if (type == 0) {
            body.categoryBitMask = BodyType.playerTypeB.rawValue
        } else {
            body.categoryBitMask = BodyType.playerTypeR.rawValue
        }
        bullet.physicsBody = body
        worldNode.addChild(bullet)
        // player is player point
        let player = CGPoint(x: self.convert(thePlayer.position, from: worldNode).x - 100 ,y: thePlayer.position.y)
        
        // mouse is mouse point
        let mouse = CGPoint(x: mouseLocation.x - screenWidth/2, y: mouseLocation.y - screenHeight/2)
        
        // distance sets the speed of each bullet
        let distance:CGFloat = 100.0
        
        bullet.physicsBody?.angularVelocity = CGFloat(30)
        
        // angle from player to mouse
        let angle = atan2(mouse.y - player.y, mouse.x - player.x)
        
        // points calculated to have a constant distance but different direction based on mouse position
        let pointX = player.x + distance * cos(angle)
        let pointY = player.y + distance * sin(angle)
        
        // push bullet in mouse direction
        bullet.physicsBody?.applyImpulse(CGVector(dx: (pointX - player.x), dy: (pointY - player.y)))
    }
    
    // restart level after death
    func resetLevel() {
        
        // remove levelunit children from world node
        worldNode.enumerateChildNodes(withName: "levelUnit" ) {
            node, stop in
            node.removeFromParent()
        }
        
        // reset levelunit counter
        levelUnitCounter = 0
        
        // reset sounds
        soundPlayed1 = true
        soundPlayed2 = true
        soundPlayed3 = true
        
        // generate new levels
        addLevelUnits()
    }
    
    // how many levelunits should be generated
    func addLevelUnits() {
        
        for _ in 0 ..< initialUnits {
            
            createLevelUnit()
        }
    }
    
    
    
    // generate a level
    func createLevelUnit() {
        
        // set loaction based on which unit is created
        let yLocation:CGFloat = 0
        let xLocation:CGFloat = levelUnitCounter * levelUnitWidth
        
        // create level object
        let levelUnit:LevelUnit = LevelUnit()
        
        // add level to world node
        worldNode.addChild(levelUnit)
        levelUnit.zPosition = -1
        levelUnit.levelUnitWidth = levelUnitWidth
        levelUnit.levelUnitHeight = levelUnitHeight
        
        // check if unit is first
        if (levelUnitCounter < 2) {

            levelUnit.isFirstUnit = true
        }
        
        // set up level
        levelUnit.setUpLevel()
        levelUnit.position = CGPoint( x: xLocation , y: yLocation)
        
        // increase counter for next level
        levelUnitCounter += 1
        
        // score is increased by 1 for each level
        scoreData += 1
        
        // update score label
        score.text = String(scoreData)
        
        // increase speed as level progresses
        if (scoreData > 100 && isDead == false && scoreData < 200) {
            thePlayer.minSpeed = CGFloat(10)
            // play getting faster sound once
            if (soundPlayed1) {
                run(gettingFasterSound)
                footstepSoundPlayer?.rate = 3.0 // increase footstep sound speed
                soundPlayed1 = false
            }
        } else if (scoreData >= 200 && isDead == false && scoreData < 300) {
            thePlayer.minSpeed = CGFloat(12)
            // play getting faster sound once
            if (soundPlayed2) {
                run(gettingFasterSound)
                footstepSoundPlayer?.rate = 4.0 // increase footstep sound speed
                soundPlayed2 = false
            }
        } else if (scoreData >= 300 && isDead == false) {
            thePlayer.minSpeed = CGFloat(14)
            // play getting faster sound once
            if (soundPlayed3) {
                run(gettingFasterSound)
                footstepSoundPlayer?.rate = 5.0 // increase footstep sound speed
                soundPlayed3 = false
            }
        }
    }
    
    // remove what player cant see
    func clearNodes() {
        
        // check all levels in world node
        worldNode.enumerateChildNodes(withName: "levelUnit") {
            node, stop in
            
            let nodeLocation:CGPoint = self.convert(node.position, from: self.worldNode)
            
            // if node is off screen
            if ( nodeLocation.x < -(self.screenWidth / 2) - self.levelUnitWidth ) {
                
                // remove node off screen
                node.removeFromParent()
            }
        }
    }
    
    // called before each frame is rendered
    override func update(_ currentTime: TimeInterval) {
        
        let nextTier:CGFloat = (levelUnitCounter * levelUnitWidth) - (CGFloat(initialUnits) * levelUnitWidth)
        
        // check if player is far enough to generate new levels
        if (thePlayer.position.x > nextTier) {
            
            // generate levels
            createLevelUnit()
        }
        
        // clear nodes off screen
        clearNodes()
        
        // check if player is alie
        if ( isDead == false) {
            
            // update living player
            thePlayer.update()
            
            // if player is touching ground
            if (thePlayer.isGrounded) {
                // start footstep audio
                if let footstepSoundPlayer = footstepSoundPlayer, !footstepSoundPlayer.isPlaying {
                    footstepSoundPlayer.play()
                }
                
                // move footstep particle to follow player
                footSteps!.position = CGPoint(x: thePlayer.position.x - 20,y: thePlayer.position.y - 40)
            } else {
                // stop footstep audio
                if let footstepSoundPlayer = footstepSoundPlayer, footstepSoundPlayer.isPlaying {
                    footstepSoundPlayer.pause()
                }
                
                // move footstep particle off screen
                footSteps!.position = CGPoint(x: -1000, y: -1000)
            }
            
        }
    }
    
    override func didSimulatePhysics() {
        
        self.centerOnNode(thePlayer)
    }
    
    // center cam on player
    func centerOnNode(_ node:SKNode) {
        
        let cameraPositionInScene:CGPoint = self.convert(node.position, from: worldNode)
        
        // -200 on x to let player see more of oncoming enemies
        worldNode.position = CGPoint(x: worldNode.position.x - cameraPositionInScene.x - 200, y:0 )
    }
    
    // collision handling:
    func didBegin(_ contact: SKPhysicsContact) {
        
        // enemy and player
        if (contact.bodyA.categoryBitMask == BodyType.player.rawValue  && contact.bodyB.categoryBitMask == BodyType.enemyTypeB.rawValue ) {
            killPlayer()
        } else if (contact.bodyA.categoryBitMask == BodyType.enemyTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.player.rawValue ) {
            killPlayer()
        } else if (contact.bodyA.categoryBitMask == BodyType.player.rawValue  && contact.bodyB.categoryBitMask == BodyType.enemyTypeR.rawValue ) {
            killPlayer()
        } else if (contact.bodyA.categoryBitMask == BodyType.enemyTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.player.rawValue ) {
            killPlayer()
        } else if (contact.bodyA.categoryBitMask == BodyType.player.rawValue  && contact.bodyB.categoryBitMask == BodyType.rainTypeB.rawValue ) {
            killPlayer()
        } else if (contact.bodyA.categoryBitMask == BodyType.rainTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.player.rawValue ) {
            killPlayer()
        } else if (contact.bodyA.categoryBitMask == BodyType.player.rawValue  && contact.bodyB.categoryBitMask == BodyType.rainTypeR.rawValue ) {
            killPlayer()
        } else if (contact.bodyA.categoryBitMask == BodyType.rainTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.player.rawValue ) {
            killPlayer()
        } else if (contact.bodyA.categoryBitMask == BodyType.player.rawValue  && contact.bodyB.categoryBitMask == BodyType.bulletTypeB.rawValue ) {
            killPlayer()
        } else if (contact.bodyA.categoryBitMask == BodyType.bulletTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.player.rawValue ) {
            killPlayer()
        } else if (contact.bodyA.categoryBitMask == BodyType.player.rawValue  && contact.bodyB.categoryBitMask == BodyType.bulletTypeR.rawValue ) {
            killPlayer()
        } else if (contact.bodyA.categoryBitMask == BodyType.bulletTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.player.rawValue ) {
            killPlayer()
        }
        
        // water and player
        if (contact.bodyA.categoryBitMask == BodyType.player.rawValue  && contact.bodyB.categoryBitMask == BodyType.water.rawValue ) {
            killPlayer()
        } else if (contact.bodyA.categoryBitMask == BodyType.water.rawValue  && contact.bodyB.categoryBitMask == BodyType.player.rawValue ) {
            killPlayer()
        }
        
        // shuriken and ground
        if (contact.bodyA.categoryBitMask == BodyType.playerTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.ground.rawValue ) {
            emitter(contact.bodyA, emitter: "MetalOnMetal.sks")
            run(metalOnMetalSound)
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.ground.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeB.rawValue ) {
            emitter(contact.bodyB, emitter: "MetalOnMetal.sks")
            run(metalOnMetalSound)
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.playerTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.ground.rawValue ) {
            emitter(contact.bodyA, emitter: "MetalOnMetal.sks")
            run(metalOnMetalSound)
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.ground.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeR.rawValue ) {
            emitter(contact.bodyB, emitter: "MetalOnMetal.sks")
            run(metalOnMetalSound)
            contact.bodyB.node?.removeFromParent()
        }
        
        // bullet and ground
        if (contact.bodyA.categoryBitMask == BodyType.bulletTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.ground.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.ground.rawValue  && contact.bodyB.categoryBitMask == BodyType.bulletTypeB.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.bulletTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.ground.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.ground.rawValue  && contact.bodyB.categoryBitMask == BodyType.bulletTypeR.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        }
        
        // rain and ground
        if (contact.bodyA.categoryBitMask == BodyType.rainTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.ground.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.ground.rawValue  && contact.bodyB.categoryBitMask == BodyType.rainTypeB.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.rainTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.ground.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.ground.rawValue  && contact.bodyB.categoryBitMask == BodyType.rainTypeR.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        }
        
        // shuriken and enemy
        if (contact.bodyA.categoryBitMask == BodyType.playerTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.enemyTypeB.rawValue ) {
            emitter(contact.bodyA, emitter: "BlueBox.sks")
            emitter(contact.bodyA, emitter: "plus3.sks")
            run(plusThreeSound)
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
            scoreData+=3
        } else if (contact.bodyA.categoryBitMask == BodyType.enemyTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeB.rawValue ) {
            emitter(contact.bodyB, emitter: "BlueBox.sks")
            emitter(contact.bodyB, emitter: "plus3.sks")
            run(plusThreeSound)
            contact.bodyB.node?.removeFromParent()
            contact.bodyA.node?.removeFromParent()
            scoreData+=3
        } else if (contact.bodyA.categoryBitMask == BodyType.playerTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.enemyTypeR.rawValue ) {
            emitter(contact.bodyA, emitter: "RedBox.sks")
            emitter(contact.bodyA, emitter: "plus3.sks")
            run(plusThreeSound)
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
            scoreData+=3
        } else if (contact.bodyA.categoryBitMask == BodyType.enemyTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeR.rawValue ) {
            emitter(contact.bodyB, emitter: "RedBox.sks")
            emitter(contact.bodyB, emitter: "plus3.sks")
            run(plusThreeSound)
            contact.bodyB.node?.removeFromParent()
            contact.bodyA.node?.removeFromParent()
            scoreData+=3
        } else if (contact.bodyA.categoryBitMask == BodyType.playerTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.enemyTypeB.rawValue ) {
            emitter(contact.bodyA, emitter: "MetalOnMetal.sks")
            run(metalOnMetalSound)
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.enemyTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeR.rawValue ) {
            emitter(contact.bodyB, emitter: "MetalOnMetal.sks")
            run(metalOnMetalSound)
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.playerTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.enemyTypeR.rawValue ) {
            emitter(contact.bodyA, emitter: "MetalOnMetal.sks")
            run(metalOnMetalSound)
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.enemyTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeB.rawValue ) {
            emitter(contact.bodyB, emitter: "MetalOnMetal.sks")
            run(metalOnMetalSound)
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.playerTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.rainTypeB.rawValue ) {
            emitter(contact.bodyA, emitter: "plus3.sks")
            emitter(contact.bodyA, emitter: "MetalOnMetal.sks")
            run(plusThreeSound)
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
            scoreData+=3
        } else if (contact.bodyA.categoryBitMask == BodyType.rainTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeB.rawValue ) {
            emitter(contact.bodyB, emitter: "MetalOnMetal.sks")
            emitter(contact.bodyB, emitter: "plus3.sks")
            run(plusThreeSound)
            contact.bodyB.node?.removeFromParent()
            contact.bodyA.node?.removeFromParent()
            scoreData+=3
        } else if (contact.bodyA.categoryBitMask == BodyType.playerTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.rainTypeR.rawValue ) {
            emitter(contact.bodyA, emitter: "MetalOnMetal.sks")
            emitter(contact.bodyA, emitter: "plus3.sks")
            run(plusThreeSound)
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
            scoreData+=3
        } else if (contact.bodyA.categoryBitMask == BodyType.rainTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeR.rawValue ) {
            emitter(contact.bodyB, emitter: "MetalOnMetal.sks")
            emitter(contact.bodyB, emitter: "plus3.sks")
            run(plusThreeSound)
            contact.bodyB.node?.removeFromParent()
            contact.bodyA.node?.removeFromParent()
            scoreData+=3
        } else if (contact.bodyA.categoryBitMask == BodyType.playerTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.rainTypeB.rawValue ) {
            emitter(contact.bodyA, emitter: "MetalOnMetal.sks")
            run(metalOnMetalSound)
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.rainTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeR.rawValue ) {
            emitter(contact.bodyB, emitter: "MetalOnMetal.sks")
            run(metalOnMetalSound)
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.playerTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.rainTypeR.rawValue ) {
            emitter(contact.bodyA, emitter: "MetalOnMetal.sks")
            run(metalOnMetalSound)
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.rainTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeB.rawValue ) {
            emitter(contact.bodyB, emitter: "MetalOnMetal.sks")
            run(metalOnMetalSound)
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.playerTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.bulletTypeB.rawValue ) {
            emitter(contact.bodyA, emitter: "plus3.sks")
            run(plusThreeSound)
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
            scoreData+=3
        } else if (contact.bodyA.categoryBitMask == BodyType.bulletTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeB.rawValue ) {
            emitter(contact.bodyB, emitter: "plus3.sks")
            run(plusThreeSound)
            contact.bodyB.node?.removeFromParent()
            contact.bodyA.node?.removeFromParent()
            scoreData+=3
        } else if (contact.bodyA.categoryBitMask == BodyType.playerTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.bulletTypeR.rawValue ) {
            emitter(contact.bodyA, emitter: "plus3.sks")
            run(plusThreeSound)
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
            scoreData+=3
        } else if (contact.bodyA.categoryBitMask == BodyType.bulletTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeR.rawValue ) {
            emitter(contact.bodyB, emitter: "plus3.sks")
            run(plusThreeSound)
            contact.bodyB.node?.removeFromParent()
            contact.bodyA.node?.removeFromParent()
            scoreData+=3
        } else if (contact.bodyA.categoryBitMask == BodyType.playerTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.bulletTypeB.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.bulletTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeR.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.playerTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.bulletTypeR.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.bulletTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeB.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        }
        
        // shuriken and platform
        if (contact.bodyA.categoryBitMask == BodyType.playerTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.platformObject.rawValue ) {
            emitter(contact.bodyA, emitter: "MetalOnMetal.sks")
            run(metalOnMetalSound)
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.platformObject.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeB.rawValue ) {
            emitter(contact.bodyB, emitter: "MetalOnMetal.sks")
            run(metalOnMetalSound)
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.playerTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.platformObject.rawValue ) {
            emitter(contact.bodyA, emitter: "MetalOnMetal.sks")
            run(metalOnMetalSound)
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.platformObject.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeR.rawValue ) {
            emitter(contact.bodyB, emitter: "MetalOnMetal.sks")
            run(metalOnMetalSound)
            contact.bodyB.node?.removeFromParent()
        }
        
        // rain and platform
        if (contact.bodyA.categoryBitMask == BodyType.rainTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.platformObject.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.platformObject.rawValue  && contact.bodyB.categoryBitMask == BodyType.rainTypeB.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.rainTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.platformObject.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.platformObject.rawValue  && contact.bodyB.categoryBitMask == BodyType.rainTypeR.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        }
        
        // shuriken and water
        if (contact.bodyA.categoryBitMask == BodyType.playerTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.water.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.water.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeB.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.playerTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.water.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.water.rawValue  && contact.bodyB.categoryBitMask == BodyType.playerTypeR.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        }
        
        // bullet and rain
        if (contact.bodyA.categoryBitMask == BodyType.bulletTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.rainTypeB.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.rainTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.bulletTypeB.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.bulletTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.rainTypeR.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.rainTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.bulletTypeR.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.bulletTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.rainTypeR.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.rainTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.bulletTypeB.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.bulletTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.rainTypeB.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.rainTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.bulletTypeR.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        }
        
        // bullet and box
        if (contact.bodyA.categoryBitMask == BodyType.bulletTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.enemyTypeB.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.enemyTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.bulletTypeB.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.bulletTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.enemyTypeR.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.enemyTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.bulletTypeR.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.bulletTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.enemyTypeR.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.enemyTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.bulletTypeB.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.bulletTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.enemyTypeB.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.enemyTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.bulletTypeR.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        }
        
        // rain and water
        if (contact.bodyA.categoryBitMask == BodyType.rainTypeB.rawValue  && contact.bodyB.categoryBitMask == BodyType.water.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.water.rawValue  && contact.bodyB.categoryBitMask == BodyType.rainTypeB.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.rainTypeR.rawValue  && contact.bodyB.categoryBitMask == BodyType.water.rawValue ) {
            
            contact.bodyA.node?.removeFromParent()
        } else if (contact.bodyA.categoryBitMask == BodyType.water.rawValue  && contact.bodyB.categoryBitMask == BodyType.rainTypeR.rawValue ) {
            
            contact.bodyB.node?.removeFromParent()
        }
        
        // if the player hits the ground
        if (contact.bodyA.categoryBitMask == BodyType.ground.rawValue  && contact.bodyB.categoryBitMask == BodyType.player.rawValue ) {
            
            thePlayer.physicsBody?.isDynamic = true
            
            // if player animation isnt running
            if ( thePlayer.isRunning == false) {
                
                // start running
                thePlayer.startRun()
            }
            
            // player is grounded
            thePlayer.isGrounded = true
        } else if (contact.bodyA.categoryBitMask == BodyType.player.rawValue  && contact.bodyB.categoryBitMask == BodyType.ground.rawValue ) {
            thePlayer.physicsBody?.isDynamic = true
            if ( thePlayer.isRunning == false) {
                thePlayer.startRun()
            }
            thePlayer.isGrounded = true
        }
        
        // check if on Platform Object
        if (contact.bodyA.categoryBitMask == BodyType.player.rawValue  && contact.bodyB.categoryBitMask == BodyType.platformObject.rawValue ) {
            
            // on platform and grounded
            onPlatform = true
            thePlayer.isGrounded = true
            
            // set players current platform
            currentPlatform =  contact.bodyB.node! as? SKSpriteNode
            thePlayer.physicsBody?.isDynamic = true
            
            // if player animation isnt running
            if ( thePlayer.isRunning == false) {
                
                // start running
                thePlayer.startRun()
            }
        } else if (contact.bodyA.categoryBitMask == BodyType.platformObject.rawValue  && contact.bodyB.categoryBitMask == BodyType.player.rawValue ) {
            onPlatform = true
            thePlayer.isGrounded = true
            currentPlatform =  contact.bodyA.node! as? SKSpriteNode
            thePlayer.physicsBody?.isDynamic = true
            if ( thePlayer.isRunning == false) {
                thePlayer.startRun()
            }
        }
    }

    func didEnd(_ contact: SKPhysicsContact) {
        
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        switch (contactMask) {
        
        // when player leaves platform
        case BodyType.platformObject.rawValue | BodyType.player.rawValue:
            
            // not on platform
            onPlatform = false

        default:
            return
        }
    }
    
    func emitter(_ contact: SKPhysicsBody, emitter: String) {
        if let particles = SKEmitterNode(fileNamed: emitter), let node = contact.node {
            particles.position = CGPoint(x: self.convert(node.position, from: worldNode).x ,y: node.position.y)
            self.addChild(particles)
        }
    }

    func killPlayer() {
        
        // player must be alive to die
        if ( isDead == false) {
            
            // player DEAD
            isDead = true
            
            // check if new score is greater than highscore
            if (scoreData > savedData.integer(forKey: "highscore")) {
                
                // set new score as highscore
                savedData.set(scoreData, forKey: "highscore")
                
                // update highscore label
                highscoreLabel.text = "Highscore: " + String(savedData.integer(forKey: "highscore"))
            }
            
            // stop looping background
            loopingBG.removeAllActions()
            loopingBG2.removeAllActions()
            
            thePlayer.physicsBody!.isDynamic = false
            
            // stop background sounds
            stopBackgroundSound()
            
            // stop footstep sounds
            if let footstepSoundPlayer = footstepSoundPlayer, footstepSoundPlayer.isPlaying {
                footstepSoundPlayer.pause()
            }
            
            let gameOverAlert: NSAlert = NSAlert()
            gameOverAlert.messageText = "You Lose!"
            gameOverAlert.informativeText = "Your score: " + score.text! + "\n" + "Your Highscore: " + String(savedData.integer(forKey: "highscore"))
            gameOverAlert.alertStyle = .informational
            gameOverAlert.addButton(withTitle: "Try Again")
            gameOverAlert.addButton(withTitle: "Quit")
            let result = gameOverAlert.runModal()
            switch result {
                case NSApplication.ModalResponse.alertFirstButtonReturn:
                resetEverything()
                case NSApplication.ModalResponse.alertSecondButtonReturn:
                run(gameOverSound)
                Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false, block: { _ in NSApp.terminate(self) })
            default:
                resetEverything()
            }
        }
    }
    
    func revivePlayer() {
      
        // action sequence to fade out worldNode and reset the level with new units
        let fadeOut:SKAction = SKAction.fadeAlpha(to: 0, duration: 0.2)
        let block:SKAction = SKAction.run(resetLevel)
        let fadeIn:SKAction = SKAction.fadeAlpha(to: 1, duration: 0.2)
        let seq:SKAction = SKAction.sequence([fadeOut, block, fadeIn])
        worldNode.run(seq)
        
        // action sequence to fade in player and revive
        let wait:SKAction = SKAction.wait(forDuration: 1)
        let fadeIn2:SKAction = SKAction.fadeAlpha(to: 1, duration: 0.2)
        let block2:SKAction = SKAction.run(noLongerDead)
        let seq2:SKAction = SKAction.sequence([wait , fadeIn2, block2])
        thePlayer.run(seq2)
        
        thePlayer.minSpeed = 8
    }
    
    func noLongerDead() {
        
        // player alive again
        isDead = false
        
        // player can start running
        thePlayer.startRun()
        
        // begin the looping backgrounds
        startLoopingBackground()
        
        thePlayer.physicsBody!.isDynamic = true
    }
    
    func chooseRandomBG() -> String {
        let diceRoll = arc4random_uniform(3)
        
        if (diceRoll == 0) {
            return "looping_BG1"
        } else if (diceRoll == 1) {
            return "looping_BG2"
        } else if (diceRoll == 2) {
            return "looping_BG3"
        } else {
            return "looping_BG4"
        }
    }
    func resetLoopingBackground() {
        let randomBackground = chooseRandomBG()
        let loopingBGTexture = SKTexture(imageNamed: randomBackground)
        loopingBG.texture = loopingBGTexture
        loopingBG2.texture = loopingBGTexture
        loopingBG.position = CGPoint(x: 0, y: 0)
        loopingBG2.position = CGPoint(x: loopingBG2.size.width - 3, y: 0)
        
        // play background sounds
        playBackgroundSound()
        
        // set footstep sound speed
        footstepSoundPlayer?.rate = 2.0
    }
    
    func resetEverything() {
        // reset score and score label
        scoreData = -3
        score.text = "0"
        
        // action sequence to reset player
        let fadeOut:SKAction = SKAction.fadeAlpha(to: 0, duration: 0.2)
        let move:SKAction = SKAction.move(to: startingPosition, duration: 0.0)
        let block:SKAction = SKAction.run(revivePlayer)
        let seq:SKAction = SKAction.sequence([fadeOut, move, block])
        thePlayer.run(seq)
        
        // action sequence to reset looping backgrounds
        let fadeOutBG:SKAction = SKAction.fadeAlpha(to: 0, duration: 0.2)
        let blockBG:SKAction = SKAction.run(resetLoopingBackground)
        let fadeInBG:SKAction = SKAction.fadeAlpha(to: 1, duration: 0.2)
        let seqBG:SKAction = SKAction.sequence([fadeOutBG, blockBG, fadeInBG])
        loopingBG.run(seqBG)
        loopingBG2.run(seqBG)
    }
    
    func playBackgroundSound() {
        if let path = Bundle.main.path(forResource: "windBackgroundSound", ofType: "wav") {
            do {
                backgroundSoundPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                backgroundSoundPlayer?.numberOfLoops = -1
                backgroundSoundPlayer?.play()
            } catch {
                print("error loading background sounds")
            }
        }
    }
    
    func stopBackgroundSound() {
        backgroundSoundPlayer?.pause()
    }
}

// override resetcursorects() to create custom cursor
extension SKView {
    override open func resetCursorRects() {
        if let image = NSImage(named:NSImage.Name("crosshair.png")) {
            
            // center pont of image
            let spot = NSPoint(x: 23.5, y: 23)
            let customCursor = NSCursor(image: image, hotSpot: spot)
            addCursorRect(visibleRect, cursor:customCursor)
        }
    }
}
