#import "NYPLBook.h"
#import "NYPLMyBooksRegistry.h"

#import "NYPLMyBooksDownloadCenter.h"

@implementation NYPLMyBooksDownloadCenter

+ (NYPLMyBooksDownloadCenter *)sharedDownloadCenter
{
  static dispatch_once_t predicate;
  static NYPLMyBooksDownloadCenter *sharedDownloadCenter = nil;
  
  dispatch_once(&predicate, ^{
    sharedDownloadCenter = [[self alloc] init];
    if(!sharedDownloadCenter) {
      NYPLLOG(@"Failed to create shared download center.");
    }
  });
  
  return sharedDownloadCenter;
}

- (void)startDownloadForBook:(NYPLBook *const)book
{
  [[NYPLMyBooksRegistry sharedRegistry] addBook:book];
}

@end
