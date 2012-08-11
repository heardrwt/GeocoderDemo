//
//  DistanceBetweenTableViewController.m
//  GeocoderDemo
//
//  Copyright 2011 Apple Inc. All rights reserved.
//

//     File: DistanceBetweenTableViewController.m
// Abstract: UITableViewController that demonstrates calculating distance between two coordinates.
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

#import "DistanceBetweenTableViewController.h"
#import "CoordinateSelectorTableViewController.h"
#import "PlacemarksListViewController.h"

#pragma mark - Private Category
@interface DistanceBetweenTableViewController (){
@private
        
    CoordinateSelectorTableViewController *_toCoordinateSelector; 
    CoordinateSelectorTableViewController *_fromCoordinateSelector;
    
}

@property (readonly) CoordinateSelectorTableViewController *toCoordinateSelector;  
@property (readonly) CoordinateSelectorTableViewController *fromCoordinateSelector;  


@end


@implementation DistanceBetweenTableViewController


@synthesize toCoordinateSelector=_toCoordinateSelector;
@synthesize fromCoordinateSelector=_fromCoordinateSelector;



- (id)init{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
        _toCoordinateSelector = [[CoordinateSelectorTableViewController alloc] initWithAllowedOptionsSearch:YES current:YES regular:NO custom:NO];
        _fromCoordinateSelector = [[CoordinateSelectorTableViewController alloc] initWithAllowedOptionsSearch:YES current:YES regular:NO custom:NO];
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
    self.title = NSLocalizedString(@"Distance Calculator", nil);
        
}

- (void)viewDidUnload{

    
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

#pragma mark - Distance Calculation

-(double)distanceBetweenCoordinates{
    CLLocationDegrees latitude, longitude;
    
    latitude = self.toCoordinateSelector.selectedCoordinate.latitude;
    longitude = self.toCoordinateSelector.selectedCoordinate.longitude;
    CLLocation *to = [[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] autorelease];
    
    latitude = self.fromCoordinateSelector.selectedCoordinate.latitude;
    longitude = self.fromCoordinateSelector.selectedCoordinate.longitude;
    CLLocation *from = [[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] autorelease];
    
    CLLocationDistance distance = [to distanceFromLocation:from];
    return distance;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    // Return the number of sections.
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    // Return the number of rows in the section.
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{


    //to and from cells
    if (indexPath.section == 0 || indexPath.section == 1) {

        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"selectorCell"];
        if (! cell) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"selectorCell"] autorelease];

        CoordinateSelectorTableViewController *selector;
        switch (indexPath.section) {
            default:
            case 0: selector = self.toCoordinateSelector; break;
            case 1: selector = self.fromCoordinateSelector; break;
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (selector.selectedType != CoordinateSelectorLastSelectedTypeUndefined) {
            cell.textLabel.text = selector.selectedName;
            cell.detailTextLabel.text = [NSString stringWithFormat:@"φ:%.4F, λ:%.4F", selector.selectedCoordinate.latitude, selector.selectedCoordinate.longitude]; 
        } else {
            cell.textLabel.text = NSLocalizedString(@"Select a Place",nil);
            cell.detailTextLabel.text = @"";
        }
        
        return cell;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (! cell) cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"] autorelease];

    //Distance Display Cell
    if (indexPath.section == 2) {
        if ( self.toCoordinateSelector.selectedType != CoordinateSelectorLastSelectedTypeUndefined &&
            self.fromCoordinateSelector.selectedType != CoordinateSelectorLastSelectedTypeUndefined ){
            
            cell.textLabel.text = [NSString stringWithFormat:@"%.1f km", [self distanceBetweenCoordinates] / 1000];
        } else {
            cell.textLabel.text = NSLocalizedString(@"- km", nil);
        }
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        cell.textLabel.textColor = [UIColor grayColor];

        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }    

    cell.textLabel.text = NSLocalizedString(@"Unknown Cell", nil);
    
    return cell;
}

-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44.0f;
}

-(NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    if (section == 2){
        return NSLocalizedString(@"As the Crow Flies", nil);
    }
    return NSLocalizedString(@"", nil);
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    [[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];
    
    if (indexPath.section == 0){
        [[self navigationController] pushViewController:self.toCoordinateSelector animated:YES];
    }

    if (indexPath.section == 1){
        [[self navigationController] pushViewController:self.fromCoordinateSelector animated:YES];
    }

     
}






- (void)dealloc {

    [_toCoordinateSelector release];
    [_fromCoordinateSelector release];     
    
    [super dealloc];
}
@end
