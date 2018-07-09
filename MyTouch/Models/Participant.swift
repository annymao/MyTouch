//
//  Participant.swift
//  MyTouch
//
//  Created by Tommy Lin on 2018/7/9.
//  Copyright © 2018年 NTU HCI Lab. All rights reserved.
//

import Foundation

struct Participant {
    
    enum Gender: String {
        case female, male, other
    }

    enum DominantHand: String {
        case left, right, both, none
    }
    
    let id: Int
    var name: String
    var birthYear: Int
    var gender: Gender
    var dominantHand: DominantHand
    
    var note: String
}
