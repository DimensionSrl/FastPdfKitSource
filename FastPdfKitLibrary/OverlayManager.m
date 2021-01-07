//
//  OverlayManager.m
//  SampleProject
//

#import "OverlayManager.h"

@implementation OverlayManager

- (FPKOverlayManager *)init
{
	self = [super init];
	if (self != nil)
	{
        // Add Extensions to the array. Alternatively, use -initWithExtension:
		[self setExtensions:[[NSArray alloc] initWithObjects:@"FPKGallerySlide", @"FPKGalleryTap", @"FPKMap", @"FPKYouTube", @"FPKGalleryFade", @"FPKConfig", nil]];
	}
	return self;
}

@end
