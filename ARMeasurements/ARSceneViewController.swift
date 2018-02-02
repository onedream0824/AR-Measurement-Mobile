//
//  ViewController.swift
//  ARMeasurements
//
//  Created by Dave on 2/2/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class ARSceneViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var infoLabel: UILabel!
    
    var nodes = [ARSphere]()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(sceneView)
        
        // Add label to view
        //
        view.addSubview(infoLabel)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Resize the scence view
        //
        sceneView.frame = view.bounds
        
        // Update label position
        //
        infoLabel.frame = CGRect(x: 0, y: 16, width: view.bounds.width, height: 64)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(recognizer:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Start ARKit session
        //
        let configuration = ARWorldTrackingConfiguration()
        sceneView.delegate = self
        // Add horizontal plane detection
        //
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
    }
    
    // Marker: ARSCNViewDelegate
    //
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        var status = "Loading..."
        
        switch camera.trackingState {
            
        case ARCamera.TrackingState.notAvailable:
            status = "Not available"
        case ARCamera.TrackingState.limited(_):
            status = "Analyzing"
        case ARCamera.TrackingState.normal:
            // Once the status is normal we can place virtual objects into our scene
            //
            status = "Ready"
        }
        infoLabel.text = status
    }
    
    // Marker: Initial Plane Detection
    //
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.materials.first?.diffuse.contents = UIColor.transparentBlue()
        
        let planeNode = SCNNode(geometry: plane)
        
        planeNode.position = SCNVector3.getSCNVectorFrom(planeAnchor: planeAnchor)
        planeNode.eulerAngles.x = -.pi / 2
        
        node.addChildNode(planeNode)
    }
    
    // Update the size of a detected plane
    //
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
              let planeNode = node.childNodes.first,
              let plane = planeNode.geometry as? SCNPlane
        else { return }
        
        // update the size of the plane
        //
        plane.width =  CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
        
        // update the position of the plane
        //
        planeNode.position = SCNVector3.getSCNVectorFrom(planeAnchor: planeAnchor)
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: sceneView)
        
        // Find point in 3D that correspondes to the 2D point in the view
        //
        let hitTestResults = sceneView.hitTest(location, types: .featurePoint)
        
        if let result = hitTestResults.first {
            // Get 3D point coordinates
            //
            let vector = SCNVector3.positionFrom(matrix: result.worldTransform)
            
            // Create a sphere at that point
            //
            let sphere = ARSphere(vector3: vector)
            
            // Add the sphere to scene
            //
            sceneView.scene.rootNode.addChildNode(sphere)
            
            let lastNode = nodes.last
            nodes.append(sphere)
            
            if lastNode != nil {
                // Calculate the distance between the last two spheres
                //
                let distanceInMeters = lastNode!.position.distanceTo(destination: sphere.position)
                let inches = distanceInMeters * 39.3701
                
                if inches > 12 {
                    // Use feet
                    //
                    infoLabel.text = String(format: "Distance: %.3f feet", inches / 12)
                } else {
                    infoLabel.text = String(format: "Distance: %.3f inches", inches)
                }
                
                // Draw a line between those two spheres
                //
                let lineNode = getLineDrawing(from: vector, to: lastNode!.position)
                sceneView.scene.rootNode.addChildNode(lineNode)
            }
        }
    }
    
    // Marker: Drawing lines
    //
    func getLineDrawing(from: SCNVector3, to: SCNVector3) -> SCNNode {
        let lineGeometry = getLineGeometry(from: from, to: to)
        let lineInBetween = SCNNode(geometry: lineGeometry)
        
        return lineInBetween
    }
    
    func getLineGeometry(from: SCNVector3, to: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [from, to])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        return SCNGeometry(sources: [source], elements: [element])
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the session
        //
        sceneView.session.pause()
    }
}

extension SCNVector3 {
    
    // Calculates and returns the distance from one SCNVector to another
    //
    func distanceTo(destination: SCNVector3) -> CGFloat {
        let xDiff = destination.x - self.x
        let yDiff = destination.y - self.y
        let zDiff = destination.z - self.z
        
        let meters = CGFloat(sqrt(xDiff * xDiff + yDiff * yDiff + zDiff * zDiff))
        return meters
    }
    
    // Takes the worldTransform vector and creates an SCNVector3
    //
    static func positionFrom(matrix: matrix_float4x4) -> SCNVector3 {
        let column = matrix.columns.3
        return SCNVector3(column.x, column.y, column.z)
    }
    
    // Create SCNVector3 from a planeAnchor
    //
    static func getSCNVectorFrom(planeAnchor: ARPlaneAnchor) -> SCNVector3 {
        return SCNVector3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
    }
}

extension UIColor {
    static func transparentBlue() -> UIColor {
        return UIColor.init(red: 14/255, green: 122/255, blue: 254/255, alpha: 0.2)
        // return UIColor(red: 0.0, green: 0.0, blue: 255.0, alpha: 0.2)
    }
}

