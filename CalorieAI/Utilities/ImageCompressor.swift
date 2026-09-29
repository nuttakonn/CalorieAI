import UIKit

struct ImageCompressor {
    static func compress(image: UIImage, maxMB: Double = 1.0) -> Data? {
        let maxDimension: CGFloat = 800.0
        var targetSize = image.size
        
        if targetSize.width > maxDimension || targetSize.height > maxDimension {
            let ratio = min(maxDimension / targetSize.width, maxDimension / targetSize.height)
            targetSize = CGSize(width: targetSize.width * ratio, height: targetSize.height * ratio)
        }
        
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let finalImage = resizedImage else { return nil }
        
        // Use a moderate compression quality
        return finalImage.jpegData(compressionQuality: 0.6)
    }
}
