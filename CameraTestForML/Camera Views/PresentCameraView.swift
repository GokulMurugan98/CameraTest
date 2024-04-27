//
//  PresentCameraView.swift
//  CameraTestForML
//
//  Created by Gokul Murugan on 19/02/24.
//

import SwiftUI

struct PresentCameraView:UIViewControllerRepresentable{
    func makeUIViewController(context: Context) -> ViewController {
        let vc = ViewController()
        return vc
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        //
    }
    
    
    typealias UIViewControllerType = ViewController
    
    
}
