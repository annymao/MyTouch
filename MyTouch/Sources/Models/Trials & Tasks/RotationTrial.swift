//
//  RotationTrial.swift
//  MyTouch
//
//  Created by Tommy Lin on 2018/7/20.
//  Copyright © 2018年 NTU HCI Lab. All rights reserved.
//

import UIKit
import ResearchKit

class RotationTrial: Trial {
    
    var targetRotation: CGFloat = 0.0
    var resultRotation: CGFloat = 0.0
    
    override init(trial: ORKTouchAbilityTrial) {
        super.init(trial: trial)
        if let trial = trial as? ORKTouchAbilityRotationTrial {
            self.targetRotation = trial.targetRotation
            self.resultRotation = trial.resultRotation
        }
    }
    
    /*required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }*/
    enum StructKeysA: String, CodingKey {
        case targetRotation,resultRotation
    }
    override func encode(to encoder: Encoder) throws {
        
        var container =  encoder.container(keyedBy: StructKeysA.self)
        try container.encode(targetRotation, forKey: .targetRotation)
        try container.encode(resultRotation, forKey: .resultRotation)
        try super.encode(to: encoder)
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StructKeysA.self)
        self.targetRotation = try container.decode(CGFloat.self, forKey: .targetRotation)
        self.resultRotation = try container.decode(CGFloat.self, forKey: .resultRotation)
        try super.init(from: decoder)
    }
}
