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

  /// Removes spaces, dashes, and "ISBN" prefix if present, from a string of digits.
  /// If older 9-digit SPN, will prepend a '0' to convert to ISBN.
  func cleanISBN(_ text: String) -> String {
    var temp = text.uppercased()
    temp = temp.replacingOccurrences(of: "ISBN", with: "")
    temp = temp.replacingOccurrences(of: " ", with: "")
    temp = temp.replacingOccurrences(of: "-", with: "")
    if temp.count == 9 {
      temp = "0" + temp
    }
    return temp
  }

  /// Converts a clean ISBN into a version for display. (NOT USED)
  func formatISBN(_ isbn: String) -> String {
    // not adding dashes as it's complicated
    return "ISBN \(isbn)"
  }

  /// Returns true if given clean ISBN string is a valid ISBN.
  func isISBN(_ isbn: String) -> Bool {
    // ISBN-10 may have an 'X' which we replace with 'A' as a hack
    let isbn2 = isbn.replacingOccurrences(of: "X", with: "A")
    // test that only 0-9 & A characters present
    if Int(isbn2, radix: 11) != nil {
      if isbn2.count == 10 {
        // ISBN-10
        // following algorithm returns true if check digit is valid
        var s = 0, t = 0
        isbn2.forEach { ch in
          t += Int(String(ch), radix: 16) ?? 0
          s += t
        }
        return ((s % 11) == 0)
      }
      else if (isbn2.count == 13) && (isbn2.hasPrefix("978") || isbn2.hasPrefix("979")) {
        // ISBN-13
        // not verifying check digit as this is good enough
        return true
      }
    }
    return false
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
      // display ISBN
      if let text = meta.stringValue {
        let isbn = cleanISBN(text)
        self.websiteLabel.text = isISBN(isbn) ? "ISBN \(isbn)" : "Not an ISBN"
      }
    }
  }

}
