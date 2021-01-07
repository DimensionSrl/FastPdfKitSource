//
//  FPKConfigurationJSONLoader.m
//  FastPdfKitLibrary
//
//  Created by Nicolo' on 13/06/14.
//
//

#import "FPKConfigurationLoader.h"
#import "MFDocumentViewController.h"
@implementation FPKConfigurationLoader

+(NSDictionary *)configurationDictionaryWithJSONFile:(NSString *)path
{
    if(path.length > 0)
    {
    NSData * data = [NSData dataWithContentsOfFile:path];
    if(data.length > 0)
    {
    NSError * __autoreleasing error = nil;
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if(obj)
    {
    if([obj isKindOfClass:[NSDictionary class]])
    {
        return (NSDictionary *)obj;
    }
    else if ([obj isKindOfClass:[NSArray class]])
    {
        return @{FPKConfigurationDictionaryConfigKey:obj};
    }
        NSLog(@"%@",error);
    }
    }
    }
    return nil;
}

+(NSDictionary *)configurationDictionaryWithXMLFile:(NSString *)path
{
    return nil;
}

+(NSDictionary *)configurationDictionaryWithPlistFile:(NSString *)path
{
     return nil;
}

@end
