//
//  ViewController.m
//  TrackLocation
//
//  Created by Stanislav Shpak on 12/25/15.
//  Copyright © 2015 Stanislav Shpak. All rights reserved.
//

#import "ViewController.h"
#import <MapKit/MapKit.h>

@interface ViewController () <CLLocationManagerDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@end

@implementation ViewController

#pragma mark - Lifecycle -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    // Setup location tracker accuracy
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    
    // Distance filter
    self.locationManager.distanceFilter = 50.f;
    
    // Assign location tracker delegate
    self.locationManager.delegate = self;
    
    // This setup pauses location manager if location wasn't changed
    [self.locationManager setPausesLocationUpdatesAutomatically:YES];
    
    // For iOS9 we have to call this method if we want to receive location updates in background mode
    if([self.locationManager respondsToSelector:@selector(allowsBackgroundLocationUpdates)]){
        [self.locationManager setAllowsBackgroundLocationUpdates:YES];
    }
    
    // Display user location only when app has access to user location
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
        self.mapView.showsUserLocation = YES;
    }

    [self addPins];
}

- (void)addPins {
    NSArray <CLLocation *> *locations = [self locations];
    for (CLLocation *location in locations) {
        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
        annotation.coordinate = location.coordinate;
        [self.mapView addAnnotation:annotation];
    }
}

#pragma mark - Button Actions -

- (IBAction)startLocationTracking:(id)sender {
    
    // Get current authorization status and check it
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied) {
        // Display message about disabled location service
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Location Service Disabled" message:@"Please go to Settings and turn on Location Service for this app" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        }];
        [alertController addAction:settingsAction];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {}];
        [alertController addAction:cancelAction];
        
    } else if (status == kCLAuthorizationStatusNotDetermined) {
        // Request authorization to receive user's location
        [self.locationManager requestAlwaysAuthorization];
        
    } else if (status == kCLAuthorizationStatusAuthorizedAlways) {
        // Start updating location
        [_locationManager startUpdatingLocation];
    }
}

- (IBAction)stopLocationTracking:(id)sender {
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - Location Manager Delegate methods -

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    NSLog(@"Did update location");
    
    // For real cases we should filter location array by accuracy
    // And check timestamp if you need real time tracking
    // By we don't do it here
    CLLocation *location = [locations lastObject];
    if (location == nil)
        return;
    
    // Save location
    [self addLocation:location];
    
    // Add location pin on map
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    annotation.coordinate = location.coordinate;
    [self.mapView addAnnotation:annotation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Error: %@", error.localizedDescription);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusNotDetermined) {
        [self.locationManager requestAlwaysAuthorization];
    } else if (status == kCLAuthorizationStatusAuthorizedAlways) {
        self.mapView.showsUserLocation = YES;
    }
}

#pragma mark - Storing locations -

- (void)addLocation:(nonnull CLLocation *)location {
    
    // Use very simple way to store some simple data - saving to file
    // In real app if you want to save miltiple data - use databases.
    // We can't save location objects in file, so convert location into
    // dictionaries and save it
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *filePath = [paths.firstObject stringByAppendingPathComponent:@"locations"];
    NSMutableArray *locations = [[NSArray arrayWithContentsOfFile:filePath] mutableCopy];
    if (!locations)
        locations = [NSMutableArray new];
    NSNumber *latitude = [NSNumber numberWithDouble:location.coordinate.latitude];
    NSNumber *longitude = [NSNumber numberWithDouble:location.coordinate.longitude];
    NSDictionary *locationDictionary = @{@"latitude":latitude, @"longitude":longitude};
    [locations addObject:locationDictionary];
    [locations writeToFile:filePath atomically:YES];
}

- (NSArray <CLLocation *> *)locations {
    // Get path to documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *filePath = [paths.firstObject stringByAppendingPathComponent:@"locations"];
    NSArray *array = [NSArray arrayWithContentsOfFile:filePath];
    
    // Convert location dictionaries to CLLocation objects and return the array
    NSMutableArray <CLLocation *> *locations = [NSMutableArray new];
    for (NSDictionary *dict in array) {
        NSNumber *latitudeNumber = dict[@"latitude"];
        NSNumber *longitudeNumber = dict[@"longitude"];
        CLLocationDegrees latitude = latitudeNumber.doubleValue;
        CLLocationDegrees longitude = longitudeNumber.doubleValue;
        CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude
                                                          longitude:longitude];
        [locations addObject:location];
    }
    return locations;
}

#pragma mark - Other -

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MKCoordinateRegion mapRegion;
        mapRegion.center = mapView.userLocation.coordinate;
        mapRegion.span.latitudeDelta = 0.05;
        mapRegion.span.longitudeDelta = 0.05;
        
        [self.mapView setRegion:mapRegion animated: YES];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end


