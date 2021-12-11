import Foundation
import SpriteKit

class Rain: SKNode {

    private var timer = Timer()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override init() {
        super.init()
        
        // start timer to drop knives every 0.75 seconds
        timer = .scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(rainTimer), userInfo: nil, repeats: true)
        timer.fire()
    }
    
    @objc func rainTimer() {
        
        // choose random rain color ie blue or red
        let rainType = Bool.random()
        var texture:SKTexture
        if (rainType) {
            texture = SKTexture(imageNamed: "kunaiR")
        } else {
            texture = SKTexture(imageNamed: "kunaiB")
        }
        let rain:Box = Box(texture: texture, size: CGSize(width: 16, height: 80))
        rain.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 12, height: 75), center: CGPoint(x: 0, y: 0))
        if (rainType) {
            rain.physicsBody!.categoryBitMask = BodyType.rainTypeR.rawValue
        } else {
            rain.physicsBody!.categoryBitMask = BodyType.rainTypeB.rawValue
        }
        rain.physicsBody!.collisionBitMask = 0
        rain.physicsBody!.contactTestBitMask = BodyType.rainTypeR.rawValue | BodyType.ground.rawValue | BodyType.rainTypeB.rawValue | BodyType.player.rawValue | BodyType.playerTypeB.rawValue | BodyType.playerTypeR.rawValue | BodyType.water.rawValue | BodyType.bulletTypeR.rawValue | BodyType.bulletTypeB.rawValue
        rain.physicsBody!.friction = 1
        rain.physicsBody!.isDynamic = true
        rain.physicsBody!.affectedByGravity = true
        rain.physicsBody!.linearDamping = CGFloat(3)
        rain.physicsBody!.restitution = 0.0
        rain.physicsBody!.allowsRotation = true
        
        rain.zPosition = 2
        let xpos = Int.random(in: 100..<1400)
        rain.position = CGPoint( x: CGFloat(xpos) - (1500 / 2),  y: CGFloat(500))
        addChild(rain)
    }
}
