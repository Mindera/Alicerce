import Foundation

public extension NetworkStore
where Self: NetworkStack, E == NetworkPersistableStoreError {

    @discardableResult
    func fetch<R>(resource: R, completion: @escaping NetworkStoreCompletionClosure<R.Internal, E>) -> Cancelable
        where R: NetworkStore.FetchResource,
        R.External == Remote, R.Request == Request, R.Response == Response, R.ExternalMetadata == Response {

            let cancelable = CancelableBag()

            cancelable += fetch(resource: resource) { (result: Result<Network.Value<R.External>, Network.Error>) in

                switch result {
                case .success(let response):
                    do {
                        completion(.success(.network(try resource.decode(response.value), response.response)))
                    } catch let error as Parse.Error {
                        completion(.failure(.parse(error)))
                    } catch {
                        completion(.failure(.other(error)))
                    }
                case .failure(let error) where cancelable.isCancelled:
                    completion(.failure(.cancelled(error)))
                case .failure(let error):
                    completion(.failure(.network(error)))
                }
            }

            return cancelable
    }
}

extension Network.URLSessionNetworkStack: NetworkStore {
    public typealias E = NetworkPersistableStoreError
}
