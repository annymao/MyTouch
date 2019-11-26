//
//  AdditionalPageViewController.swift
//  MyTouch
//
//  Created by Syenny on 2019/11/26.
//  Copyright © 2019 NTU HCI Lab. All rights reserved.
//

import UIKit

@objc public class AdditionalPageViewController: UIViewController {

    let numberArray = ["1", "2", "3", "4", "5"]
    private var label: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.green
        label.font = UIFont(name: "Arial", size: 18)
        return label
    }()

    private var button: UIButton = {
        let button = UIButton()
        let label = UILabel()
        button.setTitle("Tap Here", for: .normal)
        return button
    }()

    override public func viewDidLoad() {
        super.viewDidLoad()

        button.addTarget(self, action: #selector(tappedButton(sender:)), for: .touchUpInside)

        // Do any additional setup after loading the view.

    }
    @objc private func tappedButton(sender: UIButton) {
        for number in numberArray {
            label.text = number
        }
    }
}
