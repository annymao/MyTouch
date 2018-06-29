//
//  DragAndDropTrial.swift
//  MyTouch
//
//  Created by Tommy Lin on 2018/6/29.
//  Copyright © 2018年 NTU HCI Lab. All rights reserved.
//

import UIKit

struct DragAndDropTrial: Trial {
    
    let initialFrame: CGRect
    
    let targetFrame: CGRect
    
    var resultFrame: CGRect = .zero
    
    var startTime: TimeInterval = Date.distantPast.timeIntervalSince1970
    
    var endTime: TimeInterval = Date.distantFuture.timeIntervalSince1970
    
    var rawTouches: [RawTouch] = []
    
    var success: Bool = false
    
    init(initialFrame: CGRect, targetFrame: CGRect) {
        self.initialFrame = initialFrame
        self.targetFrame = targetFrame
    }
}
