//
//  DeviceMotionData.swift
//  MyTouch
//
//  Created by Anny on 2019/9/15.
//  Copyright © 2019 NTU HCI Lab. All rights reserved.
//

import Foundation
import CoreMotion

struct DeviceMotionData: Codable {
    
    var timestamp: TimeInterval
    var userAccX: Double
    var userAccY: Double
    var userAccZ: Double
    var rotateX: Double
    var rotateY: Double
    var rotateZ: Double
    
    init(timestamp: TimeInterval, rotate:CMRotationRate, userAcc:CMAcceleration) {
        let date = Date()
        self.timestamp = timestamp + date.timeIntervalSince1970 - ProcessInfo.processInfo.systemUptime
        self.userAccX = userAcc.x
        self.userAccY = userAcc.y
        self.userAccZ = userAcc.z
        self.rotateX = rotate.x
        self.rotateY = rotate.y 
        self.rotateZ = rotate.z
    }
}
