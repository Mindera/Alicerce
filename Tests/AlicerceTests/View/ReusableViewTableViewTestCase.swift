//
//  ReusableViewTableViewTestCase.swift
//  AlicerceTests
//
//  Created by André Pacheco Neves on 20/11/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import XCTest
import UIKit
@testable import Alicerce

class ReusableViewTableViewTestCase: XCTestCase {

    private var tableViewController: TestTableViewController!
    private var tableView: UITableView! { return tableViewController.tableView }

    override func setUp() {
        super.setUp()

        tableViewController = TestTableViewController()
    }

    override func tearDown() {
        tableViewController = nil

        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // MARK: register

    func testRegister_WithTableViewCell_ShouldSucceedl() {
        tableView.register(TestTableViewCell.self)

        let cell = tableView.dequeueReusableCell(withIdentifier: TestTableViewCell.reuseIdentifier, for: .zero)

        guard let _ = cell as? TestTableViewCell else {
            return XCTFail("unexpected cell type!")
        }
    }

    func testRegister_WithTableReusableView_ShouldSucceedl() {
        tableView.registerHeaderFooterView(TestTableViewHeaderView.self)
        tableView.registerHeaderFooterView(TestTableViewFooterView.self)

        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: TestTableViewHeaderView.reuseIdentifier)

        let footer = tableView.dequeueReusableHeaderFooterView(withIdentifier: TestTableViewFooterView.reuseIdentifier)

        guard let _ = header as? TestTableViewHeaderView else {
            return XCTFail("unexpected header view type!")
        }

        guard let _ = footer as? TestTableViewFooterView else {
            return XCTFail("unexpected footer view type!")
        }
    }

    // MARK: dequeue

    func testDequeue_WithTableViewCell_ShouldSucceed() {
        tableView.register(TestTableViewCell.self, forCellReuseIdentifier: TestTableViewCell.reuseIdentifier)

        let _: TestTableViewCell = tableView.dequeueCell(for: .zero)
    }

    func testDequeue_WithTableReusableView_ShouldSucceed() {
        tableView.register(TestTableViewHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: TestTableViewHeaderView.reuseIdentifier)
        tableView.register(TestTableViewFooterView.self,
                           forHeaderFooterViewReuseIdentifier: TestTableViewFooterView.reuseIdentifier)

        let _: TestTableViewHeaderView = tableView.dequeueHeaderFooterView()
        let _: TestTableViewFooterView = tableView.dequeueHeaderFooterView()
    }

    // MARK: cell

    func testCell_withRegisteredTableViewCell_ShouldSucceed() {
        tableView.register(TestTableViewCell.self, forCellReuseIdentifier: TestTableViewCell.reuseIdentifier)

        // force the tableView to draw itself
        tableViewController.view.layoutIfNeeded()

        let _: TestTableViewCell = tableView.cell(for: .zero)
    }

    // MARK: headerView

    func testHeaderView_WithRegisteredHeaderFooterView() {
        // we always have to register a cell so that the section isn't empty 🤷‍♂️
        tableView.register(TestTableViewCell.self, forCellReuseIdentifier: TestTableViewCell.reuseIdentifier)

        tableView.register(TestTableViewHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: TestTableViewHeaderView.reuseIdentifier)

        // force the tableView to draw itself
        tableViewController.view.layoutIfNeeded()

        let _: TestTableViewHeaderView = tableView.headerView(forSection: 0)
    }

    // MARK: footerView

    func testFooterView_WithRegisteredHeaderFooterView() {
        // we always have to register a cell so that the section isn't empty 🤷‍♂️
        tableView.register(TestTableViewCell.self, forCellReuseIdentifier: TestTableViewCell.reuseIdentifier)

        tableView.register(TestTableViewFooterView.self,
                           forHeaderFooterViewReuseIdentifier: TestTableViewFooterView.reuseIdentifier)

        // force the tableView to draw itself
        tableViewController.view.layoutIfNeeded()

        let _: TestTableViewFooterView = tableView.footerView(forSection: 0)
    }
}

private final class TestTableViewCell: UITableViewCell {}
private final class TestTableViewHeaderView: UITableViewHeaderFooterView {}
private final class TestTableViewFooterView: UITableViewHeaderFooterView {}

private class TestTableViewController: UITableViewController {

    override func numberOfSections(in tableView: UITableView) -> Int { return 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return 1 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: TestTableViewCell.reuseIdentifier, for: indexPath)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: TestTableViewHeaderView.reuseIdentifier)
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(withIdentifier: TestTableViewFooterView.reuseIdentifier)
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { return 1 }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return 1 }
}

private extension IndexPath {

    static var zero: IndexPath {
        return IndexPath(item: 0, section: 0)
    }
}

