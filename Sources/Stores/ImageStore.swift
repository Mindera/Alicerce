//
//  ImageStore.swift
//  Alicerce
//
//  Created by Luís Portela on 24/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public class ImageStore: NetworkPersistableStore {

    @discardableResult
    public override func fetch<Resource: NetworkResource & PersistableResource & StrategyFetchResource>(
        resource: Resource,
        completion: @escaping StoreCompletionClosure<Resource.Local>)
        -> Alicerce.Cancelable
    where Resource.Remote == Data, Resource.Local == UIImage {
        return super.fetch(resource: resource, completion: completion)
    }
}
