//
//  ViewController.swift
//  CameraTestForML
//
//  Created by Gokul Murugan on 19/02/24.
//

import Foundation

import AVFoundation
import UIKit
class ViewController: UIViewController {

  // MARK: Storyboards Connections
  let previewView = PreviewView()

  // MARK: Constants
  private let animationDuration = 0.5
  private let collapseTransitionThreshold: CGFloat = -40.0
  private let expandTransitionThreshold: CGFloat = 40.0
  private let delayBetweenInferencesMs = 1000.0

  // MARK: Instance Variables
  private let inferenceQueue = DispatchQueue(label: "org.tensorflow.lite.inferencequeue")
  private var previousInferenceTimeMs = Date.distantPast.timeIntervalSince1970 * 1000
  private var isInferenceQueueBusy = false
  private var initialBottomSpace: CGFloat = 0.0
  private var threadCount = DefaultConstants.threadCount

  private var scoreThreshold = DefaultConstants.scoreThreshold
  private var model: ModelType = .efficientnetLite0

  // MARK: Controllers that manage functionality
  // Handles all the camera related functionality
  private lazy var cameraCapture = CameraFeedManager(previewView: previewView)

  // Handles all data preprocessing and makes calls to run inference through the
  // `ImageClassificationHelper`.
  private var imageClassificationHelper: ImageClassificationHelper? =
    ImageClassificationHelper(
      modelFileInfo: DefaultConstants.model.modelFileInfo,
      threadCount: DefaultConstants.threadCount,
      resultCount: DefaultConstants.maxResults,
      scoreThreshold: DefaultConstants.scoreThreshold)

    // MARK: View Handling Methods
  override func viewDidLoad() {
    super.viewDidLoad()

    guard imageClassificationHelper != nil else {
      fatalError("Model initialization failed.")
    }

    cameraCapture.delegate = self
    //view.layoutSubviews()
      view.addSubview(previewView)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    #if !targetEnvironment(simulator)
      cameraCapture.checkCameraConfigurationAndStartSession()
    #endif
  }

  #if !targetEnvironment(simulator)
    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      cameraCapture.stopSession()
    }
  #endif

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  func presentUnableToResumeSessionAlert() {
    let alert = UIAlertController(
      title: "Unable to Resume Session",
      message: "There was an error while attempting to resume session.",
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

    self.present(alert, animated: true)
  }
  
}
// MARK: CameraFeedManagerDelegate Methods
extension ViewController: CameraFeedManagerDelegate {

  func didOutput(pixelBuffer: CVPixelBuffer) {
    // Make sure the model will not run too often, making the results changing quickly and hard to
    // read.
    let currentTimeMs = Date().timeIntervalSince1970 * 1000
    guard (currentTimeMs - previousInferenceTimeMs) >= delayBetweenInferencesMs else { return }
    previousInferenceTimeMs = currentTimeMs

    // Drop this frame if the model is still busy classifying a previous frame.
    guard !isInferenceQueueBusy else { return }

    inferenceQueue.async { [weak self] in
      guard let self = self else { return }

      self.isInferenceQueueBusy = true

      // Pass the pixel buffer to TensorFlow Lite to perform inference.
      let result = self.imageClassificationHelper?.classify(frame: pixelBuffer)

      self.isInferenceQueueBusy = false

      // Display results by handing off to the InferenceViewController.
      DispatchQueue.main.async {
          _ = CGSize(
          width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        
          print(result?.classifications.categories.first?.label)
      }
    }
  }

  // MARK: Session Handling Alerts
  func sessionWasInterrupted(canResumeManually resumeManually: Bool) {

    // Updates the UI when session is interupted.
   
  }

  func sessionInterruptionEnded() {
    // Updates UI once session interruption has ended.
   
  }

  func sessionRunTimeErrorOccured() {
    previewView.shouldUseClipboardImage = true
  }

  func presentCameraPermissionsDeniedAlert() {
    let alertController = UIAlertController(
      title: "Camera Permissions Denied",
      message:
        "Camera permissions have been denied for this app. You can change this by going to Settings",
      preferredStyle: .alert)

    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in
      UIApplication.shared.open(
        URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
    alertController.addAction(cancelAction)
    alertController.addAction(settingsAction)

    present(alertController, animated: true, completion: nil)

    previewView.shouldUseClipboardImage = true
  }

  func presentVideoConfigurationErrorAlert() {
    let alert = UIAlertController(
      title: "Camera Configuration Failed", message: "There was an error while configuring camera.",
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

    self.present(alert, animated: true)
    previewView.shouldUseClipboardImage = true
  }
}

// Define default constants
enum DefaultConstants {
  static let threadCount = 4
  static let maxResults = 3
  static let scoreThreshold: Float = 0.2
  static let model: ModelType = .efficientnetLite0
}

/// TFLite model types
enum ModelType: CaseIterable {
  case efficientnetLite0
  case efficientnetLite1
  case efficientnetLite2
  case efficientnetLite3
  case efficientnetLite4

  var modelFileInfo: FileInfo {
    switch self {
    case .efficientnetLite0:
      return FileInfo("efficientnet_lite0", "tflite")
    case .efficientnetLite1:
      return FileInfo("efficientnet_lite1", "tflite")
    case .efficientnetLite2:
      return FileInfo("efficientnet_lite2", "tflite")
    case .efficientnetLite3:
      return FileInfo("efficientnet_lite3", "tflite")
    case .efficientnetLite4:
      return FileInfo("efficientnet_lite4", "tflite")
    }
  }

  var title: String {
    switch self {
    case .efficientnetLite0:
      return "EfficientNet-Lite0"
    case .efficientnetLite1:
      return "EfficientNet-Lite1"
    case .efficientnetLite2:
      return "EfficientNet-Lite2"
    case .efficientnetLite3:
      return "EfficientNet-Lite3"
    case .efficientnetLite4:
      return "EfficientNet-Lite4"
    }
  }
}
