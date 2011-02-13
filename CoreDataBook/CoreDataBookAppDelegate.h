//
//  CoreDataBookAppDelegate.h
//  CoreDataBook
//
//  Created by Matthew Chavez on 2/12/11.
//  Copyright 2011 Big Cat Dev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CoreDataBookAppDelegate : NSObject <NSApplicationDelegate> {
    NSArrayController *recipeArrayController;
@private
    NSWindow *window;
    NSPersistentStoreCoordinator *__persistentStoreCoordinator;
    NSManagedObjectModel *__managedObjectModel;
    NSManagedObjectContext *__managedObjectContext;
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, assign) IBOutlet NSArrayController *recipeArrayController;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:sender;
- (IBAction)addImage:(id)sender;

@end
