//
//  SwipeTrial.swift
//  MyTouch
//
//  Created by Tommy Lin on 2018/6/29.
//  Copyright © 2018年 NTU HCI Lab. All rights reserved.
//

import UIKit
import ResearchKit

class SwipeTrial: Trial {
    
    typealias Direction = SwipeGestureRecognizerEvent.Direction
    
    var targetDirection: Direction = []
    var resultDirection: Direction = []
    var success = false
    
    override init(trial: ORKTouchAbilityTrial) {
        super.init(trial: trial)
        if let trial = trial as? ORKTouchAbilitySwipeTrial {
            self.targetDirection = Direction.convert(from: trial.targetDirection)
            self.resultDirection = Direction.convert(from: trial.resultDirection)
            self.success = trial.success
        }
    }
    
    /*required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }*/
    enum StructKeysA: String, CodingKey {
        case targetDirection,resultDirection,success
    }
    override func encode(to encoder: Encoder) throws {
        
        var container =  encoder.container(keyedBy: StructKeysA.self)
        try container.encode(targetDirection, forKey: .targetDirection)
        try container.encode(resultDirection, forKey: .resultDirection)
        try container.encode(success, forKey: .success)
        try super.encode(to: encoder)
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StructKeysA.self)
        self.targetDirection = try container.decode(Direction.self, forKey: .targetDirection)
        if let dir = try container.decodeIfPresent(Direction.self, forKey: .resultDirection){
            self.resultDirection = dir
        }
        self.success = try container.decode(Bool.self, forKey: .success)
        try super.init(from: decoder)
    }
}
