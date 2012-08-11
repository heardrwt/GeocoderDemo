//
//  CoordinateSelectorTableViewController.m
//  GeocoderDemo
//
//  Created by Richard Heard on 19/05/11.
//  Copyright 2011 Apple Inc. All rights reserved.
//

//     File: CoordinateSelectorTableViewController.m
// Abstract: UITableViewController that allows for the selection of a CLCoordinate2D 
//  Version: 1.0
// 
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
// Inc. ("Apple") in consideration of your agreement to the following
// terms, and your use, installation, modification or redistribution of
// this Apple software constitutes acceptance of these terms.  If you do
// not agree with these terms, please do not use, install, modify or
// redistribute this Apple software.
// 
// In consideration of your agreement to abide by the following terms, and
// subject to these terms, Apple grants you a personal, non-exclusive
// license, under Apple's copyrights in this original Apple software (the
// "Apple Software"), to use, reproduce, modify and redistribute the Apple
// Software, with or without modifications, in source and/or binary forms;
// provided that if you redistribute the Apple Software in its entirety and
// without modifications, you must retain this notice and the following
// text and disclaimers in all such redistributions of the Apple Software.
// Neither the name, trademarks, service marks or logos of Apple Inc. may
// be used to endorse or promote products derived from the Apple Software
// without specific prior written permission from Apple.  Except as
// expressly stated in this notice, no other rights or licenses, express or
// implied, are granted by Apple herein, including but not limited to any
// patent rights that may be infringed by your derivative works or by other
// works in which the Apple Software may be incorporated.
// 
// The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
// MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
// THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
// OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
// 
// IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
// OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
// MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
// AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
// STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
// 
// Copyright (C) 2011 Apple Inc. All Rights Reserved.
// 

#import "CoordinateSelectorTableViewController.h"

//pull this in so we can use ABCreateStringWithAddressDictionary()
#import <AddressBookUI/AddressBookUI.h>

//keys that correspond to entires in CoordinateSelectorRegularOptions.plist
NSString * const kCoordinateSelectorOptionsCoordinates = @"coordinates";
NSString * const kCoordinateSelectorOptionsName = @"name";
NSString * const kCoordinateSelectorOptionsLat = @"lat";
NSString * const kCoordinateSelectorOptionsLong = @"long";



#pragma mark - Private Category
@interface CoordinateSelectorTableViewController (){
@private
    NSArray *_searchPlacemarksCache; // An array of CLPlacemarks returned by the last search.
    NSArray *_regularCoordinatesCache; // An array of coordinate dictionaries that store all the available static locations.
    CLLocationManager *_locationManager; // location manager for current location.
    
    CoordinateSelectorLastSelectedType _selectedType; //used to store the users section Type
    NSInteger _selectedIndex; //used to store the users regular location selection
    CLLocationCoordinate2D _selectedCoordinate; //used to store the users selection
    NSString* _selectedName; //used to store the users selection
    
    NSIndexPath *_checkedIndexPath; //used to store the users overall selection
    
    BOOL _allowSearch;  //allow the user to search for locations
    BOOL _allowCurrent; //allow the selection of a the current location
    BOOL _allowRegular; //allow the selection of a regular point from a dictionary
    BOOL _allowCustom;  //allow the selection of a custom point
    
    
    //custom nib cells
    UITableViewCell *_searchCell;
    UITextField *_searchTextField;
    UIActivityIndicatorView *_searchSpinner;

    
    UITableViewCell *_customLocationCell;
    UITextField *_customLatitudeTextField;
    UITextField *_customLongitudeTextField;
    
    UITableViewCell *_currentLocationCell;
    UILabel *_currentLocationLabel;
    UIActivityIndicatorView *_currentLocationActivityIndicatorView;
}
//setup
-(void)loadNibCells;
-(void)loadRegularCoordinatesCache;

//update selected cell
-(void)updateSelectedName;
-(void)updateSelectedCoordinate;

//current location
-(void)startUpdatingCurrentLocation;
-(void)stopUpdatingCurrentLocation;

//placemarks search
-(void)performPlacemarksSearch;
-(void)lockSearch;
-(void)unlockSearch;

@end


@implementation CoordinateSelectorTableViewController

@synthesize selectedIndex=_selectedIndex;
@synthesize selectedType=_selectedType;
@synthesize selectedCoordinate=_selectedCoordinate;
@synthesize selectedName=_selectedName;


//custom nib cells
@synthesize searchCell=_searchCell;
@synthesize searchTextField=_searchTextField;
@synthesize searchSpinner=_searchSpinner;

@synthesize customLocationCell=_customLocationCell;
@synthesize customLatitudeTextField=_customLatitudeTextField;
@synthesize customLongitudeTextField=_customLongitudeTextField;

@synthesize currentLocationCell=_currentLocationCell;
@synthesize currentLocationLabel=_currentLocationLabel;
@synthesize currentLocationActivityIndicatorView=_currentLocationActivityIndicatorView;


//designated initialiser
- (id)initWithAllowedOptionsSearch:(BOOL)allowSearch current:(BOOL)allowCurrent regular:(BOOL)allowRegular custom:(BOOL)allowCustom {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialisation
        _allowSearch = allowSearch;
        _allowCurrent = allowCurrent;
        _allowRegular = allowRegular;
        _allowCustom = allowCustom;
        
        //setup
        [self loadRegularCoordinatesCache];
        
        //do some default variables setup.
        _selectedCoordinate = kCLLocationCoordinate2DInvalid;
        _selectedType = CoordinateSelectorLastSelectedTypeUndefined;
        [self updateSelectedName];
        [self updateSelectedCoordinate];

    }
    return self;
}

- (id)init {
    return [self initWithAllowedOptionsSearch:NO current:YES regular:YES custom:YES ];
}

- (void)dealloc {
    [_regularCoordinatesCache release];
    [_locationManager release];
    [_checkedIndexPath release];
    [_selectedName release];
    
    [super dealloc];
}

#pragma mark - Setup
-(void)loadNibCells{
    //load our custom table view cells from our nib.
    [[NSBundle mainBundle] loadNibNamed:@"CoordinateSelectorTableViewCells" 
                                  owner:self 
                                options:nil];
}

-(void)loadRegularCoordinatesCache{
    [_regularCoordinatesCache release]; // just incase this is called more than once
    NSString *path = [[NSBundle mainBundle] pathForResource:@"CoordinateSelectorRegularOptions" ofType:@"plist"];
    _regularCoordinatesCache = [[[NSDictionary dictionaryWithContentsOfFile:path] objectForKey:kCoordinateSelectorOptionsCoordinates] retain];
}

- (void)didReceiveMemoryWarning{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Select a Coord.", nil);
    self.clearsSelectionOnViewWillAppear = NO;
    [self loadNibCells];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self updateSelectedCoordinate];
    //stop updating, we don't care no more..
    if (_selectedType == CoordinateSelectorLastSelectedTypeCurrent) {
        [self stopUpdatingCurrentLocation];
    }
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //start updating, we might care again..
    if (_selectedType == CoordinateSelectorLastSelectedTypeCurrent) {
        [self startUpdatingCurrentLocation];
    }    
}
- (void)viewDidUnload{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    // Return the number of sections.
    return _allowSearch + _allowCurrent + _allowRegular + _allowCustom;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    // Return the number of rows in the section.
    if (_allowSearch){
        if ( section == 0 ){
            return 1 + [_searchPlacemarksCache count];
        }
    }

    if (_allowRegular){
        if ( section == (0 + _allowSearch + _allowCurrent) ){
            return [_regularCoordinatesCache count];
        }
    }
    if (_allowCustom){
        if (section == (0 + _allowSearch + _allowCurrent + _allowRegular)){
            if (_selectedType == CoordinateSelectorLastSelectedTypeCustom) {
                return 2; // one for title, one for edit cells. (only show edit cells if selected)
            }
        }
    }
    
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    }
        
    //Configure the cell...
    NSInteger section = indexPath.section;
    if (section == (_allowSearch + _allowCurrent + _allowRegular) && indexPath.row == 1){ //custom
        //load the custom cell from the Nib
        cell = _customLocationCell;
        
    } else if (section == (_allowSearch + _allowCurrent + _allowRegular) && indexPath.row == 0){ //custom
        cell.textLabel.text = NSLocalizedString(@"Custom Location", nil);
        
    } else if (section == _allowSearch + _allowCurrent) { //Regular
        NSDictionary *info = [_regularCoordinatesCache objectAtIndex:indexPath.row];
        cell.textLabel.text = [info objectForKey:kCoordinateSelectorOptionsName];
        CLLocationDegrees latitude = (double)[[info objectForKey:kCoordinateSelectorOptionsLat] doubleValue]; 
        CLLocationDegrees longitude = (double)[[info objectForKey:kCoordinateSelectorOptionsLong] doubleValue];
        cell.detailTextLabel.text = [NSString stringWithFormat: @"φ:%.4F, λ:%.4F", latitude, longitude];

    } else if (section == _allowSearch) { //Current
        //load the custom cell from the Nib
        cell = _currentLocationCell;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || 
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ) {
            _currentLocationLabel.text = NSLocalizedString(@"Location Services Disabled", nil);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }

    } else if ((section) == 0) { //Search
        if (indexPath.row == 0) {
            return _searchCell;
        }
        //otherwise display the list of results
        CLPlacemark *placemark = [_searchPlacemarksCache objectAtIndex:indexPath.row -1];
        
        cell.textLabel.text = ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO);
        
        CLLocationDegrees latitude = placemark.location.coordinate.latitude;
        CLLocationDegrees longitude = placemark.location.coordinate.longitude;
        cell.detailTextLabel.text = [NSString stringWithFormat: @"φ:%.4F, λ:%.4F", latitude, longitude];        
        
    } else { //Unknown cell
        cell.textLabel.text = NSLocalizedString(@"Unknown Cell", nil);
    }

    //show a check next to the selected option / cell
    if ([_checkedIndexPath isEqual:indexPath]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}


-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == _allowSearch + _allowRegular + _allowCurrent && indexPath.row == 1){
        return 84.0f; // custom location cell
    }
    return 44.0f;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{    
    
    //set the selected type
    NSInteger section = indexPath.section;
    if (section == (_allowSearch + _allowCurrent + _allowRegular)){
        _selectedType = CoordinateSelectorLastSelectedTypeCustom;   
    } else if (section == _allowSearch + _allowCurrent) {
        _selectedType = CoordinateSelectorLastSelectedTypeRegular;   
    } else if (section == _allowSearch) {
        _selectedType = CoordinateSelectorLastSelectedTypeCurrent;   
    } else if ((section) == 0) {
        _selectedType = CoordinateSelectorLastSelectedTypeSearch;   
    }
    
    //deselect the cell
    [self.tableView cellForRowAtIndexPath:indexPath].selected = NO;

    //if this is the search cell itself do nothing.
    if (_selectedType == CoordinateSelectorLastSelectedTypeSearch && indexPath.row == 0){
        return;
    }

    //if location services are restricted do nothing
    if (_selectedType == CoordinateSelectorLastSelectedTypeCurrent){
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || 
            [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ) {
            return;
        }
    }
    
    //set the selected row index
    _selectedIndex = indexPath.row;
        
    //move the checkmark from the previous to the new cell
    [self.tableView cellForRowAtIndexPath:_checkedIndexPath].accessoryType = UITableViewCellAccessoryNone;   
    [self.tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;

    //set this row to be checked on next reload
    if (_checkedIndexPath != indexPath) {
        [_checkedIndexPath release];
        _checkedIndexPath = [indexPath retain];
    }
        
    //set the selected name based on the selected type
    [self updateSelectedName]; 
    
    //set the selected coordinates based on the selected type and index
    [self updateSelectedCoordinate];
    
    //if current location has been selected, start updating current location
    if (_selectedType == CoordinateSelectorLastSelectedTypeCurrent) {
        [self startUpdatingCurrentLocation];
    }
    
    //if regular or search, pop back to previous level
    if (_selectedType == CoordinateSelectorLastSelectedTypeRegular ||
        _selectedType == CoordinateSelectorLastSelectedTypeSearch){
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    //if this is the custom cell that has been tapped, show edit fields, otherwise hide them
    NSArray *indexes = [NSArray arrayWithObjects:
                        [NSIndexPath indexPathForRow:1 inSection:(0 + _allowSearch + _allowCurrent + _allowRegular)], 
                        nil];

    if (self.selectedType == CoordinateSelectorLastSelectedTypeCustom){
        if ([self.tableView numberOfRowsInSection:(0 + _allowSearch + _allowCurrent + _allowRegular)] == 1)
            [self.tableView insertRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        if ([self.tableView numberOfRowsInSection:(0 + _allowSearch + _allowCurrent + _allowRegular)] == 2)
            [self.tableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationAutomatic];
    }

    
}


#pragma mark - update selected cell

//keys off selectedType and selectedCoordinates 
-(void)updateSelectedName{
    [_selectedName release]; //release the old string
    
    switch (_selectedType) {
        case CoordinateSelectorLastSelectedTypeCurrent: _selectedName = NSLocalizedString(@"Current Location", nil); break;
        case CoordinateSelectorLastSelectedTypeSearch: {
            CLPlacemark *placemark = [_searchPlacemarksCache objectAtIndex:_selectedIndex-1]; //take into account the first 'search' cell
            _selectedName = ABCreateStringWithAddressDictionary(placemark.addressDictionary, NO);
            break;
        }
        case CoordinateSelectorLastSelectedTypeUndefined: _selectedName = NSLocalizedString(@"Select a Location", nil); break;
        case CoordinateSelectorLastSelectedTypeCustom: _selectedName = NSLocalizedString(@"Custom Location", nil); break;
        case CoordinateSelectorLastSelectedTypeRegular: {
            NSDictionary *info = [_regularCoordinatesCache objectAtIndex:_selectedIndex];
            _selectedName = [info objectForKey:kCoordinateSelectorOptionsName];
            break;
        }
    }
    
    [_selectedName retain]; //retain the new string

}

//keys off selectedType and selectedCoordinates 
-(void)updateSelectedCoordinate{
    switch (_selectedType) {
        case CoordinateSelectorLastSelectedTypeCustom: {
            CLLocationDegrees latitude = [self.customLatitudeTextField.text doubleValue];
            CLLocationDegrees longitude = [self.customLongitudeTextField.text doubleValue];
            _selectedCoordinate = CLLocationCoordinate2DMake(latitude, longitude); 
            break; 
        }
        case CoordinateSelectorLastSelectedTypeSearch: { 
            //allow for the selection of search results
            CLPlacemark *placemark = [_searchPlacemarksCache objectAtIndex:_selectedIndex-1]; //take into account the first 'search' cell
            _selectedCoordinate = placemark.location.coordinate;
            break;
        }
        case CoordinateSelectorLastSelectedTypeUndefined: _selectedCoordinate = kCLLocationCoordinate2DInvalid; break;
        case CoordinateSelectorLastSelectedTypeCurrent: break; // no need to update for current location (CL delegate callback sets it)
        case CoordinateSelectorLastSelectedTypeRegular: {
            NSDictionary *info = [_regularCoordinatesCache objectAtIndex:_selectedIndex];
            CLLocationDegrees latitude = (double)[[info objectForKey:kCoordinateSelectorOptionsLat] doubleValue]; 
            CLLocationDegrees longitude = (double)[[info objectForKey:kCoordinateSelectorOptionsLong] doubleValue];
            _selectedCoordinate = CLLocationCoordinate2DMake(latitude, longitude); 
            break;
        }
    }

}

#pragma mark - current location
-(void)startUpdatingCurrentLocation{
    
    //if location services are restricted do nothing
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied || 
        [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted ) {
        return;
    }

    // if locationManager does not currently exist, create it.
    if (!_locationManager){
        _locationManager = [[CLLocationManager alloc] init];
        [_locationManager setDelegate:self];
        _locationManager.distanceFilter = 10.0f; //we don't need to be any more accurate than 10m 
    }
    
    [_locationManager startUpdatingLocation];
    [_currentLocationActivityIndicatorView startAnimating];

}
-(void)stopUpdatingCurrentLocation{
    [_locationManager stopUpdatingLocation];
    [_currentLocationActivityIndicatorView stopAnimating];
}


#pragma mark - CLLocationManagerDelegate - Location updates
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {		
    // if the location is older than 30s ignore
    if (fabs([newLocation.timestamp timeIntervalSinceDate:[NSDate date]]) > 30 ){
        return;
    }
    
    _selectedCoordinate = [newLocation coordinate];
    
    //update the current location cells detail label with these coords
    _currentLocationLabel.text = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", _selectedCoordinate.latitude, _selectedCoordinate.longitude];
    
    // after recieving a location, stop updating
    [self stopUpdatingCurrentLocation];
    
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"%@", error);
    
    //stop updating.
    [self stopUpdatingCurrentLocation];
    
    //set selected location to invalid location
    _selectedType = CoordinateSelectorLastSelectedTypeUndefined;
    _selectedCoordinate = kCLLocationCoordinate2DInvalid;
    _selectedName = [NSLocalizedString(@"Select a Location", nil) retain];
    _currentLocationLabel.text = NSLocalizedString(@"Error updating location", nil);
    
    //remove the check from the current Location cell
    _currentLocationCell.accessoryType = UITableViewCellAccessoryNone;
    
    //show an alert
    UIAlertView *alert = [[[UIAlertView alloc] init] autorelease];
    alert.title = NSLocalizedString(@"Error updating location", nil);
    alert.message = [error localizedDescription];
    [alert addButtonWithTitle:@"OK"];
    [alert show];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{

}

#pragma mark - placemarks search
-(void)performPlacemarksSearch{
    [self lockSearch];
    //perform geocode
    
    CLGeocoder *geocoder = [[[CLGeocoder alloc] init] autorelease];
    [geocoder geocodeAddressString:self.searchTextField.text completionHandler:^(NSArray *placemarks, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (_checkedIndexPath.section == 0) {
                //clear any current selections if they are search result selections
                [_checkedIndexPath release];
                _checkedIndexPath = nil;
            }
            
            [_searchPlacemarksCache release];
            _searchPlacemarksCache = [placemarks retain]; //might be nil.
            [[self tableView] reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
            [self unlockSearch];
            
        });
    }];

}

-(void)lockSearch{
    self.searchTextField.enabled = NO;
    self.searchSpinner.hidden = NO;
}

-(void)unlockSearch{
    self.searchTextField.enabled = YES;
    self.searchSpinner.hidden = YES;

}

// Dismiss the keyboard for the textfields 
#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.customLongitudeTextField resignFirstResponder];
    [self.customLatitudeTextField resignFirstResponder];
    [self.searchTextField resignFirstResponder];

    if (textField == self.searchTextField){
        //initiate a search!
        [self performPlacemarksSearch];
    }
	return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField{
    [self updateSelectedCoordinate];
}



#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    //Dismiss the keyboard upon a scroll
    [self.customLongitudeTextField resignFirstResponder];
    [self.customLatitudeTextField resignFirstResponder];
}


@end
