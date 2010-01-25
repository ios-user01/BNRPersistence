// The MIT License
//
// Copyright (c) 2008 Big Nerd Ranch, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "BNRStoredObject.h"
#import "BNRStore.h"
#import "BNRStoreBackend.h"
#import "BNRIntDictionary.h"
#import "BNRClassDictionary.h"

@interface BNRStore (StoredObjectIsFriend)

- (BNRClassDictionary *)uniquingTable;

@end


@implementation BNRStore (StoredObjectIsFriend)

- (BNRClassDictionary *)uniquingTable
{
    return uniquingTable;
}
@end


@implementation BNRStoredObject

- (id)init
{
    [super init];
    // Retain count of 1 + hasContent
    status = 3;
    return self;
}

- (void)setStore:(BNRStore *)s
{
    store = s;
}

- (BNRStore *)store
{
    return store;
}

#pragma mark Getting data in and out
- (void)readContentFromBuffer:(BNRDataBuffer *)d
{
    // NOOP, must be overridden by subclass
}
- (void)writeContentToBuffer:(BNRDataBuffer *)d
{
    // NOOP, must be overridden by subclass
}
- (void)dissolveAllRelationships
{
    // NOOP, may be overridden by subclass
}
- (void)prepareForDelete
{
    // NOOP, may be overridden by subclass 
}

- (UInt32)rowID
{
    return rowID;
}
- (void)setRowID:(UInt32)n
{
    rowID = n;
}

- (BOOL)hasContent
{
    return status % 2;
}
- (void)setHasContent:(BOOL)yn
{
    // Do I currently have content?
    if ([self hasContent]) {
        if (yn == NO)
            status--;
    } else {
        if (yn == YES)
            status++;
    }
}
- (void)fetchContent
{
    if (rowID == 0) {
        return;
    }
    BNRStoreBackend *backend = [[self store] backend];
    BNRDataBuffer *d = [backend dataForClass:[self class]
                                       rowID:[self rowID]];
    if (!d) {
        return;
    }
    [self readContentFromBuffer:d];
    [self setHasContent:YES];
}

- (void)checkForContent
{
    if (![self hasContent]) {
        [self fetchContent];
    }
}

- (NSUInteger)retainCount
{
    return status / 2;
}

- (id)retain
{
    status += 2;
    return self;
}

// Called if the store is deallocated before the stored object
- (void)clearStore
{
    [self setStore:nil];
}

- (void)dealloc
{
    // FIXME: this needs to happen
    BNRClassDictionary *uniquingTable = [store uniquingTable];
    BNRIntDictionary *intDict = [uniquingTable objectForClass:[self class]];
    [intDict removeObjectForInt:[self rowID]];
    [super dealloc];
}

- (oneway void)release
{
    status -= 2;

    if (status < 2) {
        [self dealloc];
    }
    
}

@end