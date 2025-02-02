import Foundation
import UIKit

class TagCell: UICollectionViewCell {
    private let label: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(label)
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth = 1
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12)
        ])
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: 32)
        layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .required
        )
        return layoutAttributes
    }
    
    func configure(with tag: Tag, isIncluded: Bool, isExcluded: Bool) {
        label.text = tag.attributes.name["en"]
        
        if isIncluded {
            contentView.backgroundColor = .systemBlue
            label.textColor = .white
            contentView.layer.borderColor = UIColor.clear.cgColor
        } else if isExcluded {
            contentView.backgroundColor = .systemRed.withAlphaComponent(0.1)
            label.textColor = .label
            contentView.layer.borderColor = UIColor.systemRed.cgColor
        } else {
            contentView.backgroundColor = .clear
            label.textColor = .label
            contentView.layer.borderColor = UIColor.gray.withAlphaComponent(0.3).cgColor
        }
    }
}
