//
//  cityViewController.swift
//  MyFinal
//
//  Created by Brittany Mason on 2/29/20.
//  Copyright © 2020 Udacity. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

class CityViewController : UIViewController {
    
    //MARK: Set up Outlets
    @IBOutlet weak var cityPicture: CityViewController!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var getPhotoButton: UIButton!
    @IBOutlet weak var cityImage: UIImageView!
    @IBOutlet weak var nextPhotoButton: UIButton!
    @IBOutlet weak var loadingLabel: UILabel!
    
    
    //MARK: Setup Variables
    var nameOfSelectedCity = ""
    var lat = 0.0
    var log = 0.0
    var pics: Photos?
    var pictureStruct : [PhotoParser]?
    var pictureStructs: [NSManagedObject] = []
    var personvar: Person?
    var cityViewPerson : [Person]?
    var name = ""
    var imageUrl: String = ""
    var savedImageUrl = ""
    var randomURL = ""
    var activityIndicator:UIActivityIndicatorView = UIActivityIndicatorView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cityNameLabel.text = nameOfSelectedCity
        cityNameIntoCoord()
        getPhotosFromFlickr ()
        nextPhotoButton.isHidden = true
        loadingLabel.text = ""
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //May refactor this later
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Photos")
        
        do {
            pictureStructs = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    //this is the same as in view will appear
    private func setupFetchedResultControllerWith(_ city: Person) {
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Photos")
        
        do {
            pictureStructs = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    
    @IBAction func backButtonAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //MARK:Turn City name into coordinates
    
    func cityNameIntoCoord() {
        let address = nameOfSelectedCity
        //let address = "Burlington, Vermont"
        CLGeocoder().geocodeAddressString(address, completionHandler: { placemarks, error in
            if (error != nil) {
                return
            }
            
            if let placemark = placemarks?[0]  {
                let lon = String(format: "%.04f", (placemark.location?.coordinate.longitude ?? 0.0)!)
                let lat = String(format: "%.04f", (placemark.location?.coordinate.latitude ?? 0.0)!)
                let name = placemark.name!
                let country = placemark.country!
                let region = placemark.administrativeArea!
                print("\(lat),\(lon)\n\(name),\(region) \(country)")
                
                let corlat = (lat as NSString).doubleValue
                let corlong = (lon as NSString).doubleValue
                Constants.Coordinate.latitude = corlat
                Constants.Coordinate.longitude = corlong
                print("function lat",corlat)
                print( Constants.Coordinate.longitude)
            }
        })
    }
    
    @IBAction func getPhotoButtonPressed(_ sender: Any) {
        //        getPhotosFromFlickr ()
        let picURL = savedImageUrl
        cityPictureImageView (imageUrlString: picURL)
        nextPhotoButton.isHidden = false
        getPhotoButton.isHidden = true
    }
    
    func getPhotosFromFlickr () {
        self.nextPhotoButton.isHidden = true
        print("'New Collection' button pressed")
        activityIndicatorStart()
        
        helperTasks.downloadPhotos { (pictureInfo, error) in
            if let pictureInfo = pictureInfo {
                self.pictureStruct = pictureInfo.photos.photo
                self.storePhotos(self.pictureStruct!, Person: self.personvar!)
                
                DispatchQueue.main.async {
                    print("This is picture infor", pictureInfo)
                    self.activityIndicatorStop()
                    
                    guard let per = self.personvar else {
                        return
                    }
                    self.setupFetchedResultControllerWith(per)
                    print("Got the pics")
                }
            } else {
                DispatchQueue.main.async {
                    self.activityIndicatorStop()
                    self.displayAlert(title: "Error", message: "Unable to get city pictures.")
                }
                print(error as Any)
            }
        }
    }
    
    private func storePhotos(_ photos: [PhotoParser], Person: Person) {
        func showErrorMessage(msg: String) {
            showInfo(withTitle: "Error", withMessage: msg)
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        for photo in photos {
            DispatchQueue.main.async {
                
                if let url = photo.url {
                    
                    _ = Photos(title: photo.title, imageUrl: url, Person: Person, context: managedContext)
                    self.savedImageUrl = url
                    //                    self.save()
                    print("This is the URL for the saved pic", self.savedImageUrl)
                }
            }
        }
    }
    
    func save(name: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        let managedContext = appDelegate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Photos", in: managedContext)!
        let picurl = NSManagedObject(entity: entity, insertInto: managedContext)
        picurl.setValue(name, forKeyPath: "urlimage")
        print ("This pic is saved", picurl)
        
        do {
            try managedContext.save()
            pictureStructs.append(picurl)
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func cityPictureImageView (imageUrlString: String) {
        activityIndicatorStart()
        loadingLabel.text = "Loading!"
        let imageUrlString = imageUrlString
        guard let imageUrl:URL = URL(string: imageUrlString) else{
                   DispatchQueue.main.async {
                       self.displayAlert(title: "Error", message: "Invalid Image URL.")
                   }
                   return
               }
        // Start background thread so that image loading does not make app unresponsive
        DispatchQueue.global(qos: .userInitiated).async {
            
            let imageData:NSData = NSData(contentsOf: imageUrl)!
            
            // When from background thread, UI needs to be updated on main_queue
            DispatchQueue.main.async {
                self.loadingLabel.text = ""
                self.activityIndicatorStop()
                if(self.view.subviews.count > 0){
                    for iView in self.view.subviews {
                        if(iView as? UIImageView != nil){
                            iView.removeFromSuperview()
                        }
                    }
                }
                let imageView = UIImageView(frame: CGRect(x:0, y:0, width:300, height:300))
                imageView.center = self.view.center
                let image = UIImage(data: imageData as Data)
                imageView.image = image
                imageView.contentMode = UIView.ContentMode.scaleAspectFit
                self.view.addSubview(imageView)
            }
        }
    }
    
    
    func tester (){
        
        let randomName = pictureStruct?.randomElement()!
        let urlRan = randomName?.url
        randomURL = urlRan!
        print(urlRan as Any)
        save(name: urlRan!)
    }
    
    @IBAction func getNextPhotoInDictButton(_ sender: Any) {
        tester()
        let nextPhotoURL = randomURL
        cityPictureImageView(imageUrlString: nextPhotoURL)
        getPhotoButton.isHidden = true
    }
    
    func activityIndicatorStart () {
        print("act ind working")
        activityIndicator.center = self.view.center
        activityIndicator.hidesWhenStopped = true
        activityIndicator.style = UIActivityIndicatorView.Style.medium
        view.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    func activityIndicatorStop () {
        activityIndicator.stopAnimating()
    }
}

