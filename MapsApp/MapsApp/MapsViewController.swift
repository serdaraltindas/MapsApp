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
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.05 , longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location , span: span)
        mapKit.setRegion(region, animated: true)
        
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
    }
}

