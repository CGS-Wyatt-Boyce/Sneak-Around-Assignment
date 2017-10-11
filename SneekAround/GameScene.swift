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
    
    var enemyPositionX: CGFloat?
    var enemyPositionY: CGFloat?
    
    let player = SKSpriteNode.init(imageNamed: "character-1")
    
    var velocity = CGPoint.zero
    var velocityE = CGPoint.zero
    var lastTouchLocation: CGPoint?
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    
    let playerRotateRadiansPerSec:CGFloat = 4.0 * π
    var playerMovePointsPerSec: CGFloat = 180.0
    var enemyMovePointsPerSec: CGFloat = 185.0
    var dead = false
    
    let playercatagory: UInt32 = 0x1 << 1
    let enemycatagory: UInt32 = 0x1 << 2
    let buildingcatagory: UInt32 = 0x1 << 3
    
    let enemy = SKSpriteNode.init(imageNamed: "enemy")
    var enemyId = 0
    var withinRange: CGPoint?
    var playerPosInt: CGFloat?
    var enemyPosInt: CGFloat?
    var randomPosition: CGPoint?
    var screenWidth: Int?
    var screenHeight:Int?
    var playerDead = false
    var enemyMoved = false
    
    
    
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
        
        let background = SKSpriteNode.init(imageNamed: "backgroundLevel01")
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        background.zPosition = -1
        addChild(background)
        
        screenWidth = Int(size.width)
        screenHeight = Int(size.height)
        
        func spawnEnemy() {
            
            let randomX =  Int(arc4random_uniform(UInt32(screenWidth!)))
            let randomY = Int(arc4random_uniform(UInt32(screenHeight!)))
            
           enemy.name = "enemy"
            enemy.position = /*CGPoint(x: 800, y: 800)*/CGPoint (
                x: CGFloat(randomX),
                y: CGFloat(randomY))
            
            enemy.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 80, height: 80), center: CGPoint(x: randomX, y: randomY))
            enemy.physicsBody?.affectedByGravity = false
            enemy.physicsBody?.categoryBitMask = enemycatagory
            enemy.physicsBody?.collisionBitMask = enemycatagory | buildingcatagory | playercatagory
            enemy.zPosition = -1.0
            
            enemyPositionX = CGFloat(randomX)
            enemyPositionY = CGFloat(randomY)
            
            print("enemy spawned")
            print("\(randomX) = randomX")
            print("\(randomY) = randomY")
            
            addChild(enemy)
            let actionRemove = SKAction.removeFromParent()
            let _ = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { (timerEnemy) in
                self.enemy.run(actionRemove)
                print("enemy removed")
            }
        }

        func spawnPerson() {
            let person = SKSpriteNode.init(imageNamed: "person")
            person.name = "person"
            
            let randomX =  Int(arc4random_uniform(UInt32(screenWidth!)))
            let randomY = Int(arc4random_uniform(UInt32(screenHeight!)))

            person.position = /*CGPoint(x: 800, y: 800)*/CGPoint (
                x: CGFloat(randomX),
                y: CGFloat(randomY))
            person.setScale(0)
            addChild(person)
            let appear = SKAction.scale(to: 1.0, duration: 0.5)
            person.zRotation = -π / 16.0
            let wait = SKAction.wait(forDuration: 10)
            let disappear = SKAction.scale(to: 0, duration: 0.5)
            let removeFromParent = SKAction.removeFromParent()
            let actions = [appear, wait, disappear, removeFromParent]
            person.run(SKAction.sequence(actions))
        }
        
        print("Player Spawned")
        spawnPlayer()
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run(spawnEnemy),
                               SKAction.wait(forDuration: 32.0)])))
        
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run(spawnPerson),
                               SKAction.wait(forDuration: 1.0)])))


              // playerPosInt = player.position.y + player.position.x
       // enemyPosInt = enemy.position.y + enemy.position.x
    
    }
    
    func spawnPlayer() {
        print("running spawnPlayer")
        player.position = CGPoint(x: 400, y: 400)
        player.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 80, height: 80))
        player.physicsBody?.affectedByGravity = false
        player.physicsBody?.categoryBitMask = playercatagory
        player.physicsBody?.collisionBitMask = enemycatagory | buildingcatagory
        player.zPosition = -1.0
        player.name = "player"
        
    
        //  characterPhysics = CGRect(x: 400, y: 400,
        //      width: size.width, height: size.height)
        
        addChild(player)
        print(player)
     
        player.physicsBody?.categoryBitMask = 1
        player.physicsBody?.contactTestBitMask = 2
        player.physicsBody?.collisionBitMask =  2
        playerDead = false
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
    
// sets the speed and direction for the player to move
    func movePlayerToward(_ location: CGPoint)  {
        let offset = CGPoint (x: location.x - player.position.x, y: location.y - player.position.y)
        let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        let direction = CGPoint(x: offset.x / CGFloat(length), y: offset.y / CGFloat(length))
        velocity = CGPoint(x: direction.x * playerMovePointsPerSec, y: direction.y * playerMovePointsPerSec)
        print("\(velocity) = player velocty")
    }
    // sets the speed and direction for the enemy to move
    func moveEnemyToward(_ location: CGPoint)  {
        let offset = CGPoint (x: location.x - enemy.position.x, y: location.y - enemy.position.y)
        let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        let direction = CGPoint(x: offset.x / CGFloat(length), y: offset.y / CGFloat(length))
        velocityE = CGPoint(x: direction.x * enemyMovePointsPerSec, y: direction.y * enemyMovePointsPerSec)
        print("\(velocityE) = enemy velocity")
    }

    // checks for collisions between sprites
    func checkCollisions() {
        var hitEnemies: [SKSpriteNode] = []
        enumerateChildNodes(withName: "enemy") { node,  _ in
            let enemy = node as! SKSpriteNode
            if enemy.frame.insetBy(dx: 20, dy: 20).intersects(self.player.frame) {
                hitEnemies.append(enemy)
            }
        }
        for enemy in hitEnemies {
            detection()
            
        }
        enumerateChildNodes(withName: "person") { node,  _ in
            let person = node as! SKSpriteNode
        if person.frame.insetBy(dx: 20, dy: 20).intersects(self.player.frame) {
            hitEnemies.append(person)
        }
    }
    for person in hitEnemies {
    playerMovePointsPerSec = 0
        let _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timerEnemy) in
            self.playerMovePointsPerSec = 180.0
        }

    }

    }

// moves the enemy to the players position as if they are being chased
    func detection() {
            print("player detected")
        moveEnemyToward(player.position)
            let diffE = enemy.position - player.position
            if (diffE.length() <= playerMovePointsPerSec * CGFloat(dt)) {
                player.position = enemy.position
                velocityE = CGPoint.zero
            } else {
                moveSpriteE(enemy, velocity: velocityE)
                rotateSpriteE(enemy, direction: velocityE, rotateRadiansPerSec: playerRotateRadiansPerSec)
            }
        
        if enemy.position == player.position {
            if playerDead != true {
                playerDead = true
                death()
                playerMovePointsPerSec = 0
            }
        }
  
        }
    // sets the distance for the sprite to move
    func moveSprite(_ sprite: SKSpriteNode, velocity: CGPoint){
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dt),
                                   y: velocity.y * CGFloat(dt))
        sprite.position = CGPoint(x: sprite.position.x + amountToMove.x,
                                  y: sprite.position.y + amountToMove.y)

    }
    
    func moveSpriteE(_ sprite: SKSpriteNode, velocity: CGPoint){
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dt),
                                   y: velocity.y * CGFloat(dt))
        sprite.position = CGPoint(x: sprite.position.x + amountToMove.x,
                                  y: sprite.position.y + amountToMove.y)
        print("\(velocity) = velocity peram")
        print("\(amountToMove) = amount to move")
        
    }
    
// sets the angle for the sprite to rotate
    func rotateSprite(_ sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
        let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += shortest.sign() * amountToRotate
    }
    
    func rotateSpriteE(_ sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat) {
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocityE.angle)
        let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += shortest.sign() * amountToRotate
    }
    
    // plays a death animation
    func death() {
        print("death run")
            let disappear = SKAction.scale(to: 0, duration: 0.5)
            let removeFromParent = SKAction.removeFromParent()
            let actions = [disappear, removeFromParent]
            player.run(SKAction.sequence(actions))
            let _ = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { (timerEnemy) in
                print("call spawnPlayer")
                let reScale = SKAction.scale(to: 1, duration: 0.5)
                self.player.run(reScale)
                self.spawnPlayer()
                timerEnemy.invalidate()
        }
    }
    // sets a random point on the screen for the enemy to make their way to
    func randomMovement() {
        if enemyMoved == true {
            print("random movement ran")
            let randomPoint = SKSpriteNode.init()
            let randomX =  Int(arc4random_uniform(UInt32(screenWidth!)))
            let randomY = Int(arc4random_uniform(UInt32(screenHeight!)))
            randomPoint.position = CGPoint(x: randomX, y: randomY)
            print("\(randomPoint.position) = random position")
            randomPoint.name = "Random Point"
            
            addChild(randomPoint)
            print("\(randomPoint) = randomPoint")
            
            moveEnemyToward(randomPoint.position)
            print("\(randomPoint.position) DEBUG1")
            let diffE = enemy.position - randomPoint.position
            if (diffE.length() <= enemyMovePointsPerSec * CGFloat(dt)) {
                randomPoint.position = enemy.position
                velocityE = CGPoint.zero
            } else {
                moveSpriteE(enemy, velocity: velocityE)
                rotateSpriteE(enemy, direction: velocityE, rotateRadiansPerSec: playerRotateRadiansPerSec)
            }
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
    
    func boundsCheckEnemy() {
        let bottomLeft = CGPoint(x: playableRect.minX, y: playableRect.minY)
        let topRight = CGPoint(x: playableRect.maxX, y: playableRect.maxY)
        
        if enemy.position.x <= bottomLeft.x {
            enemy.position.x = bottomLeft.x
            velocityE.x = -velocityE.x
        }
        if enemy.position.x >= topRight.x {
            enemy.position.x = topRight.x
            velocityE.x = -velocityE.x
        }
        if enemy.position.y <= bottomLeft.y {
            enemy.position.y = bottomLeft.y
            velocityE.y = -velocityE.y
        }
        if enemy.position.y >= topRight.y {
            enemy.position.y = topRight.y
            velocityE.y = -velocityE.y
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
        if enemyMoved == false {
            enemyMoved = true
            randomMovement()
        }
        boundsCheckPlayer()
        boundsCheckEnemy()
        checkCollisions()
        if enemy.position == randomPosition {
            enemyMoved = false
        }
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



