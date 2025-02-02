import Foundation
import UIKit

class TagFilterViewController: UIViewController {
    private var viewModel: MangaListViewModel
    private var collectionViews: [TagCategory: UICollectionView] = [:]
    
    private lazy var containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    init(viewModel: MangaListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(containerStack)
        
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            containerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerStack.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Inclusion Mode Section
        let modeStack = UIStackView()
        modeStack.axis = .horizontal
        modeStack.spacing = 8
        modeStack.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        modeStack.isLayoutMarginsRelativeArrangement = true
        
        let modeLabel = UILabel()
        modeLabel.text = "Inclusion mode"
        modeLabel.textColor = .secondaryLabel
        
        let segmentedControl = UISegmentedControl(items: TagInclusionMode.allCases.map { $0.rawValue })
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(inclusionModeChanged), for: .valueChanged)
        
        modeStack.addArrangedSubview(modeLabel)
        modeStack.addArrangedSubview(segmentedControl)
        containerStack.addArrangedSubview(modeStack)
        
        // Instructions
        let instructionLabel = UILabel()
        instructionLabel.text = "Click once to include, twice to exclude, third time to clear"
        instructionLabel.font = .preferredFont(forTextStyle: .caption1)
        instructionLabel.textColor = .secondaryLabel
        instructionLabel.numberOfLines = 0
        instructionLabel.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        containerStack.addArrangedSubview(instructionLabel)
        
        // Tag Categories
        let tagStack = UIStackView()
        tagStack.axis = .vertical
        tagStack.spacing = 12
        
        for category in TagCategory.allCases {
            let categoryStack = UIStackView()
            categoryStack.axis = .vertical
            categoryStack.spacing = 8
            
            let titleLabel = UILabel()
            titleLabel.text = category.rawValue
            titleLabel.font = .preferredFont(forTextStyle: .headline)
            titleLabel.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            categoryStack.addArrangedSubview(titleLabel)
            
            let layout = TagFlowLayout()
            layout.minimumInteritemSpacing = 8
            layout.minimumLineSpacing = 8
            layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            
            let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
            collectionView.backgroundColor = .clear
            collectionView.register(TagCell.self, forCellWithReuseIdentifier: "TagCell")
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            collectionView.isScrollEnabled = false
            
            // Fixed height constraint based on content
            let heightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 100)
            heightConstraint.priority = .defaultHigh
            heightConstraint.isActive = true
            
            categoryStack.addArrangedSubview(collectionView)
            collectionViews[category] = collectionView
            
            if category != .content {
                let separator = UIView()
                separator.backgroundColor = .separator
                separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
                categoryStack.addArrangedSubview(separator)
            }
            
            tagStack.addArrangedSubview(categoryStack)
        }
        
        containerStack.addArrangedSubview(tagStack)
    }
    
    @objc private func inclusionModeChanged(_ sender: UISegmentedControl) {
        viewModel.filter.tagInclusionMode = TagInclusionMode.allCases[sender.selectedSegmentIndex]
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionViewHeights()
    }
    
    private func updateCollectionViewHeights() {
        for (_, collectionView) in collectionViews {
            collectionView.layoutIfNeeded()
            let height = collectionView.collectionViewLayout.collectionViewContentSize.height
            if let constraint = collectionView.constraints.first(where: { $0.firstAttribute == .height }) {
                constraint.constant = height
            }
        }
    }
}

extension TagFilterViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let category = collectionViews.first(where: { $0.value == collectionView })?.key else { return 0 }
        return viewModel.tags.filter { $0.category == category }.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCell", for: indexPath) as! TagCell
        guard let category = collectionViews.first(where: { $0.value == collectionView })?.key else { return cell }
        
        let categoryTags = viewModel.tags.filter { $0.category == category }
        let tag = categoryTags[indexPath.item]
        
        cell.configure(
            with: tag,
            isIncluded: viewModel.filter.selectedTags.contains(tag.id),
            isExcluded: viewModel.filter.excludedTags.contains(tag.id)
        )
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let category = collectionViews.first(where: { $0.value == collectionView })?.key else { return }
        let categoryTags = viewModel.tags.filter { $0.category == category }
        let tag = categoryTags[indexPath.item]
        
        if viewModel.filter.selectedTags.contains(tag.id) {
            viewModel.filter.selectedTags.remove(tag.id)
            viewModel.filter.excludedTags.insert(tag.id)
        } else if viewModel.filter.excludedTags.contains(tag.id) {
            viewModel.filter.excludedTags.remove(tag.id)
        } else {
            viewModel.filter.selectedTags.insert(tag.id)
        }
        
        collectionView.reloadItems(at: [indexPath])
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let category = collectionViews.first(where: { $0.value == collectionView })?.key else { return .zero }
        let categoryTags = viewModel.tags.filter { $0.category == category }
        let tag = categoryTags[indexPath.item]
        
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.text = tag.attributes.name["en"]
        
        let size = label.sizeThatFits(.zero)
        return CGSize(width: size.width + 24, height: 32)
    }
}
