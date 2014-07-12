An abstract class that both acts as a wrapper around NSDictionary for data,
and can also dynamically parse relations to other JJSObject subclasses from such data.

```
Let's say we have the following data:
{
	"firstName" : "Jon",
	"lastName" : "Doe",
	"photo" : {
							"thumb44" : "http://url.to.file/44.jpg",
							"thumb300" : "http://url.to.file/300.jpg"
						}
}
```

We can define objects such as 

```
@interface Photo : JJSObject
@property (nonatomic, readonly) NSString *thumb44;
@property (nonatomic, readonly) NSString *thumb300;
@end

@implementation Photo 
@dynamic thumb44;
@dynamic thumb300;
@end


@interface Person : JJSObject
@property (nonatomic, readonly) NSString *firstName;
@property (nonatomic, readonly) NSString *lastName;
@property (nonatomic, readonly) Photo *photo;
@end

@implementation Person
@dynamic firstName;
@dynamic lastName;
@dynamic Photo;
@end
```

Now we can instantiate these related instances by passing the NSDictionary to the root:
```
Person *p = [Person withDictionary:dataDict];
NSLog(@"%@", p.firstName);
NSLog(@"%@", p.lastName);
NSLog(@"%@", p.photo.thumb44);
```

Let's say, a Person has friends:

```
{
  "firstName" : "Jon",
  "friends" : [
               {"firstName" : "Jill", ...},
               {"firstName" : "James", ...},
               {"firstName" : "Julie", ...},
               {"firstName" : "Joseph", ...},
              ]
}
```

We can explicitly express our desire to have the members of the "friends" array parsed as Person instances like so:

```
@interface Person : JJSObject
@property (nonatomic, readonly) NSString *firstName;
@property (nonatomic, readonly) NSArray *friends;
@end

@implementation Person : JJSObject
- (instancetype)init {
	self = [super init];

	[self registerMemberClass:[Person class]
						    forSelector:@selector(friends)];

	return self;
}
@end
```

and we can then do something like
```
Person *p = [Person withDictionary:dataDict];
NSLog(@"%@ is %@'s first friend." , ((Person *)p.friends.firstObject).firstName, p.firstName);
```




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