//
//  Sphere.swift
//  ARMeasurements
//
//  Created by Dave on 2/2/18.
//  Copyright © 2018 High Tree Development. All rights reserved.
//

import SceneKit

class ARSphere: SCNNode {
    
    init(vector3: SCNVector3) {
        super.init()
        let sphere = SCNSphere(radius: 0.0025)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        material.lightingModel = .physicallyBased
        sphere.materials = [material]
        self.geometry = sphere
        self.position = vector3
    }
    
    
    // No new properties so we can just use the super calls to handle serialization
    //
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
    }
}
