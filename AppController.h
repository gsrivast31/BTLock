#import <Cocoa/Cocoa.h>
#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>

typedef enum _BPStatus {
	InRange,
	OutOfRange
} BPStatus;

@interface AppController : NSObject
{
	IOBluetoothDevice *device;
	NSTimer *timer;
	BPStatus priorStatus;
	NSStatusItem *statusItem;
	
    IBOutlet id deviceName;
    IBOutlet id monitoringEnabled;
    IBOutlet id prefsWindow;
    IBOutlet id progressIndicator;
    IBOutlet id runScriptsOnStartup;
    IBOutlet id timerInterval;
}

// AppController methods
- (void)createMenuBar;
- (void)userDefaultsLoad;
- (void)userDefaultsSave;
- (BOOL)isInRange;
- (void)runInRangeScript;
- (void)runOutOfRangeScript;
- (void)startMonitoring;
- (void)stopMonitoring;


// UI methods
- (IBAction)changeDevice:(id)sender;
- (IBAction)checkConnectivity:(id)sender;
- (IBAction)showWindow:(id)sender;

@end
