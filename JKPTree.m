//
//  JKPTree.h
//  A simple CFTree Cocoa wrapper.
//
//  Created by Jamie Kirkpatrick on 02/04/2006.
//  Copyright 2006 JKP. All rights reserved.  
//
//  Released under the BSD software licence.
//

#import "JKPTree.h"
#import <CoreFoundation/CFString.h>
#import <CoreFoundation/CFTree.h>

//---------------------------------------------------------- 
//  JKPTreeCreateContext()
//---------------------------------------------------------- 
CFTreeContext JKPTreeCreateContext( id content )
{
    CFTreeContext context;
    memset( &context, 0, sizeof( CFTreeContext ) );
#if __has_feature(objc_arc)
  context.info            = (__bridge void *) content;
#else
  context.info            = (void *) content;  
#endif
    context.retain          = CFRetain;
    context.release         = CFRelease;
    context.copyDescription = CFCopyDescription;
    return context;
}

#pragma mark -

@interface JKPTree (Private)
- (id) initWithCFTree:(CFTreeRef)backing;
@end

#pragma mark -

@implementation JKPTree

//---------------------------------------------------------- 
//  treeWithContentObject:
//---------------------------------------------------------- 
+ (id) treeWithContentObject:(id)theContentObject;
{
  id object = [[self alloc] initWithContentObject:theContentObject];
#if __has_feature(objc_arc)
  return object;
#else
  return [object autorelease]
#endif
}

//---------------------------------------------------------- 
//  initWithContentObject:
//---------------------------------------------------------- 
- (id) initWithContentObject:(id)theContentObject;
{
    self = [super init];
    if ( !self )
        return nil;
    
    CFTreeContext theContext = JKPTreeCreateContext( theContentObject );
    treeBacking = CFTreeCreate( kCFAllocatorDefault, &theContext );
    
    return self;
}

//---------------------------------------------------------- 
//  dealloc
//---------------------------------------------------------- 
- (void) dealloc;
{
    CFRelease( treeBacking );
#if !__has_feature(objc_arc)
  [super dealloc];
#endif

}

#pragma mark -
#pragma mark adding / removing children

//---------------------------------------------------------- 
//  addChildObject:
//---------------------------------------------------------- 
- (void) addChildObject:(id)childObject;
{
    CFTreeContext theContext = JKPTreeCreateContext( childObject );
    CFTreeRef childTree = CFTreeCreate( kCFAllocatorDefault, &theContext );
    CFTreeAppendChild( treeBacking, childTree );
    CFRelease( childTree );
}

//---------------------------------------------------------- 
//  addChildObject:atIndex:
//---------------------------------------------------------- 
- (void) addChildObject:(id)childObject atIndex:(NSUInteger)index;
{
    CFTreeContext theContext = JKPTreeCreateContext( childObject );
    CFTreeRef childTree = CFTreeCreate( kCFAllocatorDefault, &theContext );
    CFTreeRef precedingSibling = CFTreeGetChildAtIndex( treeBacking, (CFIndex) index - 1U );
    CFTreeInsertSibling( precedingSibling, childTree );
    CFRelease( childTree );
}

//---------------------------------------------------------- 
//  removeChildObject:
//---------------------------------------------------------- 
- (BOOL) removeChildObject:(id)childObject;
{
    // grab pointers to all the children...
    CFIndex childCount = CFTreeGetChildCount( treeBacking );
    CFTreeRef *children = (CFTreeRef *)malloc( childCount * sizeof( CFTreeRef ) );
    CFTreeGetChildren( treeBacking, children );
    
    // iterate over the children....if a child matches, then remove it and stop...
    BOOL result = NO;
    CFIndex i;
    for ( i = 0; i < childCount; i++ )
    {
        CFTreeRef child = children[i];
        CFTreeContext theContext;
        CFTreeGetContext( child, &theContext );
        
        // is this the node...?
#if __has_feature(objc_arc)
      if ( ![childObject isEqual:(__bridge id)theContext.info] )
        continue;
#else
      if ( ![childObject isEqual:(id)theContext.info] )
        continue;
#endif
        
        // we found it...
        result = YES;
        CFTreeRemove( child );
    }
    
    // cleanup and return result...
    free( children );
    return result;
}

//---------------------------------------------------------- 
//  removeChildObjectAtIndex: 
//---------------------------------------------------------- 
- (void) removeChildObjectAtIndex:(NSUInteger)index;
{
    CFTreeRef child = CFTreeGetChildAtIndex( treeBacking, (CFIndex)index );
    CFTreeRemove( child );
}

//---------------------------------------------------------- 
//  removeAllChildren
//---------------------------------------------------------- 
- (void) removeAllChildren;
{
    CFTreeRemoveAllChildren( treeBacking);
}

#pragma mark -
#pragma mark examining the tree

//---------------------------------------------------------- 
//  root
//---------------------------------------------------------- 
- (JKPTree *) root;
{
    CFTreeRef root = CFTreeFindRoot( treeBacking );
  JKPTree *jRoot = [[JKPTree alloc] initWithCFTree:root];
#if __has_feature(objc_arc)
  return jRoot;
#else
  return [jRoot autorelease]
#endif
}

//---------------------------------------------------------- 
//  parent
//---------------------------------------------------------- 
- (JKPTree *) parent;
{
    CFTreeRef parent = CFTreeGetParent( treeBacking );
  if ( parent != NULL ) {
    JKPTree *jRoot = [[JKPTree alloc] initWithCFTree:parent];
#if __has_feature(objc_arc)
    return jRoot;
#else
    return [jRoot autorelease]
#endif
  }
    return nil;
}

//---------------------------------------------------------- 
//  firstChild
//---------------------------------------------------------- 
- (JKPTree *) firstChild;
{
    CFTreeRef firstChild = CFTreeGetFirstChild( treeBacking );
  if ( firstChild != NULL ) {
    JKPTree *jFirstChild = [[JKPTree alloc] initWithCFTree:firstChild];
#if __has_feature(objc_arc)
    return jFirstChild;
#else
    return [jFirstChild autorelease]
#endif
  }
  return nil;
}

//---------------------------------------------------------- 
//  nextSibling
//---------------------------------------------------------- 
- (JKPTree *) nextSibling;
{
    CFTreeRef nextSibling = CFTreeGetNextSibling( treeBacking );
  if ( nextSibling != NULL ) {
    JKPTree *jNextSibling = [[JKPTree alloc] initWithCFTree:nextSibling];
#if __has_feature(objc_arc)
    return jNextSibling;
#else
    return [jNextSibling autorelease]
#endif
  }
    return nil;
}

//---------------------------------------------------------- 
//  childCount
//---------------------------------------------------------- 
- (NSUInteger) childCount;
{
    return (NSUInteger)CFTreeGetChildCount( treeBacking );
}

//---------------------------------------------------------- 
//  nodeAtIndex:
//---------------------------------------------------------- 
- (JKPTree *) nodeAtIndex:(NSUInteger)index;
{
    CFTreeRef child = CFTreeGetChildAtIndex( treeBacking, (CFIndex)index );
  if ( child != NULL ) {
    JKPTree *jChild = [[JKPTree alloc] initWithCFTree:child];
#if __has_feature(objc_arc)
    return jChild;
#else
    return [jChild autorelease]
#endif    
  }
  return nil;
}

//---------------------------------------------------------- 
//  childObjectAtIndex:
//---------------------------------------------------------- 
- (id)childObjectAtIndex:(NSUInteger)index;
{
    CFTreeRef child = CFTreeGetChildAtIndex( treeBacking, (CFIndex)index );
    CFTreeContext theContext;
    CFTreeGetContext( child, &theContext );
#if __has_feature(objc_arc)
  return (__bridge id)theContext.info;
#else  
    return (id)theContext.info;
#endif
}

//---------------------------------------------------------- 
//  allSiblings
//---------------------------------------------------------- 
- (NSArray *) allSiblingNodes;
{
    return [[self parent] childNodes];
}

//---------------------------------------------------------- 
//  allSiblingObjects
//---------------------------------------------------------- 
- (NSArray *) allSiblingObjects;
{
    return [[self parent] childObjects];
}

//---------------------------------------------------------- 
//  childNodes
//---------------------------------------------------------- 
- (NSArray *) childNodes;
{
    // grab pointers to all the children...
    CFIndex childCount = CFTreeGetChildCount( treeBacking );
    CFTreeRef *children = (CFTreeRef *)malloc( childCount * sizeof( CFTreeRef ) );
    CFTreeGetChildren( treeBacking, children );
    
    // iterate over the children extracting contentObjects and adding to array...
    NSMutableArray *childWrappers = [NSMutableArray arrayWithCapacity:childCount];
    CFIndex i;
    for ( i = 0; i < childCount; i++ )
    {
        JKPTree *child = [[JKPTree alloc] initWithCFTree:children[i]];
        [childWrappers addObject:child];
#if !__has_feature(objc_arc)
        [child release];
#endif
    }
    
    // cleanup and return result...
    free( children );
#if __has_feature(objc_arc)
  return ( childCount ? [childWrappers copy] : nil );
#else
  return ( childCount ? [[childWrappers copy] autorelease] : nil );
#endif
}

//---------------------------------------------------------- 
//  childObjects
//---------------------------------------------------------- 
- (NSArray *) childObjects;
{
    // grab pointers to all the children...
    CFIndex childCount = CFTreeGetChildCount( treeBacking );
    CFTreeRef *children = (CFTreeRef *)malloc( childCount * sizeof( CFTreeRef ) );
    CFTreeGetChildren( treeBacking, children );
    
    // iterate over the children wrapping each in turn and adding to the return array...
    NSMutableArray *childObjects = [NSMutableArray arrayWithCapacity:childCount];
    CFIndex i;
    for ( i = 0; i < childCount; i++ )
    {
        CFTreeContext theContext;
        CFTreeGetContext( children[i], &theContext );
#if __has_feature(objc_arc)
      if ( (__bridge id)theContext.info )
        [childObjects addObject:(__bridge id)theContext.info];
#else
      if ( (id)theContext.info )
        [childObjects addObject:(id)theContext.info];
#endif
    }
    
    // cleanup and return result...
    free( children );
#if __has_feature(objc_arc) 
  return ( [childObjects count] ? [childObjects copy] : nil );
#else
  return ( [childObjects count] ? [[childObjects copy] autorelease] : nil );
#endif
}

//---------------------------------------------------------- 
//  isLeaf
//---------------------------------------------------------- 
- (BOOL) isLeaf;
{
    return ( (NSUInteger)CFTreeGetChildCount( treeBacking ) ? NO : YES );
}

#pragma mark -
#pragma mark accessors

//---------------------------------------------------------- 
//  contentObject
//---------------------------------------------------------- 
- (id) contentObject;
{
    CFTreeContext theContext;
    CFTreeGetContext( treeBacking, &theContext );
#if __has_feature(objc_arc)
  return (__bridge id)theContext.info;
#else
  return (id)theContext.info;
#endif
}

//---------------------------------------------------------- 
//  setContentObject:
//---------------------------------------------------------- 
- (void) setContentObject: (id) theContentObject;
{
    CFTreeContext theContext = JKPTreeCreateContext( theContentObject );
    CFTreeSetContext( treeBacking, &theContext );
}

@end

#pragma mark -

@implementation JKPTree (Private)

//---------------------------------------------------------- 
//  initWithCFTree:
//---------------------------------------------------------- 
- (id) initWithCFTree:(CFTreeRef)backing;
{
    self = [super init];
    if ( !self )
        return nil;
    
    CFRetain( backing );
    treeBacking = backing;
    
    return self;
}

@end

