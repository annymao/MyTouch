//
//  AccelerometerData.swift
//  MyTouch
//
//  Created by Anny on 2019/9/15.
//  Copyright © 2019 NTU HCI Lab. All rights reserved.
//

import Foundation
struct AccelerometerData: Codable {
    
    var timestamp: TimeInterval
    var x: Double
    var y: Double
    var z: Double
    
    init(timestamp: TimeInterval, x: Double,y: Double,z: Double) {
        let date = Date()
        self.timestamp = timestamp + date.timeIntervalSince1970 - ProcessInfo.processInfo.systemUptime
        self.x = x
        self.y = y 
        self.z = z
    }
}
