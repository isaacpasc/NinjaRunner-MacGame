import Cocoa
import SpriteKit

class ViewController: NSViewController {
    
    
    @IBOutlet var skView: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // run game scene on launch
        if let view = self.skView {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill
                scene.size = skView.bounds.size
                
                // Present the scene
                view.presentScene(scene)
            }
            
            // for performace
            view.ignoresSiblingOrder = true
            
            // for debugging
            //view.showsFPS = true
            //view.showsNodeCount = true
            //view.showsPhysics = true
        }
    }
    
}
