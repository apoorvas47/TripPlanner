//
//  DateSquareViewController.swift
//  Trip Planner
//
//  Created by Admin on 12/15/19.
//  Copyright © 2019 Apoorva Shastri. All rights reserved.
//

import UIKit

class DateSquareViewController: UIViewController {
    
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var dayOfMonthLabel: UILabel!
    
    let date : Date?
    
    init(date: Date) {
        self.date = date
        
        super.init(nibName: "DateSquareViewController", bundle: nil)
        // rem: You MUST call the designated init above when creating a custom init,
        //      and also handle the required init that was addded below.
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        monthLabel.text = date!.getMonthString()
        dayOfMonthLabel.text = date!.getDayOfMonthString()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
