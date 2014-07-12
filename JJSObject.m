#import "JJSObject.h"
#import <objc/runtime.h>



@interface JJSObject()
@property (nonatomic) NSDictionary *dataDict;
@property (nonatomic) NSCache *parsedObjectCache;
@property (nonatomic) NSDictionary *memberClasses;
@end



@implementation JJSObject


#pragma mark - Designated Initializer

+ (instancetype)withDictionary:(NSDictionary *)dict {
    JJSObject *obj = [[self alloc] init];
    obj.dataDict = dict;
    return obj;
}


#pragma mark - Lazy Instantiators

- (NSCache *)parsedObjectCache {
    if (!_parsedObjectCache) {
        _parsedObjectCache = [[NSCache alloc] init];
    }
    return _parsedObjectCache;
}

- (NSDictionary *)memberClasses {
    if (!_memberClasses) {
        _memberClasses = @{};
    }
    return _memberClasses;
}


#pragma mark Member Class Registration

- (void)registerMemberClass:(Class)c
                forSelector:(SEL)selector {
    if (c == nil || selector == nil) {
        return;
    }
    
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:self.memberClasses];
    [d setObject:c
          forKey:NSStringFromSelector(selector)];
    self.memberClasses = d.copy;
}


#pragma mark - Runtime Method Resolution

+ (BOOL)resolveInstanceMethod:(SEL)aSEL {
    NSString *selectorString = NSStringFromSelector(aSEL);
    if ([self._propertyNames containsObject:selectorString]) {
        class_addMethod([self class], aSEL, (IMP) dynamicData, "v@:");
        return YES;
    }
    return [super resolveInstanceMethod:aSEL];
}

id dynamicData(JJSObject *self, SEL _cmd) {
    // todo: not entirely happy with this large function
    
    NSString *selectorString = NSStringFromSelector(_cmd);
    
    id obj = [self.parsedObjectCache objectForKey:selectorString];
    if (obj) {
        return obj;
    }
    
    Class c = [self.class classForPropertyName:selectorString];
    Class arrayMemberClass = self.memberClasses[selectorString];
    
    if ([c isSubclassOfClass:[JJSObject class]]) {
        NSDictionary *dict = self.dataDict[selectorString];
        if (dict && [dict isKindOfClass:[NSDictionary class]]) {
            obj = [c withDictionary:dict];
            
        }
    }
    else if (arrayMemberClass &&
             c == [NSArray class]) {
        
        NSArray *dataArray = self.dataDict[selectorString];
        if (dataArray.count == 0) {
            return dataArray;
        }
        
        NSMutableArray *parsedDataArray = [NSMutableArray arrayWithCapacity:dataArray.count];
        for (NSDictionary *dict in dataArray) {
            NSParameterAssert([dict isKindOfClass:[NSDictionary class]]);
            JJSObject *jobj = [arrayMemberClass withDictionary:dict];
            [parsedDataArray addObject:jobj];
        }
        obj = parsedDataArray.copy;
    }
    else if (arrayMemberClass &&
             c == [NSDictionary class]) {
        NSDictionary *dataDict = self.dataDict[selectorString];
        if (dataDict.count == 0) {
            return dataDict;
        }
        
        NSMutableDictionary *parsedDataDict = [NSMutableDictionary dictionaryWithCapacity:dataDict.count];
        for (NSString *key in dataDict.keyEnumerator) {
            NSDictionary *dict = dataDict[key];
            JJSObject *jobj = [arrayMemberClass withDictionary:dict];
            [parsedDataDict setObject:jobj
                               forKey:key];
        }
        obj = parsedDataDict.copy;
    }

    if (obj) {
        [self.parsedObjectCache setObject:obj
                                   forKey:selectorString];
        return obj;
    }
    
    return self.dataDict[selectorString];
}


#pragma mark - Property Name Resolution

+ (Class)classForPropertyName:(NSString *)propName {
    
    objc_property_t property = class_getProperty(self, propName.UTF8String);
    
    NSString *propertyAttributeString = [NSString stringWithUTF8String:property_getAttributes(property)];
    NSArray *propAttributes = [propertyAttributeString componentsSeparatedByString:@"\""];
    if (propAttributes.count > 2) {
        return NSClassFromString(propAttributes[1]);
    }
    return nil;
}

+ (NSArray *)_propertyNames {
    NSMutableArray *props = [NSMutableArray array];
    unsigned int i;
    objc_property_t *properties = class_copyPropertyList(self, &i);
    for (unsigned int ii = 0; ii < i; ii++) {
        objc_property_t property = properties[ii];
        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        [props addObject:name];
    }
    
    free(properties);
    
    return props;
}


#pragma mark - Subscripting

- (id)objectForKeyedSubscript:(id)key {
    return self.dataDict[key];
}

@end
