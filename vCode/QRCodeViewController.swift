//
//  QRCodeViewController.swift
//  vCode
//
//  Created by DarkTango on 5/15/15.
//  Copyright (c) 2015 ruitaocc. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

class QRCodeViewController: UIViewController,AVCaptureMetadataOutputObjectsDelegate,UIImagePickerControllerDelegate ,UINavigationControllerDelegate{
    @IBOutlet var label:UILabel!
    @IBOutlet var nextstep:UIButton!
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    var qrcodeimg:UIImage?
    var stringInQRCode:String = ""
    var setted:Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        nextstep.setTitle(NSLocalizedString("next_step", comment: ""), forState: UIControlState.Normal)
               // Do any additional setup after loading the view.
    }

    @IBAction func beginCapture(){
        stringInQRCode = ""
        beginCaptureSession()
    }
    
    @IBAction func readFromImage(){
        choose()
    }
    @IBAction func next(){
        if !setted{
            let alert:UIAlertView = UIAlertView()
            alert.message = "please scan QR code!"
            alert.addButtonWithTitle("OK")
            alert.show()
            return
        }
        let cutview = CutViewController()
        self.showViewController(cutview, sender: nextstep);
    }
    func choose(){
        setted = false
        stringInQRCode = ""
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary){
            var picker:UIImagePickerController = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            picker.mediaTypes = [kUTTypeImage]
            picker.allowsEditing = false
            self.presentViewController(picker, animated: true, completion: nil)
        }
    }
    func beginCaptureSession(){
        setted = false
        let captureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        var error:NSError?
        let input:AnyObject! = AVCaptureDeviceInput.deviceInputWithDevice(captureDevice, error: &error)
        
        if(error != nil){
            println("\(error?.localizedDescription)")
            return
        }
        captureSession = AVCaptureSession()
        captureSession?.addInput(input as! AVCaptureInput)

        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession?.addOutput(captureMetadataOutput)
        
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)
        view.bringSubviewToFront(label)
        captureSession?.startRunning()
        
        
        qrCodeFrameView = UIView()
        qrCodeFrameView?.layer.borderColor = UIColor.greenColor().CGColor
        qrCodeFrameView?.layer.borderWidth = 2
        view.addSubview(qrCodeFrameView!)
        view.bringSubviewToFront(qrCodeFrameView!)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        if metadataObjects == nil || metadataObjects.count == 0{
            qrCodeFrameView?.frame = CGRectZero
            label.text = "No QR code is detected!"
            return
        }
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if metadataObj.type == AVMetadataObjectTypeQRCode{
            let barCodeObject = videoPreviewLayer?.transformedMetadataObjectForMetadataObject(metadataObj as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
            qrCodeFrameView?.frame = barCodeObject.bounds
            if metadataObj.stringValue != nil{
                setted = true
                label.text = metadataObj.stringValue
                RequestSender.shortURL = label.text!
                captureSession?.stopRunning()
                videoPreviewLayer?.removeFromSuperlayer()
                qrCodeFrameView?.removeFromSuperview()
                
            }
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        
        
        if let str = QRDetector.decodeQRwithImg(image){
            stringInQRCode = str
        }
        if stringInQRCode != "" {
            setted = true
            label.text = stringInQRCode
            println(stringInQRCode)
        }
        else{
            let alertview = UIAlertView()
            alertview.message = "No QR Code detect!"
            alertview.addButtonWithTitle("OK")
            alertview.show()
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
