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

class ViewController: UIViewController, ARSCNViewDelegate {
    
    // Lazy vars so they aren't instantiated until needed
    
    // ASRCNView
    //
    lazy var sceneView: ARSCNView = {
        let view = ARSCNView(frame: CGRect.zero)
        // ARSCN Delegate
        //
        view.delegate = self
        return view
    }()
    
    // Label to display status information
    //
    lazy var infoLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.title1)
        label.textAlignment = .center
        label.backgroundColor = .white
        return label
    }()
    
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
        
        // 1
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(recognizer:)))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Start ARKit session
        //
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
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
            }
        }
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
}

