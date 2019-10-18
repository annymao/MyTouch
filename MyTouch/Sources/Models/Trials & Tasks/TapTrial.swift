//
//  TapTrial.swift
//  MyTouch
//
//  Created by Tommy Lin on 2018/6/29.
//  Copyright © 2018年 NTU HCI Lab. All rights reserved.
//

import UIKit
import ResearchKit

class TapTrial: Trial {
    
    var targetFrame = CGRect.zero
    var success = false
    enum StructKeysA: String, CodingKey {
        case targetFrame,success
    }
    override init(trial: ORKTouchAbilityTrial) {
        //print("hehe",self.targetFrame)
        //self.targetFrame = CGRect.zero
        //self.success = false
        super.init(trial: trial)

        if let trial = trial as? ORKTouchAbilityTapTrial {
            self.targetFrame = trial.targetFrameInWindow
            self.success = trial.success
            //print(self.targetFrame)
        }
    }
    override func encode(to encoder: Encoder) throws {
        
        var container =  encoder.container(keyedBy: StructKeysA.self)
        try container.encode(targetFrame, forKey: .targetFrame)
        try container.encode(success, forKey: .success)
        try super.encode(to: encoder)
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StructKeysA.self)
        self.targetFrame = try container.decode(CGRect.self, forKey: .targetFrame)
        self.success = try container.decode(Bool.self, forKey: .success)
        try super.init(from: decoder)
    }
    
}
