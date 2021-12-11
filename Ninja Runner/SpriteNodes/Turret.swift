import Foundation
import SpriteKit

class Turret: SKSpriteNode {
    
    private var fired = false
    private var timer = Timer()
    private let shootingMissleSound = SKAction.playSoundFileNamed("shootingMissleSound.wav", waitForCompletion: true)
    
    override init(texture: SKTexture?, color: NSColor, size: CGSize) {
        super.init(texture: texture, color: color, size: size)
        timer = .scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(fireBullet), userInfo: nil, repeats: true)
        timer.fire()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func fireBullet() {
        
        // for some reason first shot is bugged so wait for second shot
        if (fired) {
            
            // play shooting sound
            run(shootingMissleSound)
            
            // choose random bullet type ie red or blue
            let bulletType = Bool.random()
            
            // create bullet:
            let bulletTexture:SKTexture
            if (bulletType) {
                bulletTexture = SKTexture(imageNamed: "bulletB")
            } else {
                bulletTexture = SKTexture(imageNamed: "bulletR")
            }
            let bullet:PlayerBullet = PlayerBullet(texture: bulletTexture, size: CGSize(width: 50, height: 30))
            bullet.position = CGPoint(x: self.position.x - 110 - 450, y: self.position.y + 54 + 288)
            bullet.zPosition = 91
            let body:SKPhysicsBody = SKPhysicsBody(circleOfRadius: bulletTexture.size().width / 3.0, center:CGPoint(x: 0, y: 0))
            body.isDynamic = true
            body.affectedByGravity = false
            body.allowsRotation = false
            body.restitution = 0.0
            body.friction = 1
            body.collisionBitMask = 0
            body.contactTestBitMask = BodyType.player.rawValue | BodyType.playerTypeB.rawValue | BodyType.playerTypeR.rawValue | BodyType.ground.rawValue | BodyType.rainTypeB.rawValue | BodyType.rainTypeR.rawValue | BodyType.enemyTypeB.rawValue | BodyType.enemyTypeR.rawValue
            if (bulletType) {
                body.categoryBitMask = BodyType.bulletTypeB.rawValue
            } else {
                body.categoryBitMask = BodyType.bulletTypeR.rawValue
            }
            bullet.physicsBody = body
            bullet.physicsBody?.velocity = CGVector(dx: -80 - self.position.x, dy: 0)
            
            // set up shot fired particle effect
            let shotBlast = SKEmitterNode(fileNamed: "TurretShot.sks")
            shotBlast?.position = CGPoint(x: bullet.position.x + 20 , y: bullet.position.y)
            addChild(shotBlast!)
            addChild(bullet)
            
        } else {
            // this is first shot, trigger next shot
            fired = true
        }
    }
}
