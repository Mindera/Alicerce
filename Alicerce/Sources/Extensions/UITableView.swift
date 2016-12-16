//
//  UITableView.swift
//  Alicerce
//
//  Created by Luís Afonso on 16/12/2016.
//  Copyright © 2016 Mindera. All rights reserved.
//

import UIKit

extension UITableView {
    
    func cell<T: ViewCellProtocol>(`for` indexPath: IndexPath) -> T {
        guard let cell = self.dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            assertionFailure("🔥 Did you forgot to register cell with identifier `\(T.reuseIdentifier)` for type: `\(T.self)`")
            return T()
        }
        
        return cell
    }
    
    func headerView<T: TableViewProtocol>() -> T {
        guard let view = self.dequeueReusableHeaderFooterView(withIdentifier: T.reuseIdentifier) as? T else {
            assertionFailure("🔥 Did you forgot to register view with identifier `\(T.reuseIdentifier)` for type: `\(T.self)`")
            return T()
        }
        
        return view
    }
}
