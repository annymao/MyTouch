//
//  ScrollTrial.swift
//  MyTouch
//
//  Created by Tommy Lin on 2018/7/19.
//  Copyright © 2018年 NTU HCI Lab. All rights reserved.
//

import UIKit

struct ScrollTrial: Trial {
    
    enum Axis: String, Codable {
        case horizontal, vertical
        case none
    }
    
    let axis: Axis
    
    let initialOffset: CGPoint
    
    let targetOffset: CGPoint
    
    var resultOffset: CGPoint = .zero
    
    var startTime: TimeInterval = Date.distantPast.timeIntervalSince1970
    
    var endTime: TimeInterval = Date.distantFuture.timeIntervalSince1970
    
    var rawTouchTracks: [RawTouchTrack] = []
    
    var success: Bool = false
    
    var tapEvents: [TapGestureRecognizerEvent] = []
    
    var panEvents: [PanGestureRecognizerEvent] = []
    
    var longPressEvents: [LongPressGestureRecognizerEvent] = []
    
    var swipeEvents: [SwipeGestureRecognizerEvent] = []
    
    var pinchEvents: [PinchGestureRecognizerEvent] = []
    
    var rotationEvents: [RotationGestureRecognizerEvent] = []
    
    init(axis: Axis, initialOffset: CGPoint, targetOffset: CGPoint) {
        self.axis = axis
        self.initialOffset = initialOffset
        self.targetOffset = targetOffset
    }
}
