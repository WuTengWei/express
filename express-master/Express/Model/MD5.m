

#import "MD5.h"
#import <CommonCrypto/CommonDigest.h>

@implementation MD5

+(NSString *)md5String:(NSString *)sourceString{
    if (!sourceString) {
        return nil;
    }
    const char *cString = sourceString.UTF8String;
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    NSMutableString *resultString = [[NSMutableString alloc]init];
    CC_MD5(cString,(CC_LONG)strlen(cString),result);
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [resultString appendFormat:@"%02x",result[i]];
    }
    return resultString;
}

@end
