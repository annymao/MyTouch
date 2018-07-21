//
//  PinchTaskPracticeViewController.swift
//  MyTouch
//
//  Created by Tommy Lin on 2018/7/20.
//  Copyright © 2018年 NTU HCI Lab. All rights reserved.
//

import UIKit

class PinchTaskPracticeViewController: TaskTrialViewController {
    
    let pinchTrialView = PinchTrialView()
    
    var shouldStartTrial = false
    
    override func nextViewController() -> TaskViewController {
        return PinchTaskTrialViewController()
    }
    
    override var countdownColor: UIColor {
        return .white
    }
    
    override var shouldStartTrialAutomaticallyOnPrimaryButtonTapped: Bool {
        return false
    }
    
    override func loadView() {
        super.loadView()
        self.trialView = pinchTrialView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pinchTrialView.touchTrackingDelegate = self
        pinchTrialView.dataSource = self
        
        primaryButton.setTitle("Practice", for: .normal)
        secondaryButton.setTitle("Skip", for: .normal)
        
        secondaryButton.isHidden = false
    }
    
    override func didEndTrial() {
        super.didEndTrial()

        pinchTrialView.reloadData()
        
        shouldStartTrial = true
        
        UIView.performWithoutAnimation {
            self.primaryButton.setTitle("End Practice", for: .normal)
            self.secondaryButton.setTitle("Try Again", for: .normal)
        }
    }
    
    override func primaryButtonDidSelect() {
        super.primaryButtonDidSelect()
        
        if shouldStartTrial {
            presentStartTrialAlert()
        } else {
            startTrial()
        }
    }
    
    override func secondaryButtonDidSelect() {
        super.secondaryButtonDidSelect()
        
        if shouldStartTrial {
            startTrial()
        } else {
            presentStartTrialAlert()
        }
    }
    
    private func presentStartTrialAlert() {
        
        let alertController = UIAlertController(title: "Start Trial", message: "Are you sure?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        let confirmAction = UIAlertAction(title: "Go", style: .default) { (action) in
            self.presentNextViewController()
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        alertController.preferredAction = confirmAction
        
        present(alertController, animated: true, completion: nil)
    }
}

extension PinchTaskPracticeViewController: PinchTrialViewDataSource {
    
    func targetScale(_ pinchTrialView: PinchTrialView) -> CGFloat {
        let scales: [CGFloat] = [1/2, 2/3, 3/2, 2]
        return scales.shuffled().first!
    }
}
