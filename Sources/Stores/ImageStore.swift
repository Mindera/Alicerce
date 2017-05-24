//
//  ImageStore.swift
//  Alicerce
//
//  Created by Luís Portela on 24/05/2017.
//  Copyright © 2017 Mindera. All rights reserved.
//

import Foundation

public class ImageStore: NetworkPersistableStore {

    public override func fetch<Resource>(resource: Resource,
                                         _ completion: @escaping StoreCompletionClosure<Resource.T>)
    -> Alicerce.Cancelable
    where Resource: NetworkResource & PersistableResource, Resource.F == Data, Resource.T == UIImage {
        return super.fetch(resource: resource, completion)
    }
}
