//
//  ViewController.swift
//  Trip Planner
//
//  Created by Admin on 11/23/19.
//  Copyright © 2019 Apoorva Shastri. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import MapKit

protocol ViewControllerDelegate {
    func updatePlacesOnSched() // Used to tell the card view that it should update its schedule view of places.
}

class ViewController: UIViewController, GMSAutocompleteViewControllerDelegate, CLLocationManagerDelegate, MKMapViewDelegate, CardViewControllerDelegate {
    
    @IBOutlet weak var placeSearchTextField: UITextField!
    
    // Note: Ultimately chose to use Apple Map View instead of Google's Map API because the "marker"s (pins) on a
    //      Google Map cannot be interacted with!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchBarView: UIView!
    @IBOutlet weak var placeSearchButton: UIButton!
    
    let tripModel = TripModel.sharedInstance
    
    // Keep track of all pins in order to update necessary places when ordering is changed for a given date
    var placeIdToPinDict : [String : Pin] = [:]
    
    var locationManager : CLLocationManager = CLLocationManager()
    
    var placesClient = GMSPlacesClient()
    
    var haveDatesBeenAdded : Bool = false
    
    var delegate : ViewControllerDelegate?
    
    // Enum for card states
    enum CardState {
        case expanded
        case collapsed
    }
    
    // think: card view controller outlet
    var cardViewController:CardViewController!
    
    var selectedDate : Date = Date()
    
    var cardHeight:CGFloat = 0
    let cardHandleAreaHeight:CGFloat = 100 // TODO: Only the top 30 should be interactable but bottom 100 should be visible 
    
    // Current visible state of the card
    var cardVisible = false
    
    // Variable determines the next state of the card expressing that the card starts and collapased
    var nextState:CardState {
        return cardVisible ? .collapsed : .expanded
    }
    
    // Empty property animator array
    var runningAnimations = [UIViewPropertyAnimator]()
    var animationProgressWhenInterrupted:CGFloat = 0
    
    
    override func viewDidLoad() {
        // TODO: add as constant later, it is related to the height of the view of searchbar etc
        //      also make sure this doesnt
        cardHeight = self.view.frame.height - 100
        
        searchBarView.layer.cornerRadius = 6
        
        // Enable these once dates have been added!
        placeSearchTextField.isUserInteractionEnabled = false
        placeSearchButton.isEnabled = false
        
        super.viewDidLoad()
        
        setupCard()
        setupMapView()
        
        delegate = cardViewController
    }
    
    func setupMapView() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        mapView.delegate = self
    }
    
    @IBAction func searchButtonTapped(_ sender: Any) {
        launchPlaceSearch()
    }
    // Present the Autocomplete view controller when the textField is tapped.
    @IBAction func placeSearchTextFieldTap(_ sender: Any) {
        launchPlaceSearch()
    }
    
    func launchPlaceSearch() {
        placeSearchTextField.resignFirstResponder()
        let acController = GMSAutocompleteViewController()
        acController.delegate = self
        present(acController, animated: true, completion: nil)
    }
    
    // #MARK GMSAutocompleteViewControllerDelegate Protocol implementations:
    
    // Add pin onto map for newly searched place and add to it to list of places for trip.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        
        // Dismiss GMSAutoCompleteViewController
        dismiss(animated: true, completion: nil)
        
        // Load place info
        let tripPlace = Place(id: UUID().uuidString, name: place.name, latitude: place.coordinate.latitude, longitude: place.coordinate.longitude, orderNum: 0, date: nil, startHour: nil, startMinute: nil, endHour: nil, endMinute: nil, isOpen: nil)
        
        if !tripModel.isPlaceAlreadyInTrip(placeId: tripPlace.id) {
            // Load place photo
            let photoMetadata : GMSPlacePhotoMetadata? = place.photos?[0]
            if let photoMetadata = photoMetadata {
                self.placesClient.loadPlacePhoto(photoMetadata, callback: { (photo, error) -> Void in
                    if let photo = photo {
                        // If a photo was found add it
                        // note, might be an async call here, so this will update the place with image whenever it gets it!
                        self.tripModel.addPlaceToTrip(tripPlace, openHours: place.openingHours, photo: photo)
                    }
                })
            }
            
            // Store/Add place into model
            tripModel.addPlaceToTrip(tripPlace, openHours: place.openingHours, photo: nil)
            
            // Create and add pin to map from searched place
            let coord2D = CLLocationCoordinate2D(latitude: (place.coordinate.latitude), longitude: (place.coordinate.longitude))
            let pin = Pin(title: place.name!, coordinate: coord2D, place: tripPlace)
            mapView.addAnnotation(pin)
            
            // Store pin in controller
            placeIdToPinDict[tripPlace.id] = pin
        }
        
        
        // Have map zoom in to where pin is being added
        let coord2D = CLLocationCoordinate2D(latitude: (place.coordinate.latitude), longitude: (place.coordinate.longitude))
        let camera = MKMapCamera(lookingAtCenter: coord2D, fromDistance: 800, pitch: 0, heading: 0)
        mapView.setCamera(camera, animated: true)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error: ", error.localizedDescription)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        // Dismiss GMSAutocompleteViewController when the user cancelled the action
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: MapView Delegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let pinAnnotation = annotation as! Pin
        
        // TODO: change reuse identifier name?
        let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "customannotation")
        annotationView.image = pinAnnotation.image
        
        // Add tapping functionality to each pin (in order to enable the reordering)
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.pinTapped(_:)))
        annotationView.addGestureRecognizer(tap)
        
        annotationView.tag = -1
        
        annotationView.clipsToBounds = true // :( doesnt fix issue
        
        return annotationView
    }
    
    @objc func pinTapped(_ sender: UITapGestureRecognizer) {
        let annotationView = sender.view as! MKAnnotationView
        let annotation = annotationView.annotation as! Pin
        let prevPinOrderNum = annotation.pinOrderNum
        
        if (prevPinOrderNum == -1) {
            return
        }
        
        
        
        switch prevPinOrderNum {
        case ...0: // case for taken and notNumbered Pin being clicked and wanting to be added to place sequence
            
            // can't add any more than 5 places currently to a date, TODO: add more pins
            //      so only do below if you have room
            if (tripModel.numPlacesForDate(date: selectedDate) < maxNumOfPlacesForDate ) {
                // note: this annotation will be added back later if it is only being updated
                mapView.removeAnnotation(annotation)
                
                tripModel.addPlaceToDateToPlaceOrderDict(date: selectedDate, place: annotation.place)
                delegate?.updatePlacesOnSched()
                //updatePinOrderForDate(selectedDate)
            }
        case 1...: // removing a place from current place sequence for a date
            // note: this annotation will be added back later if it is only being updated
            mapView.removeAnnotation(annotation)
            
            tripModel.removePlaceFromDateToPlaceOrderDict(date: selectedDate, placeOrderNum: prevPinOrderNum)
            annotation.updatePinOrderNumWithDate(pinOrderNum: 0, date: nil) // need to call update to update image!
            placeIdToPinDict[annotation.place.id] = annotation
            // add the annotation back here because otherwise its just removed before and not added back and
            // the update called at the end only updates stuff thats in the date!!
            mapView.addAnnotation(annotation)
            delegate?.updatePlacesOnSched()
            //updatePinOrderForDate(selectedDate)
        default:
            // Don't do anything to annotation in default case
            annotation.date = nil
        }
        
        updatePinOrderForDate(selectedDate)
    }
    
    func updatePinOrderForDate(_ selectedDate: Date) {
        var currentPinOrderNum = 1
        // The following loop will iterate through the places in order for a date.
        for placeId in tripModel.getPlaceIdsForDate(selectedDate) {
            let annotation = placeIdToPinDict[placeId]!
            mapView.removeAnnotation(annotation)
            annotation.updatePinOrderNumWithDate(pinOrderNum: currentPinOrderNum, date: selectedDate)
            mapView.addAnnotation(annotation)
            currentPinOrderNum += 1
        }
        
        // update the pins that are assigned to other dates to be in taken color
        for date in tripModel.getAllDates() {
            if (date == selectedDate) {
                continue
            }
            for placeId in tripModel.getPlaceIdsForDate(date) {
                let annotation = placeIdToPinDict[placeId]!
                mapView.removeAnnotation(annotation)
                annotation.updatePinOrderNumWithDate(pinOrderNum: -1, date: date)
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    // #MARK All methods related to the card view controller:
    // CREDIT: To a combination of online resources used as reference for behavior, needs touching up tho
    
    func setupCard() {
        
        cardViewController = CardViewController(nibName:"CardViewController", bundle:nil)
        self.addChild(cardViewController)
        self.view.addSubview(cardViewController.view)
        
        cardViewController.delegate = self
        
        cardViewController.view.frame = CGRect(x: 0, y: self.view.frame.height - cardHandleAreaHeight, width: self.view.bounds.width, height: cardHeight)
        
        cardViewController.view.clipsToBounds = true
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleCardTap(recognzier:)))
        cardViewController.handleArea.addGestureRecognizer(tapGestureRecognizer)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ViewController.handleCardPan(recognizer:)))
        cardViewController.handleArea.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc
    func handleCardTap(recognzier:UITapGestureRecognizer) {
        switch recognzier.state {
        case .ended:
            animateTransitionIfNeeded(state: nextState, duration: animatorDurationConstant)
        default:
            break
        }
    }
    
    @objc
    func handleCardPan (recognizer:UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startInteractiveTransition(state: nextState, duration: animatorDurationConstant)
        case .changed:
            let translation = recognizer.translation(in: self.cardViewController.handleArea)
            var fractionComplete = translation.y / cardHeight
            fractionComplete = cardVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: fractionComplete)
        case .ended:
            continueInteractiveTransition()
        default:
            break
        }
        
    }
    
    func animateTransitionIfNeeded (state:CardState, duration:TimeInterval) {
        if runningAnimations.isEmpty {
            let pullUpAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHeight
                case .collapsed:
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHandleAreaHeight
                }
            }
            
            pullUpAnimator.addCompletion { _ in
                self.cardVisible = !self.cardVisible
                self.runningAnimations.removeAll()
            }
            
            pullUpAnimator.startAnimation()
            runningAnimations.append(pullUpAnimator)
            
        }
    }
    
    func startInteractiveTransition(state:CardState, duration:TimeInterval) {
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    func updateInteractiveTransition(fractionCompleted:CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    func continueInteractiveTransition (){
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }

    func updateSelectedDate(date: Date) {
        selectedDate = date
        updatePinOrderForDate(date)
        if (!haveDatesBeenAdded) { // only need to do this once!
            placeSearchTextField.text = "Add Places Here..."
            placeSearchTextField.isUserInteractionEnabled = true
            placeSearchButton.isEnabled = true
            haveDatesBeenAdded = true
        }
    }
    
}

