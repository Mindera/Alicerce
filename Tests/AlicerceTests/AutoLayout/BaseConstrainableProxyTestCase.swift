import XCTest

class BaseConstrainableProxyTestCase: XCTestCase {

    private(set) var host: UIView!
    private(set) var view0: UIView!
    private(set) var view1: UIView!
    private(set) var view2: UIView!
    private(set) var view3: UIView!
    private(set) var view4: UIView!
    private(set) var view5: UIView!
    private(set) var layoutGuide: UILayoutGuide!

    override func setUp() {

        host = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))

        view0 = UIView()
        view1 = UIView()
        view2 = UIView()
        view3 = UIView()
        view4 = UIView()
        view5 = UIView()

        layoutGuide = UILayoutGuide()

        host.addSubview(view0)
        host.addSubview(view1)
        host.addSubview(view2)
        host.addSubview(view3)
        host.addSubview(view4)
        host.addSubview(view5)

        host.addLayoutGuide(layoutGuide)

        super.setUp()
    }

    override func tearDown() {

        view5 = nil
        view4 = nil
        view3 = nil
        view2 = nil
        view1 = nil
        view0 = nil

        host = nil

        layoutGuide = nil

        super.tearDown()
    }
}
