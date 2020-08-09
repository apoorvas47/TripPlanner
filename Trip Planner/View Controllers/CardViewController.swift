//
//  CardViewController.swift
//  CardViewAnimation
//
//  Created by Brian Advent on 26.10.18.
//  Copyright © 2018 Brian Advent. All rights reserved.
//

import UIKit

protocol CardViewControllerDelegate {
    func updateSelectedDate(date: Date)
}

class CardViewController: UIViewController, ViewControllerDelegate {

    let tripModel = TripModel.sharedInstance
    
    @IBOutlet weak var handleArea: UIView!
    @IBOutlet weak var dragline: UIView!
    @IBOutlet weak var scheduleScrollView: UIScrollView!
    @IBOutlet weak var dateSquaresScrollView: UIScrollView!
    @IBOutlet weak var plusDateButton: UIButton!
    
    var scheduleTimeImageViewWidth : CGFloat = 0 // will be updated later.
    var delegate : CardViewControllerDelegate?
    var datePicker:UIDatePicker = UIDatePicker()
    var allDateSquaresDict = [UIView : Date]()
    var visiblePlacesOnSchedDict = [String: UIView]() // key will be placeid
    var setUpComplete: Bool = false
    var selectedDate: Date?
    
    override func viewDidLoad() {
        dragline.layer.cornerRadius = PaddingConstants.extraSmall
        self.view.layer.cornerRadius = PaddingConstants.mediumPlus
        plusDateButton.layer.cornerRadius = PaddingConstants.large
    }
    
    override func viewDidLayoutSubviews() {
        if (!setUpComplete) {
            setUpSchedule()
            setUpDateSquares()
            setUpComplete = true
        }
    }
    
    func setUpSchedule() {
        // Add the schedule times image to left side
        let scheduleTimeImageView = UIImageView(image: UIImage(named: "scheduleTimes"))
        scheduleTimeImageView.frame = CGRect(x: PaddingConstants.small, y: 0, width: scheduleTimeImageView.bounds.width, height: scheduleTimeImageView.bounds.height)
        scheduleScrollView.addSubview(scheduleTimeImageView)
        
        scheduleTimeImageViewWidth = scheduleTimeImageView.bounds.width
        
        // Make the scrollview scrollable length fit to the size of schedule times image
        let pageWidth = super.view.bounds.width // This is the visible portion width
        scheduleScrollView.contentSize = CGSize(width: pageWidth, height: scheduleTimeImageView.bounds.height)
        
        scheduleScrollView.isUserInteractionEnabled = true
        scheduleScrollView.pinchGestureRecognizer?.isEnabled = false // disable zoom
    }
    
    // # MARK delegate
    func updatePlacesOnSched() {
        // First clear the old places from the sched view
        for placeView in visiblePlacesOnSchedDict.values {
            placeView.removeFromSuperview()
        }
        
        // Replace visible Places on sched dict
        var newVisiblePlacesDict = [String: UIView]()
        
        let places = tripModel.getPlacesForDate(selectedDate!)
        var spaceIncrements = 0
        for place in places {
            let placeInfoVC = PlaceInfoViewController(place: place)
            scheduleScrollView.addSubview(placeInfoVC.view)
            let xposition = scheduleTimeImageViewWidth + PaddingConstants.small
            let yposition = CGFloat(Int(PaddingConstants.medium) + spaceIncrements*(Int(PixelLengths.thirtyMinutes)+Int(PaddingConstants.small)))
            let width = self.view.bounds.width - xposition - PaddingConstants.medium
            placeInfoVC.view.frame = CGRect(x: xposition, y: yposition, width: width, height: PixelLengths.thirtyMinutes)
            placeInfoVC.view.clipsToBounds = true
            // Note: 55 pixels can be used to be 30 minutes long in height!!!
            
            newVisiblePlacesDict[place.id] = placeInfoVC.view
            spaceIncrements += 1
        }
        
        visiblePlacesOnSchedDict = newVisiblePlacesDict
    }
    
    func setUpDateSquares() {
        //Make the scrollview scrollable length fit to the size of schedule times image
        dateSquaresScrollView.contentSize = CGSize(width: 50, height: 50)
        dateSquaresScrollView.isUserInteractionEnabled = true
        dateSquaresScrollView.pinchGestureRecognizer?.isEnabled = false // disable zoom
    }
    
    // Presents a date selector via alert view controller
    @IBAction func addDate(_ sender: Any) {
        // Create the alert controller.
        let alert = UIAlertController(title: nil, message: "Select Date Below:", preferredStyle: .alert)
        
        // Add the text field in order to have the date picker
        alert.addTextField { (textField) in
            // Date Picker set up.
            self.datePicker = UIDatePicker(frame:CGRect(x: 0, y: self.view.frame.size.height - 220, width:self.view.frame.size.width, height: 216))
            self.datePicker.backgroundColor = UIColor.white
            self.datePicker.datePickerMode = .date
            
            textField.inputView = self.datePicker
            // TODO: figure out why this text field won't disappear and why making it hidden
            //      managed to at least make it not editable.
            textField.isHidden = true
        }

        // Grab the value from the date picker from user presses Done!
        //      TODO: get it to display in textfield before quitting.
        alert.addAction(UIAlertAction(title: "Done", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            // print((textField?.inputView as! UIDatePicker).date.getDayOfMonthString())
            self.addDateSquare(date: (textField?.inputView as! UIDatePicker).date)
        }))

        // Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    // Will add a date square to the scroll and make it interactale as well.
    func addDateSquare(date: Date) {
        // create date square
        let dateSquareVC = DateSquareViewController(date: date)
        dateSquaresScrollView.addSubview(dateSquareVC.view)
        dateSquareVC.view.layer.cornerRadius = PaddingConstants.small
        dateSquareVC.view.clipsToBounds = true
        
        // set frame of date square
        let numDateSquaresAlready = allDateSquaresDict.count
        if numDateSquaresAlready == 0 {
            // Adding first one
            dateSquareVC.view.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        } else {
            dateSquareVC.view.frame = CGRect(x: (50 + 15)*numDateSquaresAlready, y:0, width: 50, height: 50)
        }
        
        // Adjust content size of dates scrollview
        dateSquaresScrollView.contentSize = CGSize(width: (50 + 15)*(numDateSquaresAlready+1) - 15, height: 50)
        
        // Store into all squares dict in this view controller
        allDateSquaresDict[dateSquareVC.view] = date
        
        // make added square the selected one and let parent know that you did that via delegate!
        selectDateSquare(dateSquareVC.view)
        delegate?.updateSelectedDate(date: date)
        selectedDate = date // let yourself know here too what the selected date is!
        updatePlacesOnSched()
        
        // add tap gesture recognizer
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.dateSquareTapped(_:)))
        dateSquareVC.view.addGestureRecognizer(tap)
    }
    
    @objc func dateSquareTapped(_ sender: UITapGestureRecognizer) {
        let dateSquareView = sender.view!
        
        // Get the date for the view that was tapped.
        let date = allDateSquaresDict[dateSquareView]
        
        // Let the parent view controller know that this is the selected date now!
        delegate?.updateSelectedDate(date: date!)
        selectedDate = date! // let yourself know here too what the selected date is!
        updatePlacesOnSched()
        
        selectDateSquare(dateSquareView)
    }
    
    func selectDateSquare(_ dateSquareView: UIView) {
        // go through all squares in this view controller and then make background light gray.
        // except for this selected one, make its background black
        for view in allDateSquaresDict.keys {
            if (view == dateSquareView) {
                view.backgroundColor = .black
            } else {
                view.backgroundColor = .lightGray
            }
        }
    }
}
