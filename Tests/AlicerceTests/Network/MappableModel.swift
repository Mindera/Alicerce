import Foundation
@testable import Alicerce

struct MappableModel {
    let data: String
}

extension MappableModel: Mappable {
    static func model(from object: Any) throws -> MappableModel {
        guard let dict = object as? JSON.Dictionary else {
            throw JSON.Error.unexpectedType(expected: JSON.Dictionary.self, found: type(of: object))
        }

        guard let data = dict["data"] as? String else {
            throw JSON.Error.missingAttribute("data", json: dict)
        }

        return MappableModel(data: data)
    }

    func json() -> Any {
        return ["data" : self.data]
    }
}

extension MappableModel: Equatable {
    static func ==(lhs: MappableModel, rhs: MappableModel) -> Bool {
        return lhs.data == lhs.data
    }
}
