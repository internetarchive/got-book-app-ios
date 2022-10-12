//
//  NavViewController.swift
//  GotBook
//
//  Created by Internet Archive on 9/30/22.
//

import UIKit

class NavViewController: UINavigationController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    // return topViewController?.preferredStatusBarStyle ?? .default
    return .lightContent
  }

}

