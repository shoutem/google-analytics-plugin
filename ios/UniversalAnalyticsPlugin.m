//UniversalAnalyticsPlugin.m
//Created by Daniel Wilson 2013-09-19

#import "UniversalAnalyticsPlugin.h"
#import "GAI.h"
#import "GAIDictionaryBuilder.h"
#import "GAIFields.h"

@implementation UniversalAnalyticsPlugin

- (void) pluginInitialize
{
    _debugMode = false;
    _customDimensions = nil;
    _trackers = [[NSMutableDictionary alloc] init];
}

- (BOOL) startedTrackerWithId: (NSString *)trackerId
{
    return [self getTrackerWithId:trackerId] != NULL;
}

- (void) addTracker: (id<GAITracker>)tracker withId:(NSString *)trackerId
{
    [_trackers setObject:tracker forKey:trackerId];
}

- (id<GAITracker>) getTrackerWithId: (NSString *)trackerId
{
    return [_trackers objectForKey:trackerId];
}

- (void) startTrackerWithId: (CDVInvokedUrlCommand*)command
{
    NSString* trackerId = [command.arguments objectAtIndex:0];
    
    if ([self startedTrackerWithId:trackerId]) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                 messageAsString:[NSString stringWithFormat:@"Tracker with id %@ already started.", trackerId]]
                                    callbackId:command.callbackId];
        return;
    }

    [GAI sharedInstance].dispatchInterval = 10;

    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:trackerId];
    [self addTracker:tracker withId:trackerId];

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
                                callbackId:command.callbackId];
    /* NSLog(@"successfully started GAI tracker"); */
}

- (void) addCustomDimensionsToTracker: (id<GAITracker>)tracker
{
    if (_customDimensions) {
      for (NSString *key in _customDimensions) {
        NSString *value = [_customDimensions objectForKey:key];

        /* NSLog(@"Setting tracker dimension slot %@: <%@>", key, value); */
        [tracker set:[GAIFields customDimensionForIndex:[key intValue]]
        value:value];
      }
    }
}

- (void) debugMode: (CDVInvokedUrlCommand*) command
{
  _debugMode = true;
  [[GAI sharedInstance].logger setLogLevel:kGAILogLevelVerbose];
}

- (void) setUserId: (CDVInvokedUrlCommand*)command
{
    NSString* trackerId = [command.arguments objectAtIndex:1];
    
    if (![self startedTrackerWithId:trackerId]) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                 messageAsString:[NSString stringWithFormat:@"Tracker with id %@ not started.", trackerId]]
                                    callbackId:command.callbackId];
        return;
    }
    
    id<GAITracker> tracker = [self getTrackerWithId:trackerId];
    NSString* userId = [command.arguments objectAtIndex:0];
    [tracker set:@"&uid" value: userId];
    
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
                                callbackId:command.callbackId];
}

- (void) enableUncaughtExceptionReporting: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    
    if (![[GAI sharedInstance] defaultTracker]) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Tracker not started"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }
    
    bool enabled = [[command.arguments objectAtIndex:0] boolValue];
    [[GAI sharedInstance] setTrackUncaughtExceptions:enabled];
    
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) addCustomDimension: (CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSString* key = [command.arguments objectAtIndex:0];
    NSString* value = [command.arguments objectAtIndex:1];

    if ( ! _customDimensions) {
      _customDimensions = [[NSMutableDictionary alloc] init];
    }

    _customDimensions[key] = value;

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) trackEvent: (CDVInvokedUrlCommand*)command
{
    NSString* trackerId = [command.arguments objectAtIndex:4];
    
    if (![self startedTrackerWithId:trackerId]) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                 messageAsString:[NSString stringWithFormat:@"Tracker with id %@ not started.", trackerId]]
                                    callbackId:command.callbackId];
        return;
    }

    NSString *category = nil;
    NSString *action = nil;
    NSString *label = nil;
    NSNumber *value = nil;

    if ([command.arguments count] > 0)
        category = [command.arguments objectAtIndex:0];

    if ([command.arguments count] > 1)
        action = [command.arguments objectAtIndex:1];

    if ([command.arguments count] > 2)
        label = [command.arguments objectAtIndex:2];

    if ([command.arguments count] > 3)
        value = [command.arguments objectAtIndex:3];

    id<GAITracker> tracker = [self getTrackerWithId:trackerId];

    [self addCustomDimensionsToTracker:tracker];

    [tracker send:[[GAIDictionaryBuilder
    createEventWithCategory: category //required
         action: action //required
          label: label
          value: value] build]];

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
                                callbackId:command.callbackId];
}

- (void) trackException: (CDVInvokedUrlCommand*)command
{
    NSString* trackerId = [command.arguments objectAtIndex:2];
    
    if (![self startedTrackerWithId:trackerId]) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                 messageAsString:[NSString stringWithFormat:@"Tracker with id %@ not started.", trackerId]]
                                    callbackId:command.callbackId];
        return;
    }

    NSString *description = nil;
    NSNumber *fatal = nil;

    if ([command.arguments count] > 0)
        description = [command.arguments objectAtIndex:0];

    if ([command.arguments count] > 1)
        fatal = [command.arguments objectAtIndex:1];

    id<GAITracker> tracker = [self getTrackerWithId:trackerId];

    [self addCustomDimensionsToTracker:tracker];

    [tracker send:[[GAIDictionaryBuilder
    createExceptionWithDescription: description
                                     withFatal: fatal] build]];

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
                                callbackId:command.callbackId];
}

- (void) trackView: (CDVInvokedUrlCommand*)command
{
    NSString* trackerId = [command.arguments objectAtIndex:1];
    
    if (![self startedTrackerWithId:trackerId]) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                 messageAsString:[NSString stringWithFormat:@"Tracker with id %@ not started.", trackerId]]
                                    callbackId:command.callbackId];
        return;
    }

    NSString* screenName = [command.arguments objectAtIndex:0];

    id<GAITracker> tracker = [self getTrackerWithId:trackerId];

    [self addCustomDimensionsToTracker:tracker];


    [tracker set:kGAIScreenName value:screenName];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
                                callbackId:command.callbackId];
}

- (void) trackTiming: (CDVInvokedUrlCommand*)command
{
    NSString* trackerId = [command.arguments objectAtIndex:4];
    
    if (![self startedTrackerWithId:trackerId]) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                 messageAsString:[NSString stringWithFormat:@"Tracker with id %@ not started.", trackerId]]
                                    callbackId:command.callbackId];
        return;
    }

    NSString *category = nil;
    NSNumber *intervalInMilliseconds = nil;
    NSString *name = nil;
    NSString *label = nil;

    if ([command.arguments count] > 0)
        category = [command.arguments objectAtIndex:0];

    if ([command.arguments count] > 1)
        intervalInMilliseconds = [command.arguments objectAtIndex:1];

    if ([command.arguments count] > 2)
        name = [command.arguments objectAtIndex:2];

    if ([command.arguments count] > 3)
        label = [command.arguments objectAtIndex:3];

    id<GAITracker> tracker = [self getTrackerWithId:trackerId];

    [self addCustomDimensionsToTracker:tracker];

    [tracker send:[[GAIDictionaryBuilder
    createTimingWithCategory: category //required
         interval: intervalInMilliseconds //required
           name: name
          label: label] build]];

    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
                                callbackId:command.callbackId];
}

- (void) addTransaction: (CDVInvokedUrlCommand*)command
{
    NSString* trackerId = [command.arguments objectAtIndex:6];
    
    if (![self startedTrackerWithId:trackerId]) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                 messageAsString:[NSString stringWithFormat:@"Tracker with id %@ not started.", trackerId]]
                                    callbackId:command.callbackId];
        return;
    }

    NSString *transactionId = nil;
    NSString *affiliation = nil;
    NSNumber *revenue = nil;
    NSNumber *tax = nil;
    NSNumber *shipping = nil;
    NSString *currencyCode = nil;


    if ([command.arguments count] > 0)
        transactionId = [command.arguments objectAtIndex:0];

    if ([command.arguments count] > 1)
        affiliation = [command.arguments objectAtIndex:1];

    if ([command.arguments count] > 2)
        revenue = [command.arguments objectAtIndex:2];

    if ([command.arguments count] > 3)
        tax = [command.arguments objectAtIndex:3];

    if ([command.arguments count] > 4)
        shipping = [command.arguments objectAtIndex:4];

    if ([command.arguments count] > 5)
        currencyCode = [command.arguments objectAtIndex:5];

    id<GAITracker> tracker = [self getTrackerWithId:trackerId];


    [tracker send:[[GAIDictionaryBuilder createTransactionWithId:transactionId             // (NSString) Transaction ID
                                                     affiliation:affiliation         // (NSString) Affiliation
                                                         revenue:revenue                  // (NSNumber) Order revenue (including tax and shipping)
                                                             tax:tax                  // (NSNumber) Tax
                                                        shipping:shipping                      // (NSNumber) Shipping
                                                    currencyCode:currencyCode] build]];        // (NSString) Currency code


    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
                                callbackId:command.callbackId];
}



- (void) addTransactionItem: (CDVInvokedUrlCommand*)command
{
    NSString* trackerId = [command.arguments objectAtIndex:7];
    
    if (![self startedTrackerWithId:trackerId]) {
        [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                 messageAsString:[NSString stringWithFormat:@"Tracker with id %@ not started.", trackerId]]
                                    callbackId:command.callbackId];
        return;
    }

    NSString *transactionId = nil;
    NSString *name = nil;
    NSString *sku = nil;
    NSString *category = nil;
    NSNumber *price = nil;
    NSNumber *quantity = nil;
    NSString *currencyCode = nil;


    if ([command.arguments count] > 0)
        transactionId = [command.arguments objectAtIndex:0];

    if ([command.arguments count] > 1)
        name = [command.arguments objectAtIndex:1];

    if ([command.arguments count] > 2)
        sku = [command.arguments objectAtIndex:2];

    if ([command.arguments count] > 3)
        category = [command.arguments objectAtIndex:3];

    if ([command.arguments count] > 4)
        price = [command.arguments objectAtIndex:4];

    if ([command.arguments count] > 5)
        quantity = [command.arguments objectAtIndex:5];

    if ([command.arguments count] > 6)
        currencyCode = [command.arguments objectAtIndex:6];

    id<GAITracker> tracker = [self getTrackerWithId:trackerId];


    [tracker send:[[GAIDictionaryBuilder createItemWithTransactionId:transactionId         // (NSString) Transaction ID
                                                                name:name  // (NSString) Product Name
                                                                 sku:sku           // (NSString) Product SKU
                                                            category:category  // (NSString) Product category
                                                               price:price               // (NSNumber)  Product price
                                                            quantity:quantity                 // (NSNumber)  Product quantity
                                                        currencyCode:currencyCode] build]];    // (NSString) Currency code


    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK]
                                callbackId:command.callbackId];
}

@end
