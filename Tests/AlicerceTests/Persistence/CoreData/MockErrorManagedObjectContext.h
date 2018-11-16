@import CoreData;

// Sadly, this class had to be made using Obj-C because in Swift we can't override
// `count(for request: NSFetchRequest<NSFetchRequestResult>) throws -> Int`, since it makes the compiler angry:
// "throwing method cannot be an @objc override because it returns a value of type 'Int'; return 'Void' or a type that
// bridges to an Objective-C class" 😭

NS_ASSUME_NONNULL_BEGIN

@interface MockErrorManagedObjectContext : NSManagedObjectContext

@property(nullable, nonatomic, copy) NSError *mockError;

@end

NS_ASSUME_NONNULL_END
