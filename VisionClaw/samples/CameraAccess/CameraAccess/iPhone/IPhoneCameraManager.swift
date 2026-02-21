import AVFoundation
import UIKit

class IPhoneCameraManager: NSObject {
  private let captureSession = AVCaptureSession()
  private let videoOutput = AVCaptureVideoDataOutput()
  private let sessionQueue = DispatchQueue(label: "iphone-camera-session")
  private let context = CIContext(options: [.useSoftwareRenderer: false])
  private var isRunning = false
  private var lastFrameTime: CFTimeInterval = 0
  private let frameInterval: CFTimeInterval = 1.0 / 24.0  // 24fps cap

  var onFrameCaptured: ((UIImage) -> Void)?

  func start() {
    guard !isRunning else { return }

    // AVAudioSession の .playAndRecord 有効化でカメラが中断されることがあるため、
    // 中断終了時に自動復帰するオブザーバを登録
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleInterruptionEnded),
      name: .AVCaptureSessionInterruptionEnded,
      object: captureSession
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleWasInterrupted),
      name: .AVCaptureSessionWasInterrupted,
      object: captureSession
    )

    sessionQueue.async { [weak self] in
      self?.configureSession()
      self?.captureSession.startRunning()
      self?.isRunning = true
    }
  }

  func stop() {
    guard isRunning else { return }
    NotificationCenter.default.removeObserver(self)
    sessionQueue.async { [weak self] in
      self?.captureSession.stopRunning()
      self?.isRunning = false
    }
  }

  @objc private func handleWasInterrupted(_ notification: Notification) {
    NSLog("[iPhoneCamera] Capture session interrupted")
  }

  @objc private func handleInterruptionEnded(_ notification: Notification) {
    NSLog("[iPhoneCamera] Interruption ended, restarting capture session")
    sessionQueue.async { [weak self] in
      guard let self, self.isRunning, !self.captureSession.isRunning else { return }
      self.captureSession.startRunning()
      NSLog("[iPhoneCamera] Capture session restarted")
    }
  }

  private func configureSession() {
    captureSession.beginConfiguration()
    captureSession.sessionPreset = .medium

    // Add back camera input
    guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
          let input = try? AVCaptureDeviceInput(device: camera) else {
      NSLog("[iPhoneCamera] Failed to access back camera")
      captureSession.commitConfiguration()
      return
    }

    if captureSession.canAddInput(input) {
      captureSession.addInput(input)
    }

    // Add video output
    videoOutput.videoSettings = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ]
    videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
    videoOutput.alwaysDiscardsLateVideoFrames = true

    if captureSession.canAddOutput(videoOutput) {
      captureSession.addOutput(videoOutput)
    }

    // Fix orientation to portrait
    if let connection = videoOutput.connection(with: .video) {
      if connection.isVideoRotationAngleSupported(90) {
        connection.videoRotationAngle = 90
      }
    }

    captureSession.commitConfiguration()
    NSLog("[iPhoneCamera] Session configured")
  }

  static func requestPermission() async -> Bool {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .authorized:
      return true
    case .notDetermined:
      return await AVCaptureDevice.requestAccess(for: .video)
    default:
      return false
    }
  }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension IPhoneCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    // Throttle to 24fps — drop excess frames to reduce main thread pressure
    let now = CACurrentMediaTime()
    guard now - lastFrameTime >= frameInterval else { return }
    lastFrameTime = now

    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
    let image = UIImage(cgImage: cgImage)

    onFrameCaptured?(image)
  }
}
