//
//  UICollectionView.swift
//  Alicerce
//
//  Created by Luís Afonso on 16/12/2016.
//  Copyright © 2016 Mindera. All rights reserved.
//

import UIKit

public extension UICollectionView {
    
    public func cell<T: ViewCellProtocol>(`for` indexPath: IndexPath) -> T {
        guard let cell = self.dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            assertionFailure("🔥 Did you forgot to register cell with identifier `\(T.reuseIdentifier)` for type: `\(T.self)`")
            return T()
        }
        
        return cell
    }
    
    public func register<T: UICollectionViewCell>(_ cellType: T.Type) where T: ViewCellProtocol {
        register(cellType, forCellWithReuseIdentifier: cellType.reuseIdentifier)
    }
    
    public func register<T: AnyObject>(_ viewType: T.Type, forSupplementaryViewOfKind kind: String) where T: ViewCellProtocol {
        register(viewType, forSupplementaryViewOfKind: kind, withReuseIdentifier: viewType.reuseIdentifier)
    }
}
