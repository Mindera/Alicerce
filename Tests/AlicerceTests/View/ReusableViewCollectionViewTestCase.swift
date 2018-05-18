//
//  ReusableViewCollectionViewTestCase.swift
//  Alicerce
//
//  Created by André Pacheco Neves on 20/11/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
import UIKit
@testable import Alicerce

class ReusableViewCollectionViewTestCase: XCTestCase {

    private var collectionViewController: TestCollectionViewController!
    private var collectionView: UICollectionView! { return collectionViewController.collectionView }
    private var collectionViewLayout: UICollectionViewFlowLayout! {
        return collectionView.collectionViewLayout as! UICollectionViewFlowLayout
    }

    override func setUp() {
        super.setUp()

        collectionViewController = TestCollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
    }

    override func tearDown() {
        collectionViewController = nil

        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // MARK: register

    func testRegister_WithCollectionViewCell_ShouldSucceedl() {
        collectionView.register(TestCollectionViewCell.self)

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TestCollectionViewCell.reuseIdentifier,
                                                      for: .zero)

        guard let _ = cell as? TestCollectionViewCell else {
            return XCTFail("unexpected cell type!")
        }
    }

    func testRegister_WithCollectionReusableView_ShouldSucceedl() {
        let kind = UICollectionElementKindSectionHeader

        // we always have to register and dequeue a cell so that the section isn't empty 🤷‍♂️
        collectionView.register(TestCollectionViewCell.self, forCellWithReuseIdentifier: "🔨🐒")
        let _ = collectionView.dequeueReusableCell(withReuseIdentifier: "🔨🐒", for: .zero)

        collectionView.register(TestCollectionReusableView.self, forSupplementaryViewOfKind: kind)

        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: TestCollectionReusableView.reuseIdentifier,
            for: .zero)

        guard let _ = view as? TestCollectionReusableView else {
            return XCTFail("unexpected view type!")
        }
    }

    // MARK: dequeue

    func testDequeue_WithCollectionViewCell_ShouldSucceed() {
        collectionView.register(TestCollectionViewCell.self,
                                forCellWithReuseIdentifier: TestCollectionViewCell.reuseIdentifier)

        let _: TestCollectionViewCell = collectionView.dequeueCell(for: .zero)
    }

    func testDequeue_WithCollectionReusableView_ShouldSucceed() {
        let kind = UICollectionElementKindSectionHeader

        // we always have to register and dequeue a cell so that the section isn't empty 🤷‍♂️
        collectionView.register(TestCollectionViewCell.self, forCellWithReuseIdentifier: "🔨🐒")
        let _ = collectionView.dequeueReusableCell(withReuseIdentifier: "🔨🐒", for: .zero)

        collectionView.register(TestCollectionReusableView.self, forSupplementaryViewOfKind: kind)

        let _: TestCollectionReusableView = collectionView.dequeueSupplementaryView(forElementKind: kind, at: .zero)
    }

    // MARK: cell

    func testCell_withRegisteredCollectionViewCell_ShouldSucceed() {
        collectionView.register(TestCollectionViewCell.self,
                                forCellWithReuseIdentifier: TestCollectionViewCell.reuseIdentifier)

        // force the collectionView to draw itself
        collectionViewController.view.layoutIfNeeded()

        let _: TestCollectionViewCell = collectionView.cell(for: .zero)
    }

    // MARK: supplementaryView

    func testSupplementaryView_WithRegisteredSupplementaryView() {
        let kind = UICollectionElementKindSectionHeader

        // we always have to register and dequeue a cell so that the section isn't empty 🤷‍♂️
        collectionView.register(TestCollectionViewCell.self,
                                forCellWithReuseIdentifier: TestCollectionViewCell.reuseIdentifier)

        collectionView.register(TestCollectionReusableView.self,
                                forSupplementaryViewOfKind: kind,
                                withReuseIdentifier: TestCollectionReusableView.reuseIdentifier)

        // give non zero size for supplementary view do be dequeued
        collectionViewLayout.headerReferenceSize = CGSize(width: 1, height: 1)

        // force the collectionView to draw itself
        collectionViewController.view.layoutIfNeeded()

        let _: TestCollectionReusableView = collectionView.supplementaryView(forElementKind: kind, at: .zero)
    }
}

private final class TestCollectionViewCell: UICollectionViewCell {}
private final class TestCollectionReusableView: UICollectionReusableView {}

private class TestCollectionViewController: UICollectionViewController {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: TestCollectionViewCell.reuseIdentifier,
                                                  for: indexPath)
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
        return collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: TestCollectionReusableView.reuseIdentifier,
            for: indexPath)
    }
}

private extension IndexPath {

    static var zero: IndexPath {
        return IndexPath(item: 0, section: 0)
    }
}
