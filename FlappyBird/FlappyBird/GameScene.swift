//
//  GameScene.swift
//  FlappyBird
//
//  Created by Jakub  Vaněk on 18/03/2019.
//  Copyright © 2019 Jakub  Vaněk. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation

let kBestScore = "kBestScore"

struct PhysicsCategory {
    static let Ghost : UInt32 = 0x1 << 1
    static let Ground : UInt32 = 0x1 << 2
    static let Wall : UInt32 = 0x1 << 3
    static let Score : UInt32 = 0x1 << 4
}


class GameScene: SKScene, SKPhysicsContactDelegate{
    
    var flyAudioPlayer:AVAudioPlayer!
    var pointAudioPlayer:AVAudioPlayer!
    var dieAudioPlayer:AVAudioPlayer!
    
    var Ground = SKSpriteNode()
    var Ghost = SKSpriteNode()
    var wallPair = SKNode()
    
    var gameStarted = Bool()
    
    var score = Int()
    var bestScore = Int()
    
    var moveAndRemove = SKAction()
    
    let scoreLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
    let bestScoreLbl = SKLabelNode(fontNamed: "AvenirNext-Bold")
    
    var died = Bool()
    var restartBtn = SKSpriteNode()
    
    func restartScene(){
    
        self.removeAllChildren()
        self.removeAllActions()
        died = false
        gameStarted = false
        score = 0
        bestScore = getBestScore()
        createScene()
    }
    
    func createScene(){
        
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -15)
        self.backgroundColor = UIColor(red:0.00, green:1.00, blue:1.00, alpha:1.0)
        
        
        scoreLbl.position = CGPoint(x: 0, y: self.frame.height/3)
        scoreLbl.fontSize = 80
        scoreLbl.zPosition = 5
        scoreLbl.text = "\(score)"
        self.addChild(scoreLbl)
        
        
        bestScoreLbl.fontSize = 80
        bestScoreLbl.position = CGPoint(x: 0, y: self.frame.height/3 + bestScoreLbl.fontSize)
        bestScoreLbl.zPosition = 5
        bestScoreLbl.text = "HighScore: \(getBestScore())"
        self.addChild(bestScoreLbl)
        
        Ground = SKSpriteNode(imageNamed: "Ground")
        Ground.setScale(self.frame.width/Ground.size.width)
        Ground.position = CGPoint(x: 0, y: 0 - self.frame.height/2 + Ground.size.height/2)
        Ground.physicsBody = SKPhysicsBody(rectangleOf: Ground.size)
        Ground.physicsBody?.categoryBitMask = PhysicsCategory.Ground
        Ground.physicsBody?.collisionBitMask = PhysicsCategory.Ghost
        Ground.physicsBody?.contactTestBitMask = PhysicsCategory.Ghost
        Ground.physicsBody?.affectedByGravity = false
        Ground.physicsBody?.isDynamic = false
        Ground.zPosition = 3
        
        self.addChild(Ground)
        
        Ghost = SKSpriteNode(imageNamed: "Ghost")
        Ghost.size = CGSize(width: self.frame.width * 0.15, height: self.frame.height * 0.1);
        Ghost.position = CGPoint(x: -Ghost.frame.width, y: 0)
        Ghost.physicsBody = SKPhysicsBody(circleOfRadius: Ghost.frame.height/2)
        Ghost.physicsBody?.categoryBitMask = PhysicsCategory.Ghost
        Ghost.physicsBody?.collisionBitMask = PhysicsCategory.Ground | PhysicsCategory.Wall
        Ghost.physicsBody?.contactTestBitMask = PhysicsCategory.Ground | PhysicsCategory.Wall | PhysicsCategory.Score
        Ghost.physicsBody?.affectedByGravity = false
        Ghost.physicsBody?.isDynamic = true
        Ghost.zPosition = 2
        
        self.addChild(Ghost)
        
        
    }
    
    override func didMove(to view: SKView) {
        //setup your scene here
        createScene()
    }
    
    func createBtn(){
        
        restartBtn = SKSpriteNode(imageNamed: "restart")
        restartBtn.position = CGPoint(x: 0, y: 0)
        restartBtn.zPosition = 6
        restartBtn.setScale(0)
        self.addChild(restartBtn)
        
        restartBtn.run(SKAction.scale(to: 2.0, duration: 0.5))
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB
        
        if firstBody.categoryBitMask == PhysicsCategory.Score && secondBody.categoryBitMask == PhysicsCategory.Ghost || firstBody.categoryBitMask == PhysicsCategory.Ghost && secondBody.categoryBitMask == PhysicsCategory.Score{
            
            score += 1
            playPointSound()
            scoreLbl.text = "\(score)"
        }
        
        if firstBody.categoryBitMask == PhysicsCategory.Ghost && secondBody.categoryBitMask == PhysicsCategory.Wall || firstBody.categoryBitMask == PhysicsCategory.Wall && secondBody.categoryBitMask == PhysicsCategory.Ghost{
            
            
            
            
            enumerateChildNodes(withName: "wallPair", using: ({
                (node, error) in
                
                node.speed = 0
                self.removeAllActions()
            }))
            if died == false {
                playDieSound()
                died = true
                createBtn()
            }
        }
        if firstBody.categoryBitMask == PhysicsCategory.Ghost && secondBody.categoryBitMask == PhysicsCategory.Ground || firstBody.categoryBitMask == PhysicsCategory.Ground && secondBody.categoryBitMask == PhysicsCategory.Ghost{
            
            
            
            
            enumerateChildNodes(withName: "wallPair", using: ({
                (node, error) in
                
                node.speed = 0
                self.removeAllActions()
            }))
            if died == false {
                died = true
                createBtn()
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameStarted == false {
            
            gameStarted = true
            Ghost.physicsBody?.affectedByGravity = true
            
            let spawn = SKAction.run({
                () in
                
                self.createWalls()
            })
            
            let delay = SKAction.wait(forDuration: 1)
            let SpawnDelay = SKAction.sequence([spawn, delay])
            let spawnDelayForever = SKAction.repeatForever (SpawnDelay)
            self.run(spawnDelayForever)
            
            let distance = CGFloat(2*self.frame.width + 2*wallPair.frame.width)
            let movePipes = SKAction.moveBy(x: -distance, y: 0.0, duration: TimeInterval(4))
            let removePipes = SKAction.removeFromParent()
            moveAndRemove = SKAction.sequence([movePipes, removePipes])
            
            Ghost.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
            Ghost.physicsBody?.applyImpulse(CGVector(dx: 0, dy: Ghost.size.height*3))
        }
        else {
            if(died == true){
                
            }
            else {
                Ghost.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                Ghost.physicsBody?.applyImpulse(CGVector(dx: 0, dy: Ghost.size.height*3))
            }
        }
        
        for touch in touches{
            let location = touch.location(in: self)
            playFlySound()
            if died == true{
                if(score > getBestScore()){
                    setBestScore(score)
                }
                if restartBtn.contains(location){
                    restartScene()
                }
            }
        }
        
    }
   
    func createWalls(){
        let scoreNode = SKSpriteNode()
        
        scoreNode.size = CGSize(width: 1, height: self.frame.height)
        scoreNode.position = CGPoint(x: self.frame.width, y: 0)
        scoreNode.physicsBody = SKPhysicsBody(rectangleOf: scoreNode.size)
        scoreNode.physicsBody?.affectedByGravity = false;
        scoreNode.physicsBody?.isDynamic = false;
        scoreNode.physicsBody?.categoryBitMask = PhysicsCategory.Score
        scoreNode.physicsBody?.collisionBitMask = 0
        scoreNode.physicsBody?.contactTestBitMask = PhysicsCategory.Ghost
        
        
        wallPair = SKNode()
        wallPair.name = "wallPair"
        
        let topWall = SKSpriteNode(imageNamed: "Wall")
        let btmWall = SKSpriteNode(imageNamed: "Wall")
        
        topWall.setScale(self.frame.height/topWall.size.height * 0.8)
        btmWall.setScale(self.frame.height/btmWall.size.height * 0.8)
        
        topWall.position = CGPoint(x: self.frame.width, y: self.frame.height/1.85);
        topWall.zRotation = CGFloat(Double.pi)
        
        topWall.physicsBody = SKPhysicsBody(rectangleOf: topWall.size)
        topWall.physicsBody?.categoryBitMask = PhysicsCategory.Wall
        topWall.physicsBody?.collisionBitMask = PhysicsCategory.Ghost
        topWall.physicsBody?.contactTestBitMask = PhysicsCategory.Ghost
        topWall.physicsBody?.isDynamic = false
        topWall.physicsBody?.affectedByGravity = false
        
        btmWall.position = CGPoint(x: self.frame.width, y: -self.frame.height/1.85);
        
        btmWall.physicsBody = SKPhysicsBody(rectangleOf: topWall.size)
        btmWall.physicsBody?.categoryBitMask = PhysicsCategory.Wall
        btmWall.physicsBody?.collisionBitMask = PhysicsCategory.Ghost
        btmWall.physicsBody?.contactTestBitMask = PhysicsCategory.Ghost
        btmWall.physicsBody?.isDynamic = false
        btmWall.physicsBody?.affectedByGravity = false
        
        wallPair.addChild(topWall)
        wallPair.addChild(btmWall)
        
        wallPair.zPosition = 1
        
        let randomPosition = CGFloat.random(min: -200, max: 200)
        wallPair.position.y = wallPair.position.y + randomPosition
        
        wallPair.addChild(scoreNode)
        
        wallPair.run(moveAndRemove)
        
        self.addChild(wallPair)
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    func setBestScore(_ value: Int){
        UserDefaults.standard.set(value, forKey: kBestScore)
        UserDefaults.standard.synchronize()
    }
    func getBestScore() -> Int{
        return UserDefaults.standard.integer(forKey: kBestScore)
    }
    func playFlySound(){
        let audioFilePath = Bundle.main.path(forResource: "Everything/sfx_wing", ofType: "wav")
        
        do {
            let audioFileUrl = NSURL.fileURL(withPath: audioFilePath!)

            flyAudioPlayer = try AVAudioPlayer(contentsOf: audioFileUrl, fileTypeHint: nil)
            flyAudioPlayer.play()
        }
        catch {
            print("Audio file is not found")
        }
    }
    func playPointSound(){
        let audioFilePath = Bundle.main.path(forResource: "Everything/sfx_point", ofType: "wav")
        
        do {
            let audioFileUrl = NSURL.fileURL(withPath: audioFilePath!)
            
            pointAudioPlayer = try AVAudioPlayer(contentsOf: audioFileUrl, fileTypeHint: nil)
            pointAudioPlayer.play()
        }
        catch {
            print("Audio file is not found")
        }
    }
    func playDieSound(){
        let audioFilePath = Bundle.main.path(forResource: "Everything/sfx_die", ofType: "wav")
        
        do {
            let audioFileUrl = NSURL.fileURL(withPath: audioFilePath!)
            
            dieAudioPlayer = try AVAudioPlayer(contentsOf: audioFileUrl, fileTypeHint: nil)
            dieAudioPlayer.play()
        }
        catch {
            print("Audio file is not found")
        }
    }
}


