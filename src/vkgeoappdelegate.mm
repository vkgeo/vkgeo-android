#import <UIKit/UIKit.h>
#import <CoreLocation/CLLocationManager.h>
#import <CoreLocation/CLLocationManagerDelegate.h>

#import <VKSdkFramework/VKSdkFramework.h>

#include <QtCore/QtGlobal>
#include <QtCore/QString>
#include <QtCore/QDebug>

#include "vkhelpershared.h"

static const CLLocationDistance LOCATION_DISTANCE_FILTER = 100.0;
static const QString            VK_APP_ID("6459902");

static CLLocationManager *LocationManager = nil;

@interface QIOSApplicationDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>
@end

@interface QIOSApplicationDelegate (VKGeoAppDelegate)
@end

@implementation QIOSApplicationDelegate (VKGeoAppDelegate)

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    Q_UNUSED(application)
    Q_UNUSED(launchOptions)

    [VKSdk initializeWithAppId:VK_APP_ID.toNSString()];

    VKHelperShared = new VKHelper();

    LocationManager = [[CLLocationManager alloc] init];

    LocationManager.allowsBackgroundLocationUpdates    = YES;
    LocationManager.pausesLocationUpdatesAutomatically = NO;
    LocationManager.desiredAccuracy                    = kCLLocationAccuracyNearestTenMeters;
    LocationManager.distanceFilter                     = LOCATION_DISTANCE_FILTER;
    LocationManager.delegate                           = self;

    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse ||
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
        [LocationManager startUpdatingLocation];

        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
            if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
                [LocationManager startMonitoringSignificantLocationChanges];
            }
        }
    }

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    Q_UNUSED(application)

    [VKSdk processOpenURL:url fromApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]];

    return YES;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    Q_UNUSED(manager)

    if (locations != nil && locations.lastObject != nil) {
        CLLocation *location = locations.lastObject;

        if (VKHelperShared != NULL) {
            VKHelperShared->updateLocation(location.coordinate.latitude, location.coordinate.longitude);
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    Q_UNUSED(manager)

    qWarning() << QString::fromNSString([error localizedDescription]);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    Q_UNUSED(manager)

    if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
        status == kCLAuthorizationStatusAuthorizedAlways) {
        [LocationManager startUpdatingLocation];

        if (status == kCLAuthorizationStatusAuthorizedAlways) {
            if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
                [LocationManager startMonitoringSignificantLocationChanges];
            }
        } else {
            [LocationManager stopMonitoringSignificantLocationChanges];
        }
    } else {
        [LocationManager stopUpdatingLocation];
        [LocationManager stopMonitoringSignificantLocationChanges];
    }
}

@end
