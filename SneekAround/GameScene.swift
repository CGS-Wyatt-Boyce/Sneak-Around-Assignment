//
//  GameScene.swift
//  SneekAround
//
//  Created by Wyatt A. Boyce on 8/8/17.
//  Copyright © 2017 Wyatt A. Boyce. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var label : SKLabelNode?
    private var spinnyNode : SKShapeNode?
    
    let playableRect: CGRect

    let player = SKSpriteNode.init(imageNamed: "character-1")
    var velocity = CGPoint.zero
    var lastTouchLocation: CGPoint?
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    let playerRotateRadiansPerSec:CGFloat = 4.0 * π
    let playerMovePointsPerSec: CGFloat = 180.0
    var dead = false
    let playerCatagory: UInt32 = 0x1 << 1
    let enemyCatagory: UInt32 = 0x1 << 2
    let buildingCatagory: UInt32 = 0x1 << 3
  //  var characterPhysics: CGRect
    
    func didBegin(_ contact: SKPhysicsContact) {
        print("contact")
        if contact.collisionImpulse > 0 &&
            contact.bodyA.node?.name == "player" &&
            contact.bodyB.node?.name == "enemy"{
            death()
        }
    }
    
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        
        let obstacle = SKSpriteNode.init(imageNamed: "")
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: CGSize(), center: CGPoint())
        
        let background = SKSpriteNode.init(imageNamed: "backgroundLevel01")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        background.zPosition = -1
        addChild(background)
        
        let screenWidth = Int(size.width)
        let screenHeight = Int(size.height)
        
        
        func spawnEnemy() {
            
            let randomX =  Int(arc4random_uniform(UInt32(screenWidth)))
            let randomY = Int(arc4random_uniform(UInt32(screenHeight)))
            
            let enemy = SKSpriteNode.init(imageNamed: "enemy")
            enemy.position = /*CGPoint(x: 800, y: 800)*/CGPoint (
                x: CGFloat(randomX),
                y: CGFloat(randomY))
            
            enemy.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 80, height: 80), center: CGPoint(x: randomX, y: randomY))
            enemy.physicsBody?.affectedByGravity = false
            enemy.physicsBody?.categoryBitMask = enemyCatagory
            enemy.physicsBody?.collisionBitMask = enemyCatagory | buildingCatagory | playerCatagory
            enemy.zPosition = -1.0
            
            print("enemy spawned")
            print("\(randomX) = randomX")
            print("\(randomY) = randomY")
            
            addChild(enemy)
            
            let actionRemove = SKAction.removeFromParent()
            let _ = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false) { (timerEnemy) in
                enemy.run(actionRemove)
                print("enemy removed")
            }
        }

        
        player.position = CGPoint(x: 400, y: 400)
        player.zPosition = 1
        player.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 80, height: 80))
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = playerCatagory
        player.physicsBody?.collisionBitMask = enemyCatagory | buildingCatagory
        player.zPosition = -1.0
      //  characterPhysics = CGRect(x: 400, y: 400,
      //      width: size.width, height: size.height)
        
        addChild(player)
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run(spawnEnemy),
                               SKAction.wait(forDuration: 10.0)])))
    
        player.physicsBody?.categoryBitMask = 1
        player.physicsBody?.contactTestBitMask = 2
        player.physicsBody?.collisionBitMask =  2

    }
    
    override init(size: CGSize) {
        let maxAspectRatio:CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height-playableHeight)/2.0
        
        
        playableRect = CGRect(x: 0, y: playableMargin,
                              width: size.width, height: playableHeight)
         super.init(size: size)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func movePlayerToward(_ location: CGPoint)  {
        let offset = CGPoint (x: location.x - player.position.x, y: location.y - player.position.y)
        let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        let direction = CGPoint(x: offset.x / CGFloat(length), y: offset.y / CGFloat(length))
        velocity = CGPoint(x: direction.x * playerMovePointsPerSec, y: direction.y * playerMovePointsPerSec)
    }
    
    func detection() {
        if player.position() == player.position(x: enemyPositionX ) {
            
        }
    }
    
    func moveSprite(_ sprite: SKSpriteNode, velocity: CGPoint){
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dt),
                                   y: velocity.y * CGFloat(dt))
        sprite.position = CGPoint(x: sprite.position.x + amountToMove.x,
                                  y: sprite.position.y + amountToMove.y)
    }

    func rotateSprite(_ sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
        let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += shortest.sign() * amountToRotate
    }
    
    func death() {
        if dead == true {
            let disappear = SKAction.scale(to: 0, duration: 0.5)
            let removeFromParent = SKAction.removeFromParent()
            let actions = [disappear, removeFromParent]
            player.run(SKAction.sequence(actions))
        }
    }
    
    func boundsCheckPlayer() {
        let bottomLeft = CGPoint(x: playableRect.minX, y: playableRect.minY)
        let topRight = CGPoint(x: playableRect.maxX, y: playableRect.maxY)
        
        if player.position.x <= bottomLeft.x {
            player.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        if player.position.x >= topRight.x {
            player.position.x = topRight.x
            velocity.x = -velocity.x
        }
        if player.position.y <= bottomLeft.y {
            player.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        if player.position.y >= topRight.y {
            player.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }


    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        
        
        
        if let lastTouchLocation = lastTouchLocation {
            let diff = lastTouchLocation - player.position
            if (diff.length() <= playerMovePointsPerSec * CGFloat(dt)) {
                player.position = lastTouchLocation
                velocity = CGPoint.zero
            } else {
                moveSprite(player, velocity: velocity)
                rotateSprite(player, direction: velocity, rotateRadiansPerSec: playerRotateRadiansPerSec)
            }
        }
        boundsCheckPlayer()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.location(in: self)
        lastTouchLocation = touchLocation
        movePlayerToward(touchLocation)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let touchLocation = touch.location(in: self)
        lastTouchLocation = touchLocation
        movePlayerToward(touchLocation)
    }
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGMutablePath()
        path.addRect(playableRect)
        shape.path = path
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
   
}



