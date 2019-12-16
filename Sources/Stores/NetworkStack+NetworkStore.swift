import Foundation

public extension NetworkStore where Self: NetworkStack, StoreError == NetworkPersistableStoreError {

    @discardableResult
    func fetch<R>(
        resource: R,
        completion: @escaping NetworkStoreFetchCompletionClosure<R.Internal, Response, StoreError>
    ) -> Cancelable
    where R: NetworkStore.FetchResource,
          R.External == Remote, R.Request == Request, R.Response == Response, R.ExternalMetadata == Response {

        let cancelable = CancelableBag()

        cancelable += fetch(resource: resource) { (result: FetchResult) in

            switch result {
            case .success(let response):
                do {
                    completion(.success(.network(try resource.decode(response.value), response.response)))
                } catch {
                    // try to extract an API error if by any reason parsing failed
                    let apiError = resource.decodeError(response.value, response.response)
                    completion(.failure(.decode(apiError ?? error)))
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
