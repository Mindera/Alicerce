import XCTest
import UIKit
@testable import Alicerce

class ReusableViewCollectionViewTestCase: XCTestCase {

    private var collectionViewController: TestCollectionViewController!
    private var collectionView: UICollectionView! { return collectionViewController.collectionView }
    private var collectionViewLayout: UICollectionViewFlowLayout! {
        return (collectionView.collectionViewLayout as! UICollectionViewFlowLayout)
    }

    override func setUp() {
        super.setUp()

        collectionViewController = TestCollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
    }

    override func tearDown() {
        collectionViewController = nil

        super.tearDown()
    }

    // MARK: register

    func testRegister_WithCollectionViewCell_ShouldSucceedl() {
        collectionView.register(TestCollectionViewCell.self)
		collectionView.register(TestNIBCollectionViewCell.self)

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TestCollectionViewCell.reuseIdentifier,
                                                      for: .zero)
		let nibCell = collectionView.dequeueReusableCell(withReuseIdentifier: TestNIBCollectionViewCell.reuseIdentifier,
													  for: .zero)

        guard let _ = cell as? TestCollectionViewCell else {
            return XCTFail("unexpected cell type!")
        }

		guard let _ = nibCell as? TestNIBCollectionViewCell else {
			return XCTFail("unexpected cell type!")
		}
    }

    func testRegister_WithCollectionReusableView_ShouldSucceedl() {
        let kind = UICollectionView.elementKindSectionHeader

        // we always have to register and dequeue a cell so that the section isn't empty 🤷‍♂️
        collectionView.register(TestCollectionViewCell.self, forCellWithReuseIdentifier: "🔨🐒")
		collectionView.register(TestNIBCollectionViewCell.self, forCellWithReuseIdentifier: "🔨🐒👷‍♂️")

        let _ = collectionView.dequeueReusableCell(withReuseIdentifier: "🔨🐒", for: .zero)
		let _ = collectionView.dequeueReusableCell(withReuseIdentifier: "🔨🐒👷‍♂️", for: .one)

        collectionView.register(TestCollectionReusableView.self, forSupplementaryViewOfKind: kind)
		collectionView.register(TestNIBCollectionReusableView.self, forSupplementaryViewOfKind: kind)

        let view = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: TestCollectionReusableView.reuseIdentifier,
            for: .zero)

		let nibView = collectionView.dequeueReusableSupplementaryView(
			ofKind: kind,
			withReuseIdentifier: TestNIBCollectionReusableView.reuseIdentifier,
			for: .zero)

        guard let _ = view as? TestCollectionReusableView else {
            return XCTFail("unexpected view type!")
        }

		guard let _ = nibView as? TestNIBCollectionReusableView else {
			return XCTFail("unexpected view type!")
		}
    }

    // MARK: dequeue

    func testDequeue_WithCollectionViewCell_ShouldSucceed() {
        collectionView.register(TestCollectionViewCell.self,
                                forCellWithReuseIdentifier: TestCollectionViewCell.reuseIdentifier)
		collectionView.register(TestNIBCollectionViewCell.self,
								forCellWithReuseIdentifier: TestNIBCollectionViewCell.reuseIdentifier)

        let _: TestCollectionViewCell = collectionView.dequeueCell(for: .zero)
		let _: TestNIBCollectionViewCell = collectionView.dequeueCell(for: .one)
    }

    func testDequeue_WithCollectionReusableView_ShouldSucceed() {
        let kind = UICollectionView.elementKindSectionHeader

        // we always have to register and dequeue a cell so that the section isn't empty 🤷‍♂️
        collectionView.register(TestCollectionViewCell.self, forCellWithReuseIdentifier: "🔨🐒")
		collectionView.register(TestNIBCollectionViewCell.self, forCellWithReuseIdentifier: "🔨🐒👷‍♂️")

        let _ = collectionView.dequeueReusableCell(withReuseIdentifier: "🔨🐒", for: .zero)
		let _ = collectionView.dequeueReusableCell(withReuseIdentifier: "🔨🐒👷‍♂️", for: .one)

        collectionView.register(TestCollectionReusableView.self, forSupplementaryViewOfKind: kind)
		collectionView.register(TestNIBCollectionReusableView.self, forSupplementaryViewOfKind: kind)

        let _: TestCollectionReusableView = collectionView.dequeueSupplementaryView(forElementKind: kind, at: .zero)
		let _: TestCollectionReusableView = collectionView.dequeueSupplementaryView(forElementKind: kind, at: .one)
    }

    // MARK: cell

    func testCell_withRegisteredCollectionViewCell_ShouldSucceed() {
        collectionView.register(TestCollectionViewCell.self,
                                forCellWithReuseIdentifier: TestCollectionViewCell.reuseIdentifier)
		collectionView.register(TestNIBCollectionViewCell.self,
								forCellWithReuseIdentifier: TestNIBCollectionViewCell.reuseIdentifier)

        // force the collectionView to draw itself
        collectionViewController.view.layoutIfNeeded()

        let _: TestCollectionViewCell = collectionView.cell(for: .zero)
		let _: TestNIBCollectionViewCell = collectionView.cell(for: .one)
    }

    // MARK: supplementaryView

    func testSupplementaryView_WithRegisteredSupplementaryView() {
        let kind = UICollectionView.elementKindSectionHeader

        // we always have to register and dequeue a cell so that the section isn't empty 🤷‍♂️
        collectionView.register(TestCollectionViewCell.self,
                                forCellWithReuseIdentifier: TestCollectionViewCell.reuseIdentifier)
		collectionView.register(TestNIBCollectionViewCell.self,
								forCellWithReuseIdentifier: TestNIBCollectionViewCell.reuseIdentifier)

        collectionView.register(TestCollectionReusableView.self,
                                forSupplementaryViewOfKind: kind,
                                withReuseIdentifier: TestCollectionReusableView.reuseIdentifier)
		collectionView.register(TestNIBCollectionReusableView.self,
								forSupplementaryViewOfKind: kind,
								withReuseIdentifier: TestNIBCollectionReusableView.reuseIdentifier)

        // give non zero size for supplementary view do be dequeued
        collectionViewLayout.headerReferenceSize = CGSize(width: 1, height: 1)

        // force the collectionView to draw itself
        collectionViewController.view.layoutIfNeeded()

        let _: TestCollectionReusableView = collectionView.supplementaryView(forElementKind: kind, at: .zero)
		let _: TestNIBCollectionReusableView = collectionView.supplementaryView(forElementKind: kind, at: .one)
    }
}

private final class TestCollectionViewCell: UICollectionViewCell {}
private final class TestCollectionReusableView: UICollectionReusableView {}

private class TestCollectionViewController: UICollectionViewController {

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		switch indexPath {
		case .zero:
			return collectionView.dequeueReusableCell(withReuseIdentifier: TestCollectionViewCell.reuseIdentifier,
													  for: indexPath)
		default:
			return collectionView.dequeueReusableCell(withReuseIdentifier: TestNIBCollectionViewCell.reuseIdentifier,
													  for: indexPath)
		}
    }

    override func collectionView(_ collectionView: UICollectionView,
                                 viewForSupplementaryElementOfKind kind: String,
                                 at indexPath: IndexPath) -> UICollectionReusableView {
		switch indexPath {
		case .zero:
			return collectionView.dequeueReusableSupplementaryView(
				ofKind: kind,
				withReuseIdentifier: TestCollectionReusableView.reuseIdentifier,
				for: indexPath)
		default:
			return collectionView.dequeueReusableSupplementaryView(
				ofKind: kind,
				withReuseIdentifier: TestNIBCollectionReusableView.reuseIdentifier,
				for: indexPath)
		}
    }
}

private extension IndexPath {

    static var zero: IndexPath {
        return IndexPath(item: 0, section: 0)
    }

	static var one: IndexPath {
		return IndexPath(item: 0, section: 1)
	}
}
