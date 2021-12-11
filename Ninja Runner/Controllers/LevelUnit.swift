import Foundation
import SpriteKit

class LevelUnit:SKNode {
    
    // initialize level var's
    var imageName:String = ""
    var backgroundSprite:SKSpriteNode = SKSpriteNode()
    var levelUnitWidth:CGFloat = 0
    var levelUnitHeight:CGFloat = 0
    var theType:LevelType = LevelType.ground
    var numberOfObjectsInLevel:UInt32 = 0
    var offscreenCounter:Int = 0
    var maxObjectsInLevelUnit:UInt32 = 2
    var isFirstUnit:Bool = false
    
    // required:
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init () {
        super.init()
    }
    
    func setUpLevel(){
        
        // choose random level
        let diceRoll = arc4random_uniform(5)
        
        if (diceRoll == 0) {
            imageName = "Background1"
        } else if (diceRoll == 1) {
            imageName = "Background2"
        } else if (diceRoll == 2) {
            imageName = "Background3"
        } else if (diceRoll == 3) {
            imageName = "Background4"
        } else if (diceRoll == 4) {
            
            // first unit cannot be water type
            if (isFirstUnit == false) {
                let randomWaterBackground = Bool.random()
                
                // choose 1 of 2 water backgrounds
                if (randomWaterBackground) {
                    imageName = "WaterBackground1"
                } else {
                    imageName = "WaterBackground2"
                }
                theType = LevelType.water
            } else {
                imageName = "Background4"
            }
        }
        
        // set up level
        let theSize:CGSize = CGSize(width: levelUnitWidth, height: levelUnitHeight)
        let tex:SKTexture = SKTexture(imageNamed: imageName)
        backgroundSprite = SKSpriteNode(texture: tex, color: SKColor.clear, size: theSize)
        
        //add sprite to level
        self.addChild(backgroundSprite)
        self.name = "levelUnit"
        self.position = CGPoint(x: backgroundSprite.size.width / 2, y: 0)
        
        // level physics:
        backgroundSprite.physicsBody = SKPhysicsBody(rectangleOf: backgroundSprite.size, center:CGPoint(x: 0, y: -backgroundSprite.size.height * 0.88))
        backgroundSprite.physicsBody!.isDynamic = false
        backgroundSprite.physicsBody!.restitution = 0
        
        // if level is water type:
        if (theType == LevelType.water) {

            backgroundSprite.physicsBody!.categoryBitMask = BodyType.water.rawValue
            backgroundSprite.physicsBody!.contactTestBitMask = BodyType.water.rawValue
            self.zPosition = 400
            
            // build 3 random platforms
            for platforms in 1...3 {
                let platform:Box = Box(imageNamed: "Platform")
                let newSize:CGSize = CGSize(width: platform.size.width, height: 10)
                
                platform.physicsBody = SKPhysicsBody(rectangleOf: newSize, center:CGPoint(x: 0, y: 50))
                platform.physicsBody!.categoryBitMask = BodyType.platformObject.rawValue
               
                platform.physicsBody!.friction = 1
                platform.physicsBody!.isDynamic = false
                platform.physicsBody!.affectedByGravity = false
                platform.physicsBody!.restitution = 0.0
                platform.physicsBody!.allowsRotation = false
                
                var ypos:Int
                
                if (platforms == 1) {
                    
                    // first platform must be reachable by jump
                    ypos = -100
                } else {
                    ypos = Int.random(in: -100..<150)
                }
                platform.position = CGPoint(x: CGFloat(platforms * 450) + CGFloat.random(in: 0..<100) - CGFloat(levelUnitWidth / 2) - CGFloat(200), y: CGFloat(ypos))
                addChild(platform)
            }
            
        } else if (theType == LevelType.ground){
            backgroundSprite.physicsBody!.categoryBitMask = BodyType.ground.rawValue
            backgroundSprite.physicsBody!.contactTestBitMask = BodyType.ground.rawValue
        }
        
        // no obstacles on first level
        if ( isFirstUnit == false && theType == LevelType.ground) {
            
            createObstacle()
        }
    }
    
    func createObstacle() {
        if (theType == LevelType.ground) {
            
            // choose random level type
            let diceRoll = arc4random_uniform(3)
            // 0 is rain level with falling knives(kunai)
            // 1 is a single turret level
            // 2 is stacks of boxes level
            
            if ( diceRoll == 0) { // rain level
                
                // create rain controller to drop knives
                let rainController:Rain = Rain()
                addChild(rainController)
            } else if ( diceRoll == 1) { // turret level
                
                // set up turret object
                let turret1:Turret = Turret(texture: SKTexture(imageNamed: "turret"), size: CGSize(width: 160, height: 130))
                turret1.physicsBody = SKPhysicsBody(circleOfRadius: CGFloat(turret1.size.width / 3.0), center: CGPoint(x: 0, y: 0))
                turret1.physicsBody!.friction = 1
                turret1.physicsBody!.isDynamic = false
                turret1.physicsBody!.affectedByGravity = false
                turret1.physicsBody!.restitution = 0.0
                turret1.physicsBody!.allowsRotation = false
                turret1.physicsBody!.categoryBitMask = BodyType.ground.rawValue
                turret1.physicsBody!.contactTestBitMask = BodyType.ground.rawValue
                turret1.zPosition = 200
                turret1.position = CGPoint(x: 1200 - (levelUnitWidth / 2), y: -289)
                addChild(turret1)
            } else if ( diceRoll == 2) { // boxes level
                
                // set random number of stacked boxes
                var stackNumber = arc4random_uniform(4)
                // add 2 so there is always 2 stacks at least
                stackNumber += 2
                
                // create x number of stacks
                for stack in 1...stackNumber {
                    
                    // choose random height of stack
                    var boxAmount = arc4random_uniform(5)
                    // height is always 1
                    boxAmount += 1
                    var xpos = 150.0 * Float(stack)
                    xpos = xpos + Float.random(in: 0..<50)
                    for boxes in 1...boxAmount {
                        let boxType = Bool.random()
                        var texture:SKTexture
                        if (boxType) {
                            texture = SKTexture(imageNamed: "boxR")
                        } else {
                            texture = SKTexture(imageNamed: "boxB")
                        }
                        let box:Box = Box(texture: texture, size: CGSize(width: 90, height: 90))
                        box.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 80, height: 80), center: CGPoint (x: 0, y: 0))
                        if (boxType) {
                            box.physicsBody!.categoryBitMask = BodyType.enemyTypeR.rawValue
                        } else {
                            box.physicsBody!.categoryBitMask = BodyType.enemyTypeB.rawValue
                        }
                        box.physicsBody!.contactTestBitMask = BodyType.enemyTypeR.rawValue | BodyType.ground.rawValue | BodyType.enemyTypeB.rawValue | BodyType.player.rawValue | BodyType.playerTypeB.rawValue | BodyType.playerTypeR.rawValue | BodyType.bulletTypeB.rawValue | BodyType.bulletTypeR.rawValue
                        box.physicsBody!.friction = 1
                        box.physicsBody!.isDynamic = false
                        box.physicsBody!.affectedByGravity = false
                        box.physicsBody!.restitution = 0.0
                        box.physicsBody!.allowsRotation = false
                        
                        box.zPosition = 2
                        box.position = CGPoint( x: CGFloat(xpos) - (levelUnitWidth / 2),  y: CGFloat(90 * boxes) - 339)
                        addChild(box)
                    }
                }
            }
        }
    }
}
