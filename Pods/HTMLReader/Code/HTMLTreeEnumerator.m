//  HTMLTreeEnumerator.m
//
//  Public domain. https://github.com/nolanw/HTMLReader

#import "HTMLTreeEnumerator.h"
#import "HTMLNode.h"

// For performance we'll cache the number of nodes at each level of the tree.
typedef struct {
    NSUInteger i;
    NSUInteger count;
} Row;

typedef struct {
    Row *path;
    NSUInteger length;
    NSUInteger capacity;
} IndexPath;

@implementation HTMLTreeEnumerator
{
    HTMLNode *_nextNode;
	BOOL _reversed;
    IndexPath _indexPath;
}

- (void)dealloc
{
    free(_indexPath.path);
}

- (id)initWithNode:(HTMLNode *)node reversed:(BOOL)reversed
{
    self = [super init];
    if (!self) return nil;
    
    _nextNode = node;
	_reversed = reversed;
    
    return self;
}

- (id)nextObject
{
    // This enumerator works by storing the *next* node we intend to emit, and the index path that points to that next node.
    HTMLNode *currentNode = _nextNode;
    
    NSUInteger numberOfChildren = currentNode.numberOfChildren;
    
    if (numberOfChildren > 0) {
        
        // Depth-first means the next node we'll emit is the current node's first child.
        if (_indexPath.length == _indexPath.capacity) {
            _indexPath.capacity += 16;
            _indexPath.path = reallocf(_indexPath.path, sizeof(_indexPath.path[0]) * _indexPath.capacity);
        }
        Row *row = _indexPath.path + _indexPath.length;
        _indexPath.length++;
        row->count = numberOfChildren;
        row->i = _reversed ? numberOfChildren - 1 : 0;
        _nextNode = [currentNode childAtIndex:row->i];
        
    } else {
        
        // We're out of children on this row, so walk back up the tree until we find a level with spare children.
        HTMLNode *parentNode = currentNode.parentNode;
        while (_indexPath.length > 0) {
            Row *row = _indexPath.path + _indexPath.length - 1;
            if (_reversed && row->i > 0) {
                row->i--;
            } else if (!_reversed && row->i + 1 < row->count) {
                row->i++;
            } else {
                _indexPath.length--;
                parentNode = parentNode.parentNode;
                continue;
            }
            _nextNode = [parentNode childAtIndex:row->i];
            break;
        }
        
        // No more spare children means we're done.
        if (_indexPath.length == 0) {
            _nextNode = nil;
        }
    }
    return currentNode;
}

@end
