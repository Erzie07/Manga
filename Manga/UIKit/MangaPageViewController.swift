import Foundation
import UIKit
import SwiftUI

final class MangaPageViewController: UIViewController {
    private var pageViewController: UIPageViewController!
    private(set) var currentPage: Int
    private var totalPages: Int
    var loadedImages: [Int: UIImage]
    private var onPageChanged: (Int) -> Void
    private var onInteraction: () -> Void
    
    init(currentPage: Int,
         totalPages: Int,
         loadedImages: [Int: UIImage],
         onPageChanged: @escaping (Int) -> Void,
         onInteraction: @escaping () -> Void) {
        self.currentPage = min(max(currentPage, 0), totalPages - 1)
        self.totalPages = totalPages
        self.loadedImages = loadedImages
        self.onPageChanged = onPageChanged
        self.onInteraction = onInteraction
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPageViewController()
        setupTapGesture()
    }
    
    func setCurrentPage(_ page: Int, animated: Bool) {
        guard page >= 0 && page < totalPages else { return }
        guard currentPage != page else { return }
        
        let direction: UIPageViewController.NavigationDirection = page > currentPage ? .forward : .reverse
        currentPage = page
        let vc = createContentViewController(for: page)
        pageViewController.setViewControllers([vc], direction: direction, animated: animated, completion: nil)
    }
    
    private func setupPageViewController() {
        pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let initialVC = createContentViewController(for: currentPage)
        pageViewController.setViewControllers([initialVC], direction: .forward, animated: false)
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap() {
        onInteraction()
    }
    
    // Add the missing createContentViewController method
    private func createContentViewController(for page: Int) -> UIViewController {
        let contentVC = UIViewController()
        contentVC.view.backgroundColor = .systemBackground
        contentVC.view.tag = page
        
        if let image = loadedImages[page] {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            contentVC.view.addSubview(imageView)
            
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: contentVC.view.topAnchor),
                imageView.leadingAnchor.constraint(equalTo: contentVC.view.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: contentVC.view.trailingAnchor),
                imageView.bottomAnchor.constraint(equalTo: contentVC.view.bottomAnchor)
            ])
        } else {
            let spinner = UIActivityIndicatorView(style: .large)
            spinner.startAnimating()
            contentVC.view.addSubview(spinner)
            
            spinner.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                spinner.centerXAnchor.constraint(equalTo: contentVC.view.centerXAnchor),
                spinner.centerYAnchor.constraint(equalTo: contentVC.view.centerYAnchor)
            ])
        }
        
        return contentVC
    }
    
    // Add the missing updateLoadedImages method
    func updateLoadedImages(_ newImages: [Int: UIImage]) {
        guard loadedImages != newImages else { return }
        loadedImages = newImages
        if let currentVC = pageViewController.viewControllers?.first {
            let currentIndex = currentVC.view.tag
            let newVC = createContentViewController(for: currentIndex)
            pageViewController.setViewControllers([newVC], direction: .forward, animated: false)
        }
    }
}


// MARK: - UIPageViewController DataSource & Delegate
extension MangaPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let currentIndex = viewController.view.tag
        let previousIndex = currentIndex + 1
        guard previousIndex >= 0 else { return nil }
        return createContentViewController(for: previousIndex)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let currentIndex = viewController.view.tag
        let nextIndex = currentIndex - 1
        guard nextIndex < totalPages else { return nil }
        return createContentViewController(for: nextIndex)
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard finished && completed,
              let visibleViewController = pageViewController.viewControllers?.first else { return }
        
        let newPage = visibleViewController.view.tag
        if currentPage != newPage {
            currentPage = newPage
            onPageChanged(newPage)
        }
    }
}

extension MangaPageViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
}

struct PageViewControllerRepresentable: UIViewControllerRepresentable {
    let currentPage: Int
    let totalPages: Int
    let loadedImages: [Int: UIImage]
    let onPageChanged: (Int) -> Void
    let onInteraction: () -> Void
    
    func makeUIViewController(context: Context) -> MangaPageViewController {
        return MangaPageViewController(
            currentPage: currentPage,
            totalPages: totalPages,
            loadedImages: loadedImages,
            onPageChanged: onPageChanged,
            onInteraction: onInteraction
        )
    }
    
    // In PageViewControllerRepresentable's updateUIViewController
    func updateUIViewController(_ pageViewController: MangaPageViewController, context: Context) {
        if pageViewController.loadedImages != loadedImages {
            pageViewController.updateLoadedImages(loadedImages)
        }
        
        // Sync current page if needed
        if pageViewController.currentPage != currentPage {
            pageViewController.setCurrentPage(currentPage, animated: false)
        }
    }
}
