#import "AppController.h"


@implementation AppController


#pragma mark -
#pragma mark Delegate Methods

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[self stopMonitoring];
}

- (void)awakeFromNib
{
	priorStatus = OutOfRange;
	
	[self createMenuBar];
	[self userDefaultsLoad];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[self userDefaultsSave];
	[self stopMonitoring];
	[self startMonitoring];
}


#pragma mark -
#pragma mark AppController Methods

- (void)createMenuBar
{
	NSMenu *myMenu;
	NSMenuItem *menuItem;
	 
	// Menu for status bar item
	myMenu = [[NSMenu alloc] init];
	
	// Prefences menu item
	menuItem = [myMenu addItemWithTitle:@"Preferences" action:@selector(showWindow:) keyEquivalent:@""];
	[menuItem setTarget:self];
	
	// Quit menu item
	[myMenu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
	
	// Space on status bar
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[statusItem retain];
	
	// Attributes of space on status bar
	[statusItem setHighlightMode:YES];
	[statusItem setMenu:myMenu];

	[statusItem setImage:[[NSImage alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource: @"lock" ofType: @"png"]]];
}

- (void)handleTimer:(NSTimer *)theTimer
{
    if( [self isInRange] ) {
		if( priorStatus == OutOfRange ) {
			priorStatus = InRange;
			[self runInRangeScript];
		}
	}
	else {
		if( priorStatus == InRange ) {
			priorStatus = OutOfRange;
			[self runOutOfRangeScript];
		}
	}
	
    [self startMonitoring];
}

- (BOOL)isInRange
{
	if( device && [device remoteNameRequest:nil] == kIOReturnSuccess )
		return true;
	
	return false;
}

- (void)runInRangeScript
{
	NSAppleScript *script;
	NSDictionary *errDict;
	NSAppleEventDescriptor *ae;
	
    NSString* inRangeScriptPath = [[NSBundle mainBundle] pathForResource: @"inrange" ofType: @"scpt"];
	script = [[NSAppleScript alloc]
			  initWithContentsOfURL:[NSURL fileURLWithPath:inRangeScriptPath]
			  error:&errDict];
	ae = [script executeAndReturnError:&errDict];		
}

- (void)runOutOfRangeScript
{
	NSAppleScript *script;
	NSDictionary *errDict;
	NSAppleEventDescriptor *ae;
	
    NSString* outOfRangeScriptPath = [[NSBundle mainBundle] pathForResource: @"outofrange" ofType: @"scpt"];
    script = [[NSAppleScript alloc]
			  initWithContentsOfURL:[NSURL fileURLWithPath:outOfRangeScriptPath]
			  error:&errDict];
	ae = [script executeAndReturnError:&errDict];	
}

- (void)startMonitoring
{
	if( [monitoringEnabled state] == NSOnState )
	{
		timer = [NSTimer scheduledTimerWithTimeInterval:[timerInterval intValue]
												 target:self
											   selector:@selector(handleTimer:)
											   userInfo:nil
												repeats:NO];
		[timer retain];
	}		
}

- (void)stopMonitoring
{
	[timer invalidate];
}

- (void)userDefaultsLoad
{
	NSUserDefaults *defaults;
	NSData *deviceAsData;
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	// Device
	deviceAsData = [defaults objectForKey:@"device"];
	if( [deviceAsData length] > 0 )
	{
		device = [NSKeyedUnarchiver unarchiveObjectWithData:deviceAsData];
		[device retain];
		[deviceName setStringValue:[NSString stringWithFormat:@"%@ (%@)",
									[device name], [device addressString]]];
		
		if( [self isInRange] )
			priorStatus = InRange;
		else
			priorStatus = OutOfRange;
	}
	
	//Timer interval
	if( [[defaults stringForKey:@"timerInterval"] length] > 0 )
		[timerInterval setStringValue:[defaults stringForKey:@"timerInterval"]];
	
	// Monitoring enabled
	BOOL monitoring = [defaults boolForKey:@"enabled"];
	if( monitoring ) {
		[monitoringEnabled setState:NSOnState];
		[self startMonitoring];
	}
	
	// Run scripts on startup
	BOOL startup = [defaults boolForKey:@"executeOnStartup"];
	if( startup ) {
		[runScriptsOnStartup setState:NSOnState];
		
		if( monitoring ) {
			if( [self isInRange] ) {
				[self runInRangeScript];
			} else {
				[self runOutOfRangeScript];
			}
		}
	}
	
}

- (void)userDefaultsSave
{
	NSUserDefaults *defaults;
	NSData *deviceAsData;
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	// Monitoring enabled
	BOOL monitoring = ( [monitoringEnabled state] == NSOnState ? TRUE : FALSE );
	[defaults setBool:monitoring forKey:@"enabled"];
	
	// Execute scripts on startup
	BOOL startup = ( [runScriptsOnStartup state] == NSOnState ? TRUE : FALSE );
	[defaults setBool:startup forKey:@"executeOnStartup"];
	
	// Timer interval
	[defaults setObject:[timerInterval stringValue] forKey:@"timerInterval"];
	
	// Device
	if( device ) {
		deviceAsData = [NSKeyedArchiver archivedDataWithRootObject:device];
		[defaults setObject:deviceAsData forKey:@"device"];
	}
	
	[defaults synchronize];
}


#pragma mark -
#pragma mark Interface Methods

- (IBAction)changeDevice:(id)sender
{
	IOBluetoothDeviceSelectorController *deviceSelector;
	deviceSelector = [IOBluetoothDeviceSelectorController deviceSelector];
	[deviceSelector runModal];
	
	NSArray *results;
	results = [deviceSelector getResults];
	
	if( !results )
		return;
	
	device = [results objectAtIndex:0];
	[device retain];
	
	[deviceName setStringValue:[NSString stringWithFormat:@"%@ (%@)",
								[device name],
								[device addressString]]];
}

- (IBAction)checkConnectivity:(id)sender
{
	[progressIndicator startAnimation:nil];
	
	if( [self isInRange] )
	{
		[progressIndicator stopAnimation:nil];
		NSRunAlertPanel( @"Found", @"Device is powered on and in range", nil, nil, nil, nil );
	}
	else
	{
		[progressIndicator stopAnimation:nil];
		NSRunAlertPanel( @"Not Found", @"Device is powered off or out of range", nil, nil, nil, nil );
	}
}

- (void)showWindow:(id)sender
{
	[prefsWindow makeKeyAndOrderFront:self];
    [prefsWindow becomeMainWindow];
    [prefsWindow becomeKeyWindow];
	[prefsWindow center];
}


@end
