//
//  NSLayoutConstraintTestCase.swift
//  AlicerceTests
//
//  Created by Tiago Veloso on 17/02/2018.
//  Copyright © 2018 Mindera. All rights reserved.
//

import XCTest

@testable import Alicerce

class UIViewConstraintTestCase: XCTestCase {

    var superview: UIView!

    var view1: UIView!
    var view2: UIView!

    override func setUp() {
        super.setUp()

        superview = UIView()

        view1 = UIView()
        view2 = UIView()

        superview.addSubview(view1)
        superview.addSubview(view2)
    }

    override func tearDown() {
        super.tearDown()

        superview = nil
        view1 = nil
        view2 = nil
    }

    func test_translatesAutoresizingMaskIntoConstraints_is_false() {

        UIView.activateConstraints([
            view1.topAnchor.constraint(equalTo: superview.topAnchor),
            view2.topAnchor.constraint(equalTo: view1.topAnchor),
            view2.bottomAnchor.constraint(equalTo: superview.bottomAnchor)
            ])

        XCTAssert(view1.translatesAutoresizingMaskIntoConstraints == false)
        XCTAssert(view2.translatesAutoresizingMaskIntoConstraints == false)
    }

    func test_left_adds_constraine() {

        XCTAssert(superview.constraints.count == 0)

        view1.left(ofView: view2)

        XCTAssert(superview.constraints.count == 1)
    }

    func test_right_adds_constraine() {

        XCTAssert(superview.constraints.count == 0)

        view1.right(ofView: view2)

        XCTAssert(superview.constraints.count == 1)
    }

    func test_top_adds_constraine() {

        XCTAssert(superview.constraints.count == 0)

        view1.top(ofView: view2)

        XCTAssert(superview.constraints.count == 1)
    }

    func test_bottom_adds_constraine() {

        XCTAssert(superview.constraints.count == 0)

        view1.bottom(ofView: view2)

        XCTAssert(superview.constraints.count == 1)
    }

    func test_center_adds_constraine() {

        XCTAssert(superview.constraints.count == 0)

        view1.center(inView: view2)

        XCTAssert(superview.constraints.count == 2)
    }

    func test_edges_adds_constraine() {

        XCTAssert(superview.constraints.count == 0)

        view1.edges(toView: view2)

        XCTAssert(superview.constraints.count == 4)
    }

}
