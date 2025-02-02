import Foundation
import UIKit

class TagFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        var currentRowY: CGFloat = -1
        var currentRowAttributes: [UICollectionViewLayoutAttributes] = []
        
        for attribute in attributes {
            if attribute.frame.minY != currentRowY {
                currentRowY = attribute.frame.minY
                currentRowAttributes.removeAll()
            }
            currentRowAttributes.append(attribute)
        }
        
        return attributes
    }
}
