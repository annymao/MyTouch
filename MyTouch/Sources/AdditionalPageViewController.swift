//
//  AdditionalPageViewController.swift
//  MyTouch
//
//  Created by Syenny on 2019/11/26.
//  Copyright © 2019 NTU HCI Lab. All rights reserved.
//

import UIKit

public class AdditionalPageViewController: UIViewController {
    private var titles: UILabel = {
        let title = UILabel()
        title.text = NSLocalizedString("PLEASE_WAIT_5_SECONDS", comment: "")
        title.textAlignment = .center
        title.font = UIFont.systemFont(ofSize: 22)
        title.textColor = .white
        return title
    }()

    private var label: UILabel = {
        let label = UILabel()
        label.text = "5"
        label.font = UIFont.systemFont(ofSize: 300)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()

    private var startButton: UIButton = {
        let startButton = UIButton()
        let attribute = NSAttributedString(string: "Start", attributes: [NSAttributedString.Key.foregroundColor:UIColor.white,
                                                                         NSAttributedString.Key.font: UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .medium)])
        startButton.setAttributedTitle(attribute, for: .normal)
        return startButton
    }()

    private var seconds = 5
    private var timer = Timer()

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor(red: 0, green: 0.72, blue: 0.58, alpha: 1)
        setupView()
        label.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3.0) {
            self.label.isHidden = false
            self.runTimer()
        }
    }

    private func setupView() {
        titles.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titles)
        view.addSubview(label)

        titles.topAnchor.constraint(equalTo: view.topAnchor, constant: 60).isActive = true
        titles.heightAnchor.constraint(equalToConstant: 48).isActive = true
        titles.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        titles.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true

        label.topAnchor.constraint(equalTo: titles.bottomAnchor, constant: 10).isActive = true
        label.heightAnchor.constraint(equalToConstant: 500).isActive = true
        label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
    }

    private func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 0.9, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }

    @objc private func updateTimer() {
        if seconds > 0 {
            seconds -= 1
        }

        label.text = "\(seconds)"
    }
}
