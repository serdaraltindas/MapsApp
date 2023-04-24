import UIKit
import MapKit
import CoreLocation
import CoreData

class MapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapKit: MKMapView!
    @IBOutlet weak var secilenYerTextField: UITextField!
    @IBOutlet weak var secilenYerNotTextField: UITextField!
    @IBOutlet weak var kaydetButton: UIButton!
    
    //Güncel Konumu almak için kullanıyoruz.
    var locationManager = CLLocationManager()
    var secilenLatitude = Double()
    var secilenLongitude = Double()
    toMapsVC
    var secilenIsim = ""
    var secilenId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapKit.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        kaydetButton.isUserInteractionEnabled = false
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(konumSec(gestureRecognizer: )))
        gestureRecognizer.minimumPressDuration = 2
        mapKit.addGestureRecognizer(gestureRecognizer)
        
        if secilenIsim != "" {
            //CoreData
            if let uuidString = secilenId?.uuidString {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    let sonuclar = try context.fetch(fetchRequest)
                    if sonuclar.count > 0 {
                        for sonuc in sonuclar as! [NSManagedObject] {
                            if let isim = sonuc.value(forKey: "isim") as? String {
                                annotationTitle = isim
                                if let not = sonuc.value(forKey: "not") as? String {
                                    annotationSubtitle = not
                                    if let latitude = sonuc.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        if let longitude = sonuc.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubtitle
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
                                            
                                            mapKit.addAnnotation(annotation)
                                            secilenYerTextField.text = annotationTitle
                                            secilenYerNotTextField.text = annotationSubtitle
                                            
                                            locationManager.stopUpdatingLocation()
                                            
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05 , longitudeDelta: 0.05)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapKit.setRegion(region, animated: true)
                                            
                                        }
                                    }
                                }
                            }
                        }
                    }
                }catch{
                    print("Hata!")
                }
            }
        }else{
            //NewData
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "benimAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .white
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        }else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if secilenIsim != "" {
         
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarkDizisi , error) in
                    
                if let placemarks = placemarkDizisi {
                    if placemarks.count > 0 {
                        let yeniPlacemark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: yeniPlacemark)
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }
    }
    
    @objc func konumSec(gestureRecognizer : UILongPressGestureRecognizer) {
        
        kaydetButton.isUserInteractionEnabled = true
        
        if gestureRecognizer.state == .began {
            let dokunulanNokta = gestureRecognizer.location(in: mapKit)
            let dokunulanKoordinat = mapKit.convert(dokunulanNokta, toCoordinateFrom: mapKit)
            
            secilenLatitude = dokunulanKoordinat.latitude
            secilenLongitude = dokunulanKoordinat.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = dokunulanKoordinat
            annotation.title = secilenYerTextField.text
            annotation.subtitle = secilenYerNotTextField.text
            mapKit.addAnnotation(annotation)
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if secilenIsim == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05 , longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location , span: span)
            mapKit.setRegion(region, animated: true)
        }
    }
    @IBAction func kaydetButtonTiklandi(_ sender: UIButton) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let yeniYer = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: context)
        yeniYer.setValue(secilenYerTextField.text, forKey: "isim")
        yeniYer.setValue(secilenYerNotTextField.text, forKey: "not")
        yeniYer.setValue(secilenLatitude, forKey: "latitude")
        yeniYer.setValue(secilenLongitude, forKey: "longitude")
        yeniYer.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("OK")
        } catch {
            print("Error!")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "yeniYerOlusturuldu"), object: nil)
        navigationController?.popViewController(animated: true)
        
    }
}

