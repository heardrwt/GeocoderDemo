//
//  DictionarySelectorTableViewController.m
//  GeocoderDemo
//
//  Copyright 2011 Apple Inc. All rights reserved.
//

//     File: DictionarySelectorTableViewController.m
// Abstract: UITableViewController that allows for the selection of an NSDictionary in ABPerson format.
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

#import "DictionarySelectorTableViewController.h"


//keys that correspond to entires in CoordinateSelectorRegularOptions.plist
NSString * const kDictionarySelectorOptionsDictionaries = @"dictionaries";
NSString * const kDictionarySelectorOptionsName = @"name";
NSString * const kDictionarySelectorOptionsDictionary = @"dictionary";



#pragma mark - Private Category
@interface DictionarySelectorTableViewController (){
@private
    NSArray *_regularDictionariesCache; // An array of coordinate dictionaries that store all the available static locations.
    
    DictionarySelectorLastSelectedType _selectedType; //used to store the users section Type
    NSInteger _selectedIndex; //used to store the users regular location selection
    NSDictionary *_selectedDictionary; //used to store the users selection
    NSString* _selectedName; //used to store the users selection
    
    NSIndexPath *_checkedIndexPath; //used to store the users overall selection
    
    BOOL _allowContact; //allow the selection of a contact address
    BOOL _allowRegular; //allow the selection of a regular dictionary (preset)
    
}
//setup
-(void)loadRegularDictionariesCache;

//update selected cell
-(void)updateSelectedName;
-(void)updateSelectedDictionary;

//select a contact card
-(void)showPeoplePicker;

@end


@implementation DictionarySelectorTableViewController

@synthesize selectedIndex=_selectedIndex;
@synthesize selectedType=_selectedType;
@synthesize selectedDictionary=_selectedDictionary;
@synthesize selectedName=_selectedName;



//designated initialiser
- (id)initWithAllowedOptionsContact:(BOOL)allowContact regular:(BOOL)allowRegular{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialisation
        _allowContact = allowContact;
        _allowRegular = allowRegular;
        
        //setup
        [self loadRegularDictionariesCache];
        
        //do some default variables setup.
        _selectedType = DictionarySelectorLastSelectedTypeUndefined;
        [self updateSelectedName];
        [self updateSelectedDictionary];

    }
    return self;
}

- (id)init {
    return [self initWithAllowedOptionsContact:YES regular:YES];
}

- (void)dealloc {
    [_regularDictionariesCache release];
    [_checkedIndexPath release];
    [_selectedDictionary release];
    [_selectedName release];
    
    [super dealloc];
}

#pragma mark - Setup

-(void)loadRegularDictionariesCache{
    [_regularDictionariesCache release]; // just incase this is called more than once
    NSString *path = [[NSBundle mainBundle] pathForResource:@"DictionarySelectorRegularOptions" ofType:@"plist"];
    _regularDictionariesCache = [[[NSDictionary dictionaryWithContentsOfFile:path] objectForKey:kDictionarySelectorOptionsDictionaries] retain];
}

- (void)didReceiveMemoryWarning{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Select a Dictionary", nil);
    self.clearsSelectionOnViewWillAppear = NO;
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
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
    return _allowContact + _allowRegular;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    // Return the number of rows in the section.
    if (_allowRegular){
        if ( section == (0 + _allowContact) ){
            return [_regularDictionariesCache count];
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
    
    //show a check next to the selected option / cell
    if ([_checkedIndexPath isEqual:indexPath]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

        
    //Configure the cell...
    NSInteger section = indexPath.section;
    if (section == (_allowContact)){ //Regular
        NSDictionary *info = [_regularDictionariesCache objectAtIndex:indexPath.row];
        cell.textLabel.text = [info objectForKey:kDictionarySelectorOptionsName];

    } else if ((section) == 0) { //Contact
        cell.textLabel.text = NSLocalizedString(@"Contact Card", nil);
        
        if (_selectedType == DictionarySelectorLastSelectedTypeContact) {
            cell.detailTextLabel.text = _selectedName;
        } else {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text = NSLocalizedString(@"", nil); //don't show a subtitle if not selected       
        }
    } else { //Unknown cell
        cell.textLabel.text = NSLocalizedString(@"Unknown Cell", nil);
    }
    
    return cell;
}


-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44.0f;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{    
    
    //set the selected type
    NSInteger section = indexPath.section;
    if (section == _allowContact) {
        _selectedType = DictionarySelectorLastSelectedTypeRegular; 
    } else if ((section) == 0) { //contact
        _selectedType = DictionarySelectorLastSelectedTypeContact;   
    }
    
    //deselect the cell
    [self.tableView cellForRowAtIndexPath:indexPath].selected = NO;

    
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
    [self updateSelectedDictionary];
        
    //if regular, pop back to previous level
    if (_selectedType == DictionarySelectorLastSelectedTypeRegular){
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    //if contact, show the people picker
    if (_selectedType == DictionarySelectorLastSelectedTypeContact){
        [self showPeoplePicker];
    }
}


#pragma mark - update selected cell

//keys off selectedType and selectedCoordinates 
-(void)updateSelectedName{
    [_selectedName release]; //release the old string
    
    switch (_selectedType) {
        case DictionarySelectorLastSelectedTypeContact: { 
            //at this stage we don't know which contact the user has selected so set it to unknown contact..
            _selectedName = NSLocalizedString(@"Unknown Contact", nil);
            break;
        }
        case DictionarySelectorLastSelectedTypeRegular: {
            NSDictionary *info = [_regularDictionariesCache objectAtIndex:_selectedIndex];
            _selectedName = [info objectForKey:kDictionarySelectorOptionsName];
            break;
        }
        default: _selectedName = NSLocalizedString(@"Select a Dictionary", nil);
    }
    
    [_selectedName retain]; //retain the new string

}

//keys off selectedType and selectedDictionary
-(void)updateSelectedDictionary{
    [_selectedDictionary release]; //release the old dictionary
    
    switch (_selectedType) {
        case DictionarySelectorLastSelectedTypeContact: {
            _selectedDictionary = nil; // we don't know at this stage what the user will select
            break; 
        }
        case DictionarySelectorLastSelectedTypeRegular: {
            NSDictionary *info = [_regularDictionariesCache objectAtIndex:_selectedIndex];
            _selectedDictionary = [info objectForKey:kDictionarySelectorOptionsDictionary];
            break;
        }
        default: _selectedDictionary = nil; break; // default is nil.
    }
    
    [_selectedDictionary retain]; //retain the new dictionary
    
}

#pragma mark - ABPeoplePicker
-(void)showPeoplePicker{
    //show the contact picker. 
    ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
    [self presentModalViewController:picker animated:YES];
    [picker release];
}


#pragma mark - ABPeoplePickerNavigationControllerDelegate
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker{
	//user canceled. lets de-select contact.
    _selectedType = DictionarySelectorLastSelectedTypeUndefined;
    [self updateSelectedName];
    [peoplePicker dismissModalViewControllerAnimated:YES];

    [self.tableView reloadData];
    
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person{
	//we need you to select a specific address so show the contact card for you to pick from.
	return YES;
}
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier{
	
	//Set the currently selected address to the labels value.
	if (property == kABPersonAddressProperty){
		//got an address.
        
        [peoplePicker dismissModalViewControllerAnimated:YES];
		ABMultiValueRef multi = [(id)ABRecordCopyValue(person, property) autorelease];
        NSArray *addresses = [(id)ABMultiValueCopyArrayOfAllValues(multi) autorelease];
		NSUInteger addressIndex = ABMultiValueGetIndexForIdentifier(multi, identifier);
        
		NSDictionary *addressDictionary = [addresses objectAtIndex:addressIndex];
        
        NSString *personName = [(NSString*)ABRecordCopyCompositeName(person) autorelease];
        NSString *addressLabelNonLocalized = [(NSString*)ABMultiValueCopyLabelAtIndex(multi, addressIndex) autorelease];
        NSString *addressLabel = [(NSString*)ABAddressBookCopyLocalizedLabel((CFStringRef)addressLabelNonLocalized) autorelease];

        
		NSLog(@"Selected Address: %@", addressDictionary);
        
        //store the dictionary into the selectedDictionary for geocoding.
        _selectedDictionary = [addressDictionary retain];
        
        //update the selected name to something more user friendly. eg "Richard Heard - Work"
        _selectedName = [[NSString stringWithFormat:@"%@ - %@", personName, [addressLabel capitalizedString]] retain];
        
        //change the selected type to Contact. 
        _selectedType = DictionarySelectorLastSelectedTypeContact;
        
        [self.tableView reloadData]; //reload to update cell with this info.

	}
	
	//don't do the default action.
	return NO;
}

@end
