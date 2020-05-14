

#import <Foundation/Foundation.h>
//#include "voiceEncoder.h"
#import "voiceEncoder1.h"

NS_ASSUME_NONNULL_BEGIN

@interface VSSoundWaveSender : NSObject

- (BOOL)playWiFiMac:(NSString *)wifiMac password:(NSString *)password userId:(NSString *)userId playCount:(NSInteger)playCount;

- (BOOL) isStopped;

- (void)stopPlaying;
@end

NS_ASSUME_NONNULL_END
