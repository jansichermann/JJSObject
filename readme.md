An abstract class that both acts as a wrapper around NSDictionary for data,
and can also dynamically parse relations to other JJSObject subclasses from such data.

Let's say we have the following data:
```
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