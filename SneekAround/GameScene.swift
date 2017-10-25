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
    
    var enemyImageName = "enemy"
    var personImageName = "person"
    var playerImageName = "character-1"
    var backgroundImageName = "backgroundLevel01"
    
    var velocity = CGPoint.zero
    var velocityE = CGPoint.zero
    var lastTouchLocation: CGPoint?
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    
    let playerRotateRadiansPerSec:CGFloat = 4.0 * π
    var playerMovePointsPerSec: CGFloat = 180.0
    var enemyMovePointsPerSec: CGFloat = 190.0
    var dead = false
    
    let randomPoint = SKSpriteNode.init()
    var enemyId = 0

    var randomPosition: CGPoint?
    var screenWidth: Int?
    var screenHeight:Int?
    var playerDead = false
    var levelChanged = false
    var enemyMoving = false
    var playerMoving = false
    
    var player = SKSpriteNode.init()
    var enemy = SKSpriteNode.init()
     let finishZone = SKSpriteNode.init(imageNamed: "end")
    
    func spawnBackground() {
        let background = SKSpriteNode.init(imageNamed: backgroundImageName)
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        background.zPosition = -1
        addChild(background)
        
        func removeBackground() {
            let _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timerEnemy) in
                let remove = SKAction.removeFromParent()
                background.run(remove)
            }
        }
        if levelChanged == true {
           removeBackground()
            print("level changed ran")
            let _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timerEnemy) in
            self.levelChanged = false
            }
        }
    }
    
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self
        
        finishZone.name = "finish"
        finishZone.position = CGPoint(x: 2000, y: 1200)
        finishZone.zPosition = 2
        
        addChild(finishZone)
        
        screenWidth = Int(size.width)
        screenHeight = Int(size.height)
        
        spawnBackground()
        
        func spawnPerson() {
            let person = SKSpriteNode.init(imageNamed: personImageName)
            person.name = "person"
            
            let randomX =  Int(arc4random_uniform(UInt32(screenWidth!)))
            let randomY = Int(arc4random_uniform(UInt32(screenHeight!)))

            person.position = CGPoint (
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
        
       
        spawnPlayer()
        
       run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run(spawnEnemy),
                               SKAction.wait(forDuration: 31.0)])))
 
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run(spawnPerson),
                               SKAction.wait(forDuration: 1.0)])))
    
    }
    
    func spawnPlayer() {
        player = SKSpriteNode.init(imageNamed: playerImageName)
        
        player.position = CGPoint(x: 400, y: 400)
        player.zPosition = 0
        player.name = "player"
        
        addChild(player)
     
        playerDead = false
        playerMovePointsPerSec = 180.0
    }
    
    func spawnEnemy() {
        
        enemy = SKSpriteNode.init(imageNamed: enemyImageName)
        
        let randomX =  Int(arc4random_uniform(UInt32(screenWidth!)))
        let randomY = Int(arc4random_uniform(UInt32(screenHeight!)))
        
        enemy.name = "enemy"
        enemy.position = CGPoint (
            x: CGFloat(randomX),
            y: CGFloat(randomY))
        
        addChild(enemy)
        
        let _ = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { (timerEnemy) in
            self.enemy.removeFromParent()
            self.randomPoint.removeFromParent()
        }
        randomMovement()
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
    }
    // sets the speed and direction for the enemy to move
    func moveEnemyToward(_ location: CGPoint)  {
        let offset = CGPoint (x: location.x - enemy.position.x, y: location.y - enemy.position.y)
        let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        let direction = CGPoint(x: offset.x / CGFloat(length), y: offset.y / CGFloat(length))
        velocityE = CGPoint(x: direction.x * enemyMovePointsPerSec, y: direction.y * enemyMovePointsPerSec)
    }
    
    func finished() {
        let _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timerEnemy) in
            print("Changed level")
            self.enemyImageName = "enemy L" + "2"
            self.personImageName = "person L" + "2"
            self.backgroundImageName = "backgroundLevel0" + "2"
            self.spawnBackground()
            self.death()
            self.enemy.removeFromParent()
            self.randomPoint.removeFromParent()
            self.spawnEnemy()
        }
    }
    

    // checks for collisions between sprites
    func checkCollisions() {
        var hitEnemies: [SKSpriteNode] = []
        var hitPeople: [SKSpriteNode] = []
        var hitRandomPoint: [SKSpriteNode] = []
        var hitFinish: [SKSpriteNode] = []
         var nodeArray = [SKNode]()
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
            hitPeople.append(person)
        }
    }
    for person in hitPeople {
    playerMovePointsPerSec = 0
        let _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timerEnemy) in
            self.playerMovePointsPerSec = 180.0
        }
    }
        enumerateChildNodes(withName: "finish") { node,  _ in
            let finish = node as! SKSpriteNode
            if finish.frame.insetBy(dx: 20, dy: 20).intersects(self.player.frame) {
                hitFinish.append(finish)
            }
        }
        for finish in hitFinish {
            if nodeArray.contains(finishZone) == false {
                finished()
                nodeArray.append(finishZone)
            }
        }

        enumerateChildNodes(withName: "randomPoint") { node, _ in
            let randomPoint = node as! SKSpriteNode
            if randomPoint.frame.insetBy(dx: 1000, dy: 1000).intersects(self.enemy.frame) {
                hitRandomPoint.append(randomPoint)
            }
        }
        for randomPoint in hitRandomPoint {
            randomMovement()
        }
    }

// moves the enemy to the players position as if they are being chased
    func detection() {
        enemyMoving = false
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
            enemyMoving = true
            if playerDead != true {
                playerDead = true
                death()
                playerMovePointsPerSec = 0
                let remove = SKAction.removeFromParent()
                randomPoint.run(remove)
                let _ = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { (timerEnemy) in
                    self.randomMovement()
                }
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
            let disappear = SKAction.scale(to: 0, duration: 0.5)
            let removeFromParent = SKAction.removeFromParent()
            let actions = [disappear, removeFromParent]
            player.run(SKAction.sequence(actions))
            let _ = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { (timerEnemy) in

                let reScale = SKAction.scale(to: 1, duration: 0.5)
                self.player.run(reScale)
                self.spawnPlayer()
                timerEnemy.invalidate()
        }
    }
    
    // sets a random point on the screen for the enemy to make their way to
    func randomMovement() {
        let remove = SKAction.removeFromParent()
        randomPoint.run(remove)
        
            let randomX =  Int(arc4random_uniform(UInt32(screenWidth! - 20)))
            let randomY = Int(arc4random_uniform(UInt32(screenHeight! - 20)))
          randomPosition = CGPoint(x: randomX + 10, y: randomY + 10)
        randomPoint.position = randomPosition!
            print("\(randomPoint.position) = random position")
            randomPoint.name = "Random Point"
            
            addChild(randomPoint)
        enemyMoving = true
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
                playerMoving = true
            }
        }
        if enemyMoving == true {
             moveEnemyToward(randomPoint.position)
            if let Location = randomPosition {
                let diff = Location - enemy.position
                if (diff.length() <= playerMovePointsPerSec * CGFloat(dt)) {
                    enemy.position = Location
                    velocityE = CGPoint.zero
                } else {
                    moveSpriteE(enemy, velocity: velocityE)
                    rotateSpriteE(enemy, direction: velocityE, rotateRadiansPerSec: playerRotateRadiansPerSec)
                }
            }
        }
        if enemy.position == randomPosition {
            enemyMoving = false
          randomMovement()
        }
      
        boundsCheckPlayer()
        boundsCheckEnemy()
        checkCollisions()
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
        shape.lineWidth = 1.0
        addChild(shape)
    }
}



