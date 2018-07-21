//
//  TapTaskInstructionViewController.swift
//  MyTouch
//
//  Created by Tommy Lin on 2018/7/6.
//  Copyright © 2018年 NTU HCI Lab. All rights reserved.
//

import UIKit

class TapTaskInstructionViewController: TaskInstructionViewController {

    let instructionView = TapInstructionView()
    
    override func nextViewController() -> TaskViewController? {
        return TapTaskPracticeViewController()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView.addSubview(instructionView)
        instructionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            instructionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            instructionView.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            instructionView.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            instructionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        instructionView.startAnimating()
    }
}
