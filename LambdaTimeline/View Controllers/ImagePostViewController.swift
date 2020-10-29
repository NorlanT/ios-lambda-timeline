//
//  ImagePostViewController.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/12/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import Photos
import CoreImage
import CoreImage.CIFilterBuiltins

class ImagePostViewController: ShiftableViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var chooseImageButton: UIButton!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var postButton: UIBarButtonItem!
    
    @IBOutlet weak var gaussianSlider: UISlider!
    @IBOutlet weak var hueSlider: UISlider!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var saturationSlider: UISlider!
    @IBOutlet weak var sepiaSlider: UISlider!
    
    
    // MARK: - Properties
    
    var postController: PostController!
    var post: Post?
    var imageData: Data?
    
    
    var originalImage: UIImage? {
        didSet {
            guard let originalImage = originalImage else {
                scaledImage = nil
                return
            }
            
            var scaledSize = imageView.bounds.size
            let scale = imageView.contentScaleFactor
            
            scaledSize = CGSize(width: scaledSize.width*scale, height: scaledSize.height*scale)
            
            guard let scaledUIImage = originalImage.imageByScaling(toSize: scaledSize) else {
                scaledImage = nil
                return
            }
            
            scaledImage = CIImage(image: scaledUIImage)
        }
    }
    
    var scaledImage: CIImage? {
        didSet{
            updateImage()
        }
    }
    
    
    let context = CIContext()
    
    private let colorControlsFilter = CIFilter.colorControls()
    
    private let gaussianBlurFilter = CIFilter.gaussianBlur()
    private let hueFilter = CIFilter.hueAdjust()
    private let saturationFilter = CIFilter.saturationBlendMode()
    private let brightnessFilter = CIFilter.saturationBlendMode()
    private let sepiaFilter = CIFilter.sepiaTone()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        originalImage = imageView.image
        
        setImageViewHeight(with: 1.0)
    }
    
    private func image(byFiltering inputImage: CIImage) -> UIImage {
        
        colorControlsFilter.inputImage = inputImage
        colorControlsFilter.saturation = saturationSlider.value
        colorControlsFilter.brightness = brightnessSlider.value
        
        gaussianBlurFilter.inputImage = colorControlsFilter.outputImage?.clampedToExtent()
        gaussianBlurFilter.radius = gaussianSlider.value
        
        hueFilter.inputImage = gaussianBlurFilter.outputImage?.clampedToExtent()
        hueFilter.angle = hueSlider.value
        
        sepiaFilter.inputImage = hueFilter.outputImage?.clampedToExtent()
        sepiaFilter.intensity = sepiaSlider.value
        
        guard let outputImage = sepiaFilter.outputImage else { return originalImage! }
        
        guard let renderImage = context.createCGImage(outputImage, from: inputImage.extent) else { return originalImage! }
        
        return UIImage(cgImage: renderImage)
        
    }//
    
    
    private func updateImage() {
        if let scaledImage = scaledImage {
            imageView.image = image(byFiltering: scaledImage)
        } else {
            imageView.image = nil
        }
    }
    
    
    private func presentImagePickerController() {
        
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            presentInformationalAlertController(title: "Error", message: "The photo library is unavailable")
            return
        }
        
        DispatchQueue.main.async {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            
            self.present(imagePicker, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func createPost(_ sender: Any) {
        
        view.endEditing(true)
        
        guard let image = imageView.image,
            let title = titleTextField.text, title != "" else {
                presentInformationalAlertController(title: "Uh-oh", message: "Make sure that you add a photo and a caption before posting.")
                return
        }

        postController.createImagePost(with: title, image: image, ratio: image.ratio)
        
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func chooseImage(_ sender: Any) {
        
        let authorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch authorizationStatus {
        case .authorized:
            presentImagePickerController()
        case .notDetermined:
            
            PHPhotoLibrary.requestAuthorization { (status) in
                
                guard status == .authorized else {
                    NSLog("User did not authorize access to the photo library")
                    self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
                    return
                }
                
                self.presentImagePickerController()
            }
            
        case .denied:
            self.presentInformationalAlertController(title: "Error", message: "In order to access the photo library, you must allow this application access to it.")
        case .restricted:
            self.presentInformationalAlertController(title: "Error", message: "Unable to access the photo library. Your device's restrictions do not allow access.")
        default:
            break
        }
        presentImagePickerController()
    }
    
    @IBAction func addFilter(_ sender: Any) {
        
    }
    
    @IBAction func gaussianChanged(_ sender: UISlider) {
        updateImage()
    }
    
    @IBAction func hueChanged(_ sender: UISlider) {
        updateImage()
    }
    
    @IBAction func brightnessChanged(_ sender: UISlider) {
        updateImage()
    }
    
    @IBAction func saturationChanged(_ sender: UISlider) {
        updateImage()
    }
    
    @IBAction func sepiaChanged(_ sender: UISlider) {
        updateImage()
    }
    
    
    
    
    func setImageViewHeight(with aspectRatio: CGFloat) {
        
        imageHeightConstraint.constant = imageView.frame.size.width * aspectRatio
        
        view.layoutSubviews()
    }
}

extension ImagePostViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        chooseImageButton.setTitle("", for: [])
        
        if let image = info[.editedImage] as? UIImage {
            originalImage = image
        } else if let image = info[.originalImage] as? UIImage {
            originalImage = image
        }
        
        picker.dismiss(animated: true, completion: nil)
        
        
        
//        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
//
//        imageView.image = image
//
//        setImageViewHeight(with: image.ratio)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
