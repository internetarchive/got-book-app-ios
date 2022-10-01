//
//  QRViewController.swift
//  GotBook
//
//  Created by Carl on 3/8/19.
//  Copyright © 2019 Carl Gorringe. All rights reserved.
//
// QR reader code modified from:
// https://www.appcoda.com/qr-code-reader-swift/

import UIKit
import AVFoundation
// import CoreData

class QRViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

  // UI
  @IBOutlet weak var websiteLabel: UILabel!
  @IBOutlet weak var videoView: UIView!

  // class vars
  // var detailsVC: DetailsViewController?
  var captureSession: AVCaptureSession?
  var videoLayer: AVCaptureVideoPreviewLayer?
  var qrFrameView: UIView?

  ////////////////////////////////////////////////////////////////////////////////////////////////////
  // MARK: - View Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    self.websiteLabel.text = nil
  }

  override func viewDidAppear(_ animated: Bool) {
    // super.viewWillAppear(animated) // why?
    setupVideoInput()
  }

  // override func viewWillDisappear(_ animated: Bool) {
    // self.detailsVC?.updateWebsite(self.websiteLabel.text)
  // }

  ////////////////////////////////////////////////////////////////////////////////////////////////////
  // MARK: - Video Setup

  /// Setup video capture for QR code detection.
  func setupVideoInput() {
    if let captureDevice = AVCaptureDevice.default(for: .video) {
      do {
        // setup video input
        let input = try AVCaptureDeviceInput(device: captureDevice)
        self.captureSession = AVCaptureSession()
        self.captureSession?.addInput(input)

        // setup QR output
        let output = AVCaptureMetadataOutput()
        self.captureSession?.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.ean13]

        // init video preview layer
        self.videoLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
        self.videoLayer?.videoGravity = .resizeAspectFill
        self.videoLayer?.frame = self.videoView.bounds
        self.videoView.layer.addSublayer(self.videoLayer!)
        setupFrameView()

        // start video capture
        self.captureSession?.startRunning()
      }
      catch {
        NSLog("ERROR: Couldn't set up video input in \(#function)")
      }
    }
    else {
      NSLog("ERROR: captureDevice is null in \(#function)")
    }
  }

  /// Prepare the QR frame view that will display when QR code is detected.
  func setupFrameView() {
    let fview = UIView.init(frame: CGRect.zero)
    fview.layer.borderColor = UIColor.magenta.cgColor
    fview.layer.borderWidth = 2
    self.videoView.addSubview(fview)
    self.videoView.bringSubviewToFront(fview)
    self.qrFrameView = fview
  }

  ////////////////////////////////////////////////////////////////////////////////////////////////////
  // MARK: - AVCaptureMetadataOutputObjectsDelegate

  func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject],
                      from connection: AVCaptureConnection)
  {
    guard let meta = metadataObjects.first as? AVMetadataMachineReadableCodeObject else {
      self.qrFrameView?.frame = CGRect.zero
      return
    }
    if meta.type == .ean13 {
      // draw box around ISBN barcode (EAN-13)
      let barcode = self.videoLayer?.transformedMetadataObject(for: meta) as! AVMetadataMachineReadableCodeObject
      self.qrFrameView?.frame = barcode.bounds
      // display URL
      if let text = meta.stringValue {
        self.websiteLabel.text = text
      }
    }
  }

}
