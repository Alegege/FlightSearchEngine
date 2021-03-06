//
//  Created by Pierluigi Cifani on 06/05/16.
//  Copyright © 2018 TheLeftBit SL. All rights reserved.
//

import UIKit
import BSWFoundation

// MARK: PhotoGalleryViewDelegate protocol

public protocol PhotoGalleryViewDelegate: class {
    func didTapPhotoAt(index: UInt, fromView: UIView)
}

// MARK: - PhotoGalleryView

@objc(BSWPhotoGalleryView)
final public class PhotoGalleryView: UIView {
    
    fileprivate let imageContentMode: UIView.ContentMode
    fileprivate let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    fileprivate var collectionViewDataSource: CollectionViewStatefulDataSource<PhotoCollectionViewCell>!
    fileprivate var collectionViewLayout: UICollectionViewFlowLayout {
        return collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }

    fileprivate let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.hidesForSinglePage = true
        pageControl.pageIndicatorTintColor = UIColor.white
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.5)
        return pageControl
    }()
    
    public var photos = [Photo]() {
        didSet {
            collectionViewDataSource.updateState(.loaded(data: photos))
            pageControl.numberOfPages = photos.count
        }
    }
    
    fileprivate let updatePageControlOnScrollBehavior: UpdatePageControlOnScrollBehavior
    
    weak var delegate: PhotoGalleryViewDelegate?
    
    public var currentPage: UInt {
        return UInt(pageControl.currentPage)
    }
    
    // MARK: Initialization
    
    public init(photos: [Photo], imageContentMode: UIView.ContentMode = .scaleAspectFill) {
        self.photos = photos
        self.imageContentMode = imageContentMode
        updatePageControlOnScrollBehavior = UpdatePageControlOnScrollBehavior(pageControl: pageControl, scrollView: collectionView)
        super.init(frame: CGRect.zero)
        setup()
    }
    
    convenience public init() {
        self.init(photos: [])
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }    

    public func scrollToPhoto(atIndex index: UInt, animated: Bool = false) {
        collectionView.scrollToItem(at: IndexPath(item: Int(index), section: 0), at: .centeredHorizontally, animated: animated)
    }

    public func invalidateLayout() {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.setNeedsLayout()
        scrollToPhoto(atIndex: UInt(pageControl.currentPage))
    }

    fileprivate func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        // CollectionView
        addSubview(collectionView)
        collectionView.isPagingEnabled = true
        collectionViewDataSource = CollectionViewStatefulDataSource(
            state: .loaded(data: photos),
            collectionView: collectionView
        )
        collectionView.dataSource = collectionViewDataSource
        collectionView.delegate = self
        if #available(iOS 10.0, *) {
            collectionView.prefetchDataSource = self
        }
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = false
        collectionViewLayout.scrollDirection = .horizontal
        collectionViewLayout.minimumInteritemSpacing = 0
        collectionViewLayout.minimumLineSpacing = 0

        // Page control
        addAutolayoutSubview(pageControl)
        pageControl.numberOfPages = photos.count

        // Constraints
        setupConstraints()
    }

    // MARK: Constraints

    fileprivate func setupConstraints() {
        collectionView.pinToSuperview()

        let bottomConstraint: NSLayoutConstraint = {
            if #available(iOS 11, *) {
                return pageControl.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -CGFloat(Stylesheet.margin(.small)))
            } else {
                return pageControl.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -CGFloat(Stylesheet.margin(.small)))
            }
        }()
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            bottomConstraint
            ])
    }
}

// MARK: UICollectionViewDelegate

extension PhotoGalleryView: UICollectionViewDelegateFlowLayout {

    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let photoCell = cell as? PhotoCollectionViewCell else { return }
        photoCell.cellImageView.contentMode = self.imageContentMode
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else {
            return
        }
        delegate?.didTapPhotoAt(index: UInt(indexPath.item), fromView: cell)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.frame.size
    }
}

extension PhotoGalleryView: UICollectionViewDataSourcePrefetching {
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let models: [URL] = indexPaths
            .compactMap({ self.collectionViewDataSource.modelForIndexPath($0) })
            .compactMap({
                switch $0.kind {
                case .url(let url):
                    return url
                default:
                    return nil
                }
            })
        UIImageView.prefetchImagesAtURL(models)
    }
}
