//
//  CoreDataBookAppDelegate.m
//  CoreDataBook
//
//  Created by Matthew Chavez on 2/12/11.
//  Copyright 2011 Big Cat Dev. All rights reserved.
//

#import "CoreDataBookAppDelegate.h"

@implementation CoreDataBookAppDelegate

@synthesize window, recipeArrayController, recipeIngredientsController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}

/**
    Returns the directory the application uses to store the Core Data store file. This code uses a directory named "CoreDataBook" in the user's Library directory.
 */
- (NSURL *)applicationFilesDirectory {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *libraryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    return [libraryURL URLByAppendingPathComponent:@"CoreDataBook"];
}

/**
    Creates if necessary and returns the managed object model for the application.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (__managedObjectModel) {
        return __managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CoreDataBook" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return __managedObjectModel;
}

/**
    Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
 */
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    if (__persistentStoreCoordinator) {
        return __persistentStoreCoordinator;
    }

    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:&error];
        
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    else {
        if ([[properties objectForKey:NSURLIsDirectoryKey] boolValue] != YES) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]]; 
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"CoreDataBook.storedata"];
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        [__persistentStoreCoordinator release], __persistentStoreCoordinator = nil;
        return nil;
    }

    return __persistentStoreCoordinator;
}

/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
- (NSManagedObjectContext *) managedObjectContext {
    if (__managedObjectContext) {
        return __managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    __managedObjectContext = [[NSManagedObjectContext alloc] init];
    [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease]; 
    [request setEntity:[NSEntityDescription entityForName:@"Type"
                                   inManagedObjectContext:__managedObjectContext]];
    NSError *error = nil; 
    NSArray *result = [__managedObjectContext executeFetchRequest:request error:&error];
    NSAssert(error == nil, [error localizedDescription]);
    
    if ([result count]) 
        return __managedObjectContext;
    
    NSArray *types; 
    types = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"RecipeTypes"];
    for (NSString *type in types) { 
        NSManagedObject *object = 
            [NSEntityDescription insertNewObjectForEntityForName:@"Type"
                                          inManagedObjectContext:__managedObjectContext]; 
        [object setValue:type forKey:@"name"];
    }
    
    
    return __managedObjectContext;
}

/**
    Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
 */
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}

/**
    Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
 */
- (IBAction) saveAction:(id)sender {
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }

    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    // Save changes in the application's managed object context before the application terminates.

    if (!__managedObjectContext) {
        return NSTerminateNow;
    }

    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }

    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        [alert release];
        alert = nil;
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

- (void)dealloc
{
    [__managedObjectContext release];
    [__persistentStoreCoordinator release];
    [__managedObjectModel release];
    [super dealloc];
}

- (NSString *)applicationSupportFolder {
    NSString *applicationSupportFolder = nil;
    FSRef foundRef;
    OSErr err = FSFindFolder(kUserDomain, kApplicationSupportFolderType, kDontCreateFolder, &foundRef);
    if (err == noErr) {
        unsigned char path[PATH_MAX];
        OSStatus validPath = FSRefMakePath(&foundRef, path, sizeof(path));
        if (validPath == noErr)
        {
            applicationSupportFolder = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:path length:(NSUInteger)strlen((char*)path)];
        }
    }
    return [applicationSupportFolder stringByAppendingPathComponent:@"CoreDataBook"];
}

#pragma -
#pragma Button Actions

- (IBAction)addImage:(id)sender {
    id recipe = [[recipeArrayController selectedObjects] lastObject]; 
    
    if (!recipe) return;
    
    NSOpenPanel *openPanel = [[NSOpenPanel openPanel] retain];
    [openPanel setCanChooseDirectories:NO]; 
    [openPanel setCanCreateDirectories:NO]; 

    NSArray* fileTypes = [NSArray arrayWithObjects:@"jpg", @"gif", @"png", @"tiff", nil];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setMessage:@"Choose an image file to display:"];
    
    [openPanel beginSheetForDirectory:nil
                                 file:nil
                                types:fileTypes
                       modalForWindow:window
                        modalDelegate:self 
                       didEndSelector:@selector(addImageSheetDidEnd:returnCode:contextInfo:)
                          contextInfo:recipe];
}

- (void)addImageSheetDidEnd:(NSOpenPanel*)openPanel 
                 returnCode:(NSInteger)returnCode 
                contextInfo:(NSManagedObject*)recipe 
{
    if (returnCode == NSCancelButton) return; 
    
    NSString *path = [openPanel filename];
    //Build the path we want the file to be at
    NSString *destPath = [self applicationSupportFolder];
//    NSString *applicationSupportFolder =
//    (NSString *)[[NSFileManager defaultManager] findSystemFolderType:kApplicationSupportFolderType 
//                                                           forDomain:kUserDomain];
    NSString *guid = [[NSProcessInfo processInfo] globallyUniqueString]; 
    destPath = [destPath stringByAppendingPathComponent:guid]; 
    
    NSError *error = nil;
    [[NSFileManager defaultManager] copyItemAtPath:path toPath:destPath
                                             error:&error];
    if (error)
        [NSApp presentError:error];
    
    [recipe setValue:destPath forKey:@"imagePath"];
}

@end
