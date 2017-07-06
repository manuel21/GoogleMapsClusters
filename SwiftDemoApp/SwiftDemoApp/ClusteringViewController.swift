/* Copyright (c) 2016 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import GoogleMaps
import UIKit


/// Point of Interest Item which implements the GMUClusterItem protocol.
class POIItem: NSObject, GMUClusterItem
{
    var position: CLLocationCoordinate2D
    var name: String!
    
    init(position: CLLocationCoordinate2D, name: String)
    {
        self.position = position
        self.name = name
    }
}

let kClusterItemCount = 10000
let kCameraLatitude = 36.2077343
let kCameraLongitude = -113.7407914
let kZoom: Float = 4 // min 1 |- - - - - - - -| 10 max


class ClusteringViewController: UIViewController
{
    fileprivate var mapView: GMSMapView!
    fileprivate var clusterManager: GMUClusterManager!
    
    override func loadView()
    {
        let camera = GMSCameraPosition.camera(withLatitude: kCameraLatitude, longitude: kCameraLongitude, zoom: kZoom)
        self.mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        
        //Theme Style
        do {
            // Set the map style by passing a valid JSON string.
            let path = Bundle.main.path(forResource: "map_black_style", ofType: "json")
            let url = URL(fileURLWithPath: path!)
            self.mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: url)
        }
        catch
        {
            print("One or more of the map styles failed to load. \(error)")
        }
        
        //Adding to View
        self.view = self.mapView
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //Group buckets : how many levels do you want? (must be increasing order)
        let numbers: [NSNumber] = [10, 25, 50, 100, 500, 1000]
        let images = [UIImage(named: "cluster_10")!, UIImage(named: "cluster_25")!, UIImage(named: "cluster_50")!, UIImage(named: "cluster_100")!, UIImage(named: "cluster_500")!, UIImage(named: "cluster_1000")!]
        
        // Set up the cluster manager with default icon generator and renderer.
        let iconGenerator = GMUDefaultClusterIconGenerator(buckets: numbers, backgroundImages: images)
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = GMUDefaultClusterRenderer(mapView: mapView, clusterIconGenerator: iconGenerator)
        clusterManager = GMUClusterManager(map: mapView, algorithm: algorithm, renderer: renderer)
        renderer.delegate = self
        
        // Generate and add random items to the cluster manager.
        generateClusterItems()
        
        // Call cluster() after items have been added to perform the clustering and rendering on map.
        clusterManager.cluster()
        
        // Register self to listen to both GMUClusterManagerDelegate and GMSMapViewDelegate events.
        clusterManager.setDelegate(self, mapDelegate: self)
    }
    
    // MARK: - Private
    /// Randomly generates cluster items within some extent of the camera and adds them to the
    /// cluster manager.
    private func generateClusterItems()
    {
        let extent = 0.2
        
        for index in 1...kClusterItemCount
        {
            let lat = kCameraLatitude + extent * self.randomScale()
            let lng = kCameraLongitude + extent * self.randomScale()
            let name = "Item \(index)"
            let item = POIItem(position: CLLocationCoordinate2DMake(lat, lng), name: name)
            
            self.clusterManager.add(item)
        }
    }
    
    /// Returns a random value between -1.0 and 1.0.
    private func randomScale() -> Double
    {
        return Double(arc4random()) / Double(UINT32_MAX) * 2.0 - 1.0
    }
}

// MARK: - GMUClusterManagerDelegate
extension ClusteringViewController: GMUClusterManagerDelegate
{
    func clusterManager(_ clusterManager: GMUClusterManager, didTap cluster: GMUCluster) -> Bool
    {
        let newCamera = GMSCameraPosition.camera(withTarget: cluster.position, zoom: mapView.camera.zoom + 1)
        let update = GMSCameraUpdate.setCamera(newCamera)
        mapView.moveCamera(update)
        
        return false
    }
}

// MARK: - GMUMapViewDelegate
extension ClusteringViewController: GMSMapViewDelegate
{
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool
    {
        if let poiItem = marker.userData as? POIItem {
            
            NSLog("Did tap marker for cluster item \(poiItem.name)")
            
        }
        else
        {
            NSLog("Did tap a normal marker")
        }
        
        return false
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D)
    {
        print("LAT: \(coordinate.latitude) -  LONG: \(coordinate.longitude)")
        
        //Get Country and State
        let geocoder = GMSGeocoder()
        geocoder.reverseGeocodeCoordinate(coordinate) { (GMSReverseGeocodeResponse, error) in
            
            let address = GMSReverseGeocodeResponse?.firstResult()//.results()
            print(address?.country ?? "none")
            print(address?.administrativeArea ?? "none")
        }
    }
    
    
    func mapView(_ mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView?
    {
        if let _ = marker.userData as? GMUCluster {
            
            //Cluster
            return nil
        }
        else
        {
            //Location Point
            let view = UIView(frame: CGRect(x: marker.accessibilityActivationPoint.x, y: marker.accessibilityActivationPoint.y, width: 100, height: 100))
            
            return view
        }
    }
}

//MARK: GMUClusterRendererDelegate
extension ClusteringViewController: GMUClusterRendererDelegate
{
    func renderer(_ renderer: GMUClusterRenderer, markerFor object: Any) -> GMSMarker
    {
        let pin = GMSMarker()
        pin.icon = UIImage(named: "pin_location")
        
        return pin
    }
    
    func renderer(_ renderer: GMUClusterRenderer, willRenderMarker marker: GMSMarker)
    {
        print("nada")
    }
}
