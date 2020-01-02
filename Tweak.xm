// DarkShot, by Skity
// Darken the screenshot flash color!

#include <IOKit/hid/IOHIDEventSystem.h>
#include <IOKit/hid/IOHIDEventSystemClient.h>

extern "C" {
	int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
	CFArrayRef IOHIDEventSystemClientCopyServices(IOHIDEventSystemClientRef);
	IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
	typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;
	int IOHIDServiceClientSetProperty(IOHIDServiceClientRef, CFStringRef, CFNumberRef);
}

@interface SSBlurringFlashView : UIView
@end

void handle_event(void* target, void* refcon, IOHIDEventQueueRef queue, IOHIDEventRef event);
void init_iokit();
void start_iokit();
void stop_iokit();

static NSMutableDictionary *settings;
static BOOL enabled;
static BOOL darkMode;
static BOOL ambientLight;
static int luxThreshold;

static int currentLux;
static IOHIDEventSystemClientRef ioHIDClient;
static CFRunLoopRef ioHIDRunLoopSchedule;

// Preference Updates
static void refreshPrefs() {
	CFArrayRef keyList = CFPreferencesCopyKeyList(CFSTR("xyz.skitty.darkshot"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (keyList) {
		settings = (NSMutableDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, CFSTR("xyz.skitty.darkshot"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
		CFRelease(keyList);
	} else {
		settings = nil;
	}
	if (!settings) {
		settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/xyz.skitty.darkshot.plist"];
	}

	int oldAmbientLight = ambientLight;

	enabled = [([settings objectForKey:@"enabled"] ?: @(YES)) boolValue];
	darkMode = [([settings objectForKey:@"darkMode"] ?: @(YES)) boolValue];
	ambientLight = [([settings objectForKey:@"ambientLight"] ?: @(YES)) boolValue];
	luxThreshold = [([settings objectForKey:@"luxThreshold"] ?: @50) intValue];

	if (ambientLight)
		start_iokit();
	else if (oldAmbientLight)
		stop_iokit();
}

static void PreferencesChangedCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
  refreshPrefs();
}

// Actual hook!
%hook SSBlurringFlashView
- (void)flashWithCompletion:(id)arg1 {
	if (enabled) {
		BOOL darkEnabled = (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);

		//NSLog(@"[DarkShot] Debug: dark mode?: %d, use dark mode?: %d, use ambient mode?: %d, lux?: %d, enabled?: %d", darkEnabled, darkMode, ambientLight, currentLux, enabled);

		if ((darkMode && darkEnabled) || (ambientLight && currentLux < luxThreshold)) {
			MSHookIvar<UIView *>(self, "_superColorView").backgroundColor = [UIColor blackColor];
			self.backgroundColor = [UIColor blackColor];
			[UIView animateWithDuration:1.0 animations:^{
				self.backgroundColor = [UIColor clearColor];
			} completion:nil];
		}
	}
	%orig;
}
%end

// Ambient Light Sensor
void handle_event(void* target, void* refcon, IOHIDEventQueueRef queue, IOHIDEventRef event) {
	if (IOHIDEventGetType(event) == kIOHIDEventTypeAmbientLightSensor) {
		currentLux = IOHIDEventGetIntegerValue(event, (IOHIDEventField)kIOHIDEventFieldAmbientLightSensorLevel);
	}
}

void init_iokit() {
	ioHIDRunLoopSchedule = CFRunLoopGetMain();

	int pv1 = 0xff00;
	int pv2 = 4;
	CFNumberRef vals[2];
	CFStringRef keys[2];

	vals[0] = CFNumberCreate(CFAllocatorGetDefault(), kCFNumberSInt32Type, &pv1);
	vals[1] = CFNumberCreate(CFAllocatorGetDefault(), kCFNumberSInt32Type, &pv2);
	keys[0] = CFStringCreateWithCString(0, "PrimaryUsagePage", 0);
	keys[1] = CFStringCreateWithCString(0, "PrimaryUsage", 0);

	CFDictionaryRef matchInfo = CFDictionaryCreate(CFAllocatorGetDefault(),(const void**)keys,(const void**)vals, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

	ioHIDClient = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
	IOHIDEventSystemClientSetMatching(ioHIDClient, matchInfo);

	CFArrayRef matchingsrvs = IOHIDEventSystemClientCopyServices(ioHIDClient);

	if (CFArrayGetCount(matchingsrvs) != 0) {
		IOHIDServiceClientRef alssc = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(matchingsrvs, 0);

		int ri = 1 * 1000000;
		CFNumberRef interval = CFNumberCreate(CFAllocatorGetDefault(), kCFNumberIntType, &ri);
		IOHIDServiceClientSetProperty(alssc, CFSTR("ReportInterval"), interval);
	}
}

void start_iokit() {
	if (ioHIDClient) {
		IOHIDEventSystemClientScheduleWithRunLoop(ioHIDClient, ioHIDRunLoopSchedule, kCFRunLoopDefaultMode);
		IOHIDEventSystemClientRegisterEventCallback(ioHIDClient, handle_event, NULL, NULL);
	}
}

void stop_iokit() {
	if (ioHIDClient) {
		currentLux = 1000;
		IOHIDEventSystemClientUnregisterEventCallback(ioHIDClient);
		IOHIDEventSystemClientUnscheduleWithRunLoop(ioHIDClient, ioHIDRunLoopSchedule, kCFRunLoopDefaultMode);
	}
}

// Tweak setup
%ctor {
	init_iokit();
	
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback) PreferencesChangedCallback, CFSTR("xyz.skitty.darkshot.prefschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	refreshPrefs();

	%init;
}

%dtor {
	stop_iokit();
}
