//
//  RandomFunction.swift
//  FlappyBird
//
//  Created by Jakub  Vaněk on 18/03/2019.
//  Copyright © 2019 Jakub  Vaněk. All rights reserved.
//

import Foundation
import CoreGraphics

public extension CGFloat {
    
    public static func random() -> CGFloat{
        
        return CGFloat(Float(arc4random())/0xFFFFFFFF)
    }
    public static func random(min min : CGFloat, max max : CGFloat) -> CGFloat{
        return CGFloat.random()*(max-min) + min
    }
}
