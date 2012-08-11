//
//  ForwardStringGeocodeTableViewController.m
//  GeocoderDemo
//
//  Copyright 2011 Apple Inc. All rights reserved.
//

//     File: ForwardStringGeocodeTableViewController.m
// Abstract: UITableViewController that demonstrates Forward String Geocoding.
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

#import "ForwardStringGeocodeTableViewController.h"
#import "CoordinateSelectorTableViewController.h"
#import "PlacemarksListViewController.h"

#pragma mark - Private Category
@interface ForwardStringGeocodeTableViewController (){
@private
    
    UITableViewCell *_searchStringCell;
    UITextField *_searchStringTextField;
    
    UITableViewCell *_searchHintCell;
    UISwitch *_searchHintSwitch;
    
    CoordinateSelectorTableViewController *_coordinateSelector;
    
    UITableViewCell *_searchRadiusCell;
    UILabel *_searchRadiusLabel;
    UISlider *_searchRadiusSlider;
    
    UIActivityIndicatorView *_spinner; //weak
}

@property (readonly) CoordinateSelectorTableViewController *coordinateSelector;  
@property (readonly) UIActivityIndicatorView *spinner;  

//geocode
-(IBAction)performStringGeocode:(id)sender;

//display helpers
- (void)displayPlacemarks:(NSArray*)placemarks;
- (void)displayError:(NSError*)error;
    

//UI helpers
-(void)lockUI;
-(void)unlockUI;
-(void)showSpinner:(BOOL)show;

@end


@implementation ForwardStringGeocodeTableViewController

@synthesize searchStringCell = _searchStringCell;
@synthesize searchStringTextField = _searchStringTextField;

@synthesize searchHintCell = _searchHintCell;
@synthesize searchHintSwitch = _searchHintSwitch;

@synthesize searchRadiusCell = _searchRadiusCell;
@synthesize searchRadiusLabel = _searchRadiusLabel;
@synthesize searchRadiusSlider = _searchRadiusSlider;

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
    self.title = NSLocalizedString(@"Forward String Geocode", nil);
        
    //load our custom table view cells from our nib.
    [[NSBundle mainBundle] loadNibNamed:@"ForwardStringGeocodeTableViewCells" 
                                  owner:self 
                                options:nil];
}

- (void)viewDidUnload{
    self.searchRadiusSlider = nil;
    self.searchHintCell = nil;
    self.searchHintSwitch = nil;
    self.searchRadiusCell = nil;
    self.searchRadiusLabel = nil;
    self.searchStringCell = nil;
    self.searchStringTextField = nil;
    
    _spinner = nil; // if the view has gone away, so should our weak pointer.
    
    [super viewDidUnload];

}

- (void)viewWillAppear:(BOOL)animated{
    [self.tableView reloadData]; //reload the data so its always fresh on re-display.
    
    //update the radius slider display label, incase ib is out of sync with default.
    [self radiusChanged:self];

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

#pragma mark - IBActions
- (IBAction)hintSwitchChanged:(id)sender{
    
    //show or hide the region hint cells
    NSArray *indexes = [NSArray arrayWithObjects:
                        [NSIndexPath indexPathForRow:1 inSection:1], 
                        [NSIndexPath indexPathForRow:2 inSection:1], 
                        nil];
    if (self.searchHintSwitch.on){
        [self.tableView insertRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [self.tableView deleteRowsAtIndexPaths:indexes withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (IBAction)radiusChanged:(id)sender {
    self.searchRadiusLabel.text = [NSString stringWithFormat:@"%1.1f km", self.searchRadiusSlider.value/1000.0f];
}

#pragma mark - Geocoding
- (IBAction)performStringGeocode:(id)sender {
    
    [self lockUI];
    
    
    CLGeocoder *geocoder = [[[CLGeocoder alloc] init] autorelease];
    
    //if we are going to includer a 
    if (self.searchHintSwitch.on){
        //use hint region
        CLLocationDistance dist = self.searchRadiusSlider.value; //50,000m (50km)
        CLLocationCoordinate2D point = self.coordinateSelector.selectedCoordinate;
        CLRegion *region =[[[CLRegion alloc] initCircularRegionWithCenter:point radius:dist identifier:@"Hint Region"] autorelease];
        
        [geocoder geocodeAddressString:self.searchStringTextField.text inRegion:region completionHandler:^(NSArray *placemarks, NSError *error) {
            NSLog(@"geocodeAddressString:inRegion:completionHandler: Completion Handler called!");
            if (error){
                NSLog(@"Geocode failed with error: %@", error);
                [self displayError:error];
                return;
            }
            NSLog(@"Received placemarks: %@", placemarks);
            [self displayPlacemarks:placemarks];
        }];
    } else {
        //don't use a hint region
        [geocoder geocodeAddressString:self.searchStringTextField.text completionHandler:^(NSArray *placemarks, NSError *error) {
            NSLog(@"geocodeAddressString:completionHandler: Completion Handler called!");
            if (error){
                NSLog(@"Geocode failed with error: %@", error);
                [self displayError:error];
                return;
            }
            NSLog(@"Received placemarks: %@", placemarks);
            [self displayPlacemarks:placemarks];
        }];
        
        
    }
    
}

#pragma mark - display helpers
//push a results viewer
- (void)displayPlacemarks:(NSArray*)placemarks{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self unlockUI];
        
        PlacemarksListViewController *plvc = [[PlacemarksListViewController alloc] initWithPlacemarks:placemarks preferCoord:YES];
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
    self.searchHintSwitch.enabled = NO;
    self.searchRadiusSlider.enabled = NO;

    //show spinner
    [self showSpinner:YES];
}
-(void)unlockUI{
    self.tableView.allowsSelection = YES;
    self.searchHintSwitch.enabled = YES;
    self.searchRadiusSlider.enabled = YES;

    //hide spinner
    [self showSpinner:NO];
}

-(void)showSpinner:(BOOL)show{
    //show spinner
    if (!_spinner){
        UIView* containerView = [[[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 22.0)] autorelease];
        UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite] autorelease];
        [spinner startAnimating];    
        [spinner setFrame:CGRectMake(149, 0, 22, 22)];
        [spinner setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        [containerView addSubview:spinner];
        self.tableView.tableFooterView = containerView;
        _spinner = spinner; //keep a weak ref around for later.
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
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    // Return the number of rows in the section.
    if (section == 1) return self.searchHintSwitch.on ? 3 : 1;
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    // ----- interface builder generated cells -----
    //search string cell
    if (indexPath.section == 0) {
        return self.searchStringCell;
    }

    //search hint cell
    if (indexPath.section == 1 && indexPath.row == 0) {
        return self.searchHintCell;
    }    

    //search radius cell
    if (indexPath.section == 1 && indexPath.row == 2) {
        return self.searchRadiusCell;
    }    
    
    
    // ----- non interface builder generated cells -----
    
    //radius button & label
    if (indexPath.section == 1 && indexPath.row == 1) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"radiusCell"];
        if (! cell) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"radiusCell"] autorelease];

        if (self.coordinateSelector.selectedType != CoordinateSelectorLastSelectedTypeUndefined) {
            cell.textLabel.text = self.coordinateSelector.selectedName;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", self.coordinateSelector.selectedCoordinate.latitude, self.coordinateSelector.selectedCoordinate.longitude]; 
        } else {
            cell.textLabel.text = NSLocalizedString(@"Select a Region", nil);
            cell.detailTextLabel.text = @"";
        }

        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }    

    //basic cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"basicCell"];
    if (! cell) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"basicCell"] autorelease];
    
    //geocode button
    if (indexPath.section == 2 && indexPath.row == 0 ) {
        cell.textLabel.text = NSLocalizedString(@"Geocode String", nil);
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
    
    if (indexPath.section == 1 && indexPath.row == 1){
        [[self navigationController] pushViewController:self.coordinateSelector animated:YES];
    }

    if (indexPath.section == 2 && indexPath.row == 0){
        //perform the Geocode
        [self performStringGeocode:self];
    }
    
}



// Dismiss the keyboard for the textfields 
#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
    [self performStringGeocode:self];
	return YES;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    //Dismiss the keyboard upon a scroll
    [self.searchStringTextField resignFirstResponder];
}


- (void)dealloc {
    [_searchStringTextField release];
    [_searchStringCell release];
    [_searchRadiusCell release];
    [_searchRadiusSlider release];
    [_searchRadiusLabel release];
    [_searchHintSwitch release];
    [_searchHintCell release];

    [_coordinateSelector release];
    
    [super dealloc];
}
@end
