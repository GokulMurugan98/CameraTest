//
//  ContentView.swift
//  CameraTestForML
//
//  Created by Gokul Murugan on 19/02/24.
//

import SwiftUI


class ViewModel:ObservableObject{
    @Published var image:UIImage?
    
}

struct ContentView: View {
    @StateObject var cameraFeedManager = CameraFeedManager(previewView: PreviewView())
    
    var body: some View {
        VStack {
            if let image = ViewModel().image{
                Image(uiImage:  image)
                    .resizable()
            } else {
                Image(systemName: "photo.fill")
                    .resizable()
            }
            
            PresentCameraView()
                .onAppear{
                    cameraFeedManager.checkCameraConfigurationAndStartSession()
                    
                }
            
            
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
