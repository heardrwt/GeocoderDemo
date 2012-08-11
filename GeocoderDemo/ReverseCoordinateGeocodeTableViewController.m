//
//  ReverseCoordinateGeocodeTableViewController.m
//  GeocoderDemo
//
//  Copyright 2011 Apple Inc. All rights reserved.
//

//     File: ReverseCoordinateGeocodeTableViewController.m
// Abstract: UITableViewController that Demonstrates Reverse Coordinate Geocoding.
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

#import "ReverseCoordinateGeocodeTableViewController.h"
#import "CoordinateSelectorTableViewController.h"
#import "PlacemarksListViewController.h"

#pragma mark - Private Category
@interface ReverseCoordinateGeocodeTableViewController (){
@private
    
    CoordinateSelectorTableViewController *_coordinateSelector;
    UIActivityIndicatorView *_spinner; //weak
}

@property (readonly) CoordinateSelectorTableViewController *coordinateSelector;
@property (readonly) UIActivityIndicatorView *spinner;

//geocode
-(IBAction)performCoordinateGeocode:(id)sender;

//display helpers
- (void)displayPlacemarks:(NSArray*)placemarks;
- (void)displayError:(NSError*)error;
    
//UI helpers
-(void)lockUI;
-(void)unlockUI;
-(void)showSpinner:(BOOL)show;

@end


@implementation ReverseCoordinateGeocodeTableViewController

@synthesize coordinateSelector=_coordinateSelector;
@synthesize spinner=_spinner;


- (id)init{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        if (! _coordinateSelector){
            _coordinateSelector = [[CoordinateSelectorTableViewController alloc] init];
        }
    }
    return self;
}

- (void)didReceiveMemoryWarning{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];

    //setup
    self.title = NSLocalizedString(@"Reverse Geocode Coordinate", nil);
}

- (void)viewDidUnload{
    
    _spinner = nil; // if the view has gone away, so should our weak pointer.
    [super viewDidUnload];

}

- (void)viewWillAppear:(BOOL)animated{
    [self.tableView reloadData]; //reload the data so its always fresh on re-display.
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}


#pragma mark - Geocoding
- (void)performCoordinateGeocode:(id)sender {
    //- (void)reverseGeocodeLocation:(CLLocation *)location completionHandler:(CLGeocodeCompletionHandler)completionHandler;
    
    [self lockUI];
    
    CLGeocoder *geocoder = [[[CLGeocoder alloc] init] autorelease];
    CLLocation *location = [[[CLLocation alloc] initWithLatitude:self.coordinateSelector.selectedCoordinate.latitude longitude:self.coordinateSelector.selectedCoordinate.longitude] autorelease];

    
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        NSLog(@"reverseGeocodeLocation:completionHandler: Completion Handler called!");
        if (error){
            NSLog(@"Geocode failed with error: %@", error);
            [self displayError:error];
            return;
        }
        NSLog(@"Received placemarks: %@", placemarks);
        [self displayPlacemarks:placemarks];
    }];
}


#pragma mark - display helpers
//push a results viewer
- (void)displayPlacemarks:(NSArray*)placemarks{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self unlockUI];
        
        PlacemarksListViewController *plvc = [[PlacemarksListViewController alloc] initWithPlacemarks:placemarks preferCoord:NO];
        [self.navigationController pushViewController:plvc animated:YES];
        [plvc release];
    });
}

//push a results viewer
- (void)displayError:(NSError*)error{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self unlockUI];
        
        NSString *message;
        switch ([error code]) {
            case kCLErrorGeocodeFoundNoResult: message = @"kCLErrorGeocodeFoundNoResult"; break;
            case kCLErrorGeocodeCanceled: message = @"kCLErrorGeocodeCanceled"; break;
            case kCLErrorGeocodeFoundPartialResult: message = @"kCLErrorGeocodeFoundNoResult"; break;
            default: message = [error description]; break;
        }
        
        UIAlertView *alert =  [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"An error occurred.", nil)
                                                          message:message
                                                         delegate:nil 
                                                cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                otherButtonTitles:nil] autorelease];
        [alert show];
    });    
}


#pragma mark - UI Helpers
-(void)lockUI{
    self.tableView.allowsSelection = NO;

    //show spinner
    [self showSpinner:YES];
}
-(void)unlockUI{
    self.tableView.allowsSelection = YES;

    //hide spinner
    [self showSpinner:NO];
}

-(void)showSpinner:(BOOL)show{
    //show spinner
    if (!self.spinner){
        UIView* containerView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 22.0)] autorelease];
        UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
        [spinner startAnimating];    
        [spinner setFrame:CGRectMake(149, 0, 22, 22)];
        [spinner setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        [containerView addSubview:spinner];
        self.tableView.tableFooterView = containerView;
        _spinner = spinner; //keep it around for later. //weak
    }
    
    if (show){
        self.spinner.hidden = NO;
        [self.spinner startAnimating];
    } else {
        self.spinner.hidden = YES;
        [self.spinner stopAnimating];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    // Return the number of rows in the section.
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //dictionary cell
    if (indexPath.section == 0 && indexPath.row == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"coordinateCell"];
        if (! cell) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"coordinateCell"] autorelease];

        if (self.coordinateSelector.selectedType != CoordinateSelectorLastSelectedTypeUndefined) {
            cell.textLabel.text = self.coordinateSelector.selectedName;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", self.coordinateSelector.selectedCoordinate.latitude, self.coordinateSelector.selectedCoordinate.longitude]; 

        } else {
            cell.textLabel.text = NSLocalizedString(@"Select a Coordinate", nil);
            cell.detailTextLabel.text = @"";
        }

        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }    

    //basic cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"basicCell"];
    if (! cell) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"basicCell"] autorelease];
    
    //geocode button
    if (indexPath.section == 1 && indexPath.row == 0 ) {
        cell.textLabel.text = NSLocalizedString(@"Geocode Coordinate", nil);
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        return cell;
    }    

    cell.textLabel.text = NSLocalizedString(@"Unknown Cell", nil);
    
    return cell;
}

-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44.0f;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];
    
    if (indexPath.section == 0 && indexPath.row == 0){
        [[self navigationController] pushViewController:self.coordinateSelector animated:YES];
    }

    if (indexPath.section == 1 && indexPath.row == 0){
        //perform the Geocode
        [self performCoordinateGeocode:self];
    }
    
}


- (void)dealloc {
    [_coordinateSelector release];
    
    [super dealloc];
}
@end
