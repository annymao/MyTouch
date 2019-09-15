//
//  MotionActivityData.swift
//  MyTouch
//
//  Created by Anny on 2019/9/15.
//  Copyright © 2019 NTU HCI Lab. All rights reserved.
//

import Foundation
import CoreMotion

struct MotionActivityData: Codable {
    
    var timestamp: TimeInterval
    var activity: String
    
    init(motionActivity:CMMotionActivity) {
        if(motionActivity.walking){
            activity = "walking"
        }
        else if(motionActivity.running){
            activity = "running"
        }
        else if(motionActivity.stationary){
            activity = "stationary"
        }
        else if(motionActivity.cycling){
            activity = "cycling"
        }
        else if(motionActivity.automotive){
            activity = "automotive"
        }else{
            activity = "unknown"
        }
        let date = Date()
        self.timestamp = motionActivity.timestamp + date.timeIntervalSince1970 - ProcessInfo.processInfo.systemUptime
    }
} 
