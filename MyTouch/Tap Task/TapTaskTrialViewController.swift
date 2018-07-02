//
//  TapTaskTrialViewController.swift
//  MyTouch
//
//  Created by Tommy Lin on 2018/7/1.
//  Copyright © 2018年 NTU HCI Lab. All rights reserved.
//

import UIKit

class TapTaskTrialViewController: TaskTrialViewController {

    var trialsLeft = 3
    
    let tapTrialView = TapPracticeView()
        
    override func viewDidLoad() {
        super.viewDidLoad()

        cancelButton.setTitle("Cancel", for: .normal)
        
        self.trialView = tapTrialView
        tapTrialView.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.startTrial(countdown: 3)
    }
    
    override func actionButtonDidSelect() {
        super.actionButtonDidSelect()
        
        if trialsLeft == 0 {
            let endViewController = TapTaskEndViewController()
            navigationController?.pushViewController(endViewController, animated: false)
        } else {
            startTrial(countdown: 3.0)
        }
    }
    
    override func cancelButtonDidSelect() {
        super.cancelButtonDidSelect()

        let alertController = UIAlertController(title: "Are You Sure?", message: "All data will be discarded.", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Leave", style: .destructive) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Stay", style: .default, handler: nil)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        alertController.preferredAction = cancelAction
        
        present(alertController, animated: true, completion: nil)
    }
}

extension TapTaskTrialViewController: TouchTrackingViewDelegate {
    
    func touchTrackingViewDidEndTracking(_ touchTrackingView: TouchTrackingView) {
        trialsLeft -= 1
        endTrial()
        
        if trialsLeft > 0 {
            actionButton.setTitle("Next (\(trialsLeft) left)", for: .normal)
        } else {
            actionButton.setTitle("Next Task", for: .normal)
        }
    }
}
