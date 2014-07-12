#import <Foundation/Foundation.h>


/**
 Automatically parses fields where the property name and json key match,
 let's assume an object User : JJSObject

 ####
 #  // Interface Property Declaration
 #  @property (nonatomic, readonly) NSString *firstName;
 #
 #  // Json
 #  {"firstName" : "Jon"}
 ####
 
 
 If you have a relation to another JJSObject, just declare the property as such,
 parsing will happen automatically. Let's assume the same User object from above,
 but we've also defined an additional class Photo : JJSObject.

 ####
 #  // Interface Property Declaration
 #  @property (nonatomic, readonly) Photo *userPhoto;
 #
 #  // Json
 #  {
 #   "firstName" : "Jon",
 #   "userPhoto" : {
 #                  "thumb44" : "http://some.url.com/path/to/file_44.jpg",
 #                  "thumb600" : "http://some.url.com/path/to/file_600.jpg"
 #                  }
 #  }
 ####
 
 
 Let's say we have a to-many relationship, such as a user and his friends:
 
 ####
 #  // Interface Property Declaration
 #  @property (nonatomic, readonly) NSArray *friends;
 #
 #  // Json
 #  {
 #   "firstName" : "Jon",
 #   "userPhoto" : {
 #                  "thumb44" : "http://some.url.com/path/to/file_44.jpg",
 #                  "thumb600" : "http://some.url.com/path/to/file_600.jpg"
 #                  },
 #   "friends" : [
 #                {"firstName" : ...},
 #                {"firstName" : ...},
 #                {"firstName" : ...},
 #                {"firstName" : ...},
 #               ]
 #  }
 ####
 
 We will need to explicitly express our desire to have the objects parsed 
 rather than returned as instances of NSDictionary. Since NSArray cannot carry type 
 information regarding its members, JJSObject has a mechanism to "register" a member class
 for a specific selector.
 
 ####
 #  // Implementation of User
 #  - (instancetype)init {
 #      self = [super init];
 #      [self registerMemberClass:[User class]
 #                    forSelector:@selector(friends)];
 #  }
 ####
 
 
 TODO: Conform to NSCopying
 */



@interface JJSObject : NSObject

/**
 * Designated Initializer
 */
+ (instancetype)withDictionary:(NSDictionary *)dict;


- (id)objectForKeyedSubscript:(id)key;

/**
 * @discussion Use this to have properties for NSArray and NSDictionary return
 * a respective instance which contains parsed JJSObjects.
 */
- (void)registerMemberClass:(Class)c
                forSelector:(SEL)selector;

@end
