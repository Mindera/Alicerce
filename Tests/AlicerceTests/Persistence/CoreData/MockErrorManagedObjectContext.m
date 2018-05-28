#import "MockErrorManagedObjectContext.h"

@implementation MockErrorManagedObjectContext

- (BOOL)shouldThrowMockError:(NSError**)error {
    if (error != NULL && self.mockError){
        *error = self.mockError.copy;
        return YES;
    }
    return NO;
}

- (nullable __kindof NSManagedObject *)existingObjectWithID:(NSManagedObjectID*)objectID error:(NSError**)error {
    if ([self shouldThrowMockError:error]) {
        return nil;
    }

    return [super existingObjectWithID:objectID error:error];
}

- (nullable NSArray *)executeFetchRequest:(NSFetchRequest *)request error:(NSError **)error {
    if ([self shouldThrowMockError:error]) {
        return nil;
    }

    return [super executeFetchRequest:request error:error];
}

- (NSUInteger) countForFetchRequest: (NSFetchRequest *)request error: (NSError **)error {
    if ([self shouldThrowMockError:error]) {
        return NSNotFound;
    }

    return [super countForFetchRequest:request error:error];
}

- (nullable __kindof NSPersistentStoreResult *)executeRequest:(NSPersistentStoreRequest*)request error:(NSError **)error {
    if ([self shouldThrowMockError:error]) {
        return nil;
    }

    return [super executeRequest:request error:error];
}

- (BOOL)obtainPermanentIDsForObjects:(NSArray<NSManagedObject *> *)objects error:(NSError **)error {
    if ([self shouldThrowMockError:error]) {
        return NO;
    }

    return [super obtainPermanentIDsForObjects:objects error:error];
}


- (BOOL)save:(NSError **)error {
    if ([self shouldThrowMockError:error]) {
        return NO;
    }

    return [super save:error];
}


@end
