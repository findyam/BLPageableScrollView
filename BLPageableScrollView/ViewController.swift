//
//  ViewController.swift
//  BLPageableScrollView
//
//  Created by fuyong on 15/9/11.
//  Copyright © 2015年 FindYAM. All rights reserved.
//

import UIKit

class ViewController: UIViewController, BLPageableScrollViewDataSource {

    @IBOutlet weak var pageableScrollView: BLPageableScrollView!
    
    let colors: Array = [UIColor.redColor(), UIColor.blueColor(), UIColor.grayColor()];
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pageableScrollView.dataSource = self;
        
        self.pageableScrollView.registerClass(UIView.self, forViewReuseIdentifer: "view")
        self.pageableScrollView.reloadData()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    // MARK: BLPageableScrollViewDataSource methods
    
    func pageableScrollView(pageableScrollView: BLPageableScrollView, didSelectAtIndex index: Int) {
        
    }
    
    func pageableScrollView(pageableScrollView: BLPageableScrollView, viewAtIndex index: Int) -> UIView {
        let view: UIView = pageableScrollView.dequeueReusableViewWithIdentifier("view")!
        view.backgroundColor = self.colors[index]
        return view
    }
    
    func numberOfPagesInPageableScrollView(pageableScrollView: BLPageableScrollView) -> Int {
        return 3
    }    
}

