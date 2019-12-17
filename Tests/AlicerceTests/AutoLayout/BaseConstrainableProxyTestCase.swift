import XCTest

class BaseConstrainableProxyTestCase: XCTestCase {

    private(set) var host: UIView!
    private(set) var view: UIView!

    override func setUp() {

        host = UIView(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        view = UIView()
        host.addSubview(view)

        super.setUp()
    }

    override func tearDown() {

        view = nil
        host = nil

        super.tearDown()
    }
}
