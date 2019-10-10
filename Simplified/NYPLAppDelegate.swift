import Foundation

import NYPLAudiobookToolkit;

fileprivate let MinimumBackgroundFetchInterval = TimeInterval(60 * 60 * 24)

class NYPLAppDelegate: UIResponder, UIApplicationDelegate {
  // Public members
  var window: UIWindow?
  
  // Private members
  private var audiobookLifecycleManager: AudiobookLifecycleManager
    
  // Initializer
  override init() {
    self.audiobookLifecycleManager = AudiobookLifecycleManager()
    super.init()
  }

  // MARK: UIApplicationDelegate
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Perform data migrations as early as possible before anything has a chance to access them
    NYPLKeychainManager.validateKeychain()
    
    MigrationManager.migrate()
    
    self.audiobookLifecycleManager.didFinishLaunching()

    UIApplication.shared.setMinimumBackgroundFetchInterval(MinimumBackgroundFetchInterval)

    if #available(iOS 10.0, *) {
      NYPLUserNotifications.init().authorizeIfNeeded()
    }

    // This is normally not called directly, but we put all programmatic appearance setup in
    // NYPLConfiguration's class initializer.
    NYPLConfiguration.initialize()

    NetworkQueue.shared().addObserverForOfflineQueue()

    self.window = UIWindow.init(frame: UIScreen.main.bounds)
    self.window!.tintColor = NYPLConfiguration.mainColor()
    self.window!.tintAdjustmentMode = .normal;
    self.window!.makeKeyAndVisible()
    self.window!.rootViewController = NYPLRootTabBarController.shared();

    //self.beginCheckingForUpdates()

    return true;
  }
  
  func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    var bgTask = UIBackgroundTaskIdentifier.invalid
    bgTask = application.beginBackgroundTask(expirationHandler: {
      NYPLBugsnagLogs.reportExpiredBackgroundFetch()
      completionHandler(.failed)
      application.endBackgroundTask(bgTask)
    })
    
    Log.info("", "[BackgroundFetch] Starting background fetch block")
    if #available(iOS 10.0, *), NYPLUserNotifications.backgroundFetchIsNeeded() {
      // Only the "current library" account syncs during a background fetch.
      NYPLBookRegistry.shared()?.sync(completionHandler: { (success) in
        if (success) {
          NYPLBookRegistry.shared()?.save()
        }
      }, backgroundFetchHandler: { (result) in
        Log.info("BackgroundFetch", "Completed with result")
        completionHandler(result)
        application.endBackgroundTask(bgTask)
      })
    } else {
      Log.info("BackgroundFetch", "Fetch wasn't needed")
      completionHandler(.noData)
      application.endBackgroundTask(bgTask)
    }
  }
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
     // URLs should be a permalink to a feed URL
    guard var components = URLComponents.init(url: url, resolvingAgainstBaseURL: false) else {
      reportErrorForOpenUrl(reason: "Could not parse url \(url.absoluteString)")
      return false
    }
    components.scheme = "http";
    guard let entryURL = components.url else {
      reportErrorForOpenUrl(reason: "Could not reform url \(url.absoluteString)")
      return false
    }
    guard let data = try? Data.init(contentsOf: entryURL) else {
      reportErrorForOpenUrl(reason: "Could not load data from \(entryURL.absoluteString)")
      return false
    }
    guard let xml = NYPLXML.init(data: data) else {
      reportErrorForOpenUrl(reason: "Could not parse data from \(entryURL.absoluteString)")
      return false
    }
    guard let entry = NYPLOPDSEntry.init(xml: xml) else {
      reportErrorForOpenUrl(reason: "Could not parse entry from \(entryURL.absoluteString)")
      return false
    }
    guard let book = NYPLBook.init(entry: entry) else {
      reportErrorForOpenUrl(reason: "Could not parse book from \(entryURL.absoluteString)")
      return false
    }
    
    let bookDetailVC = NYPLBookDetailViewController.init(book: book)
    guard let tbc = self.window?.rootViewController, tbc.selectedViewController.isKindOfClass(UINavigationController.class) else {
      
    }
    
//
//     NYPLBookDetailViewController *bookDetailVC = [[NYPLBookDetailViewController alloc] initWithBook:book];
//     NYPLRootTabBarController *tbc = (NYPLRootTabBarController *) self.window.rootViewController;
//
//     if (!tbc || ![tbc.selectedViewController isKindOfClass:[UINavigationController class]]) {
//       NYPLLOG(@"Casted views were not of expected types.");
//       return NO;
//     }
//
//     [tbc setSelectedIndex:0];
//
//     UINavigationController *navFormSheet = (UINavigationController *) tbc.selectedViewController.presentedViewController;
//     if (tbc.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
//       [tbc.selectedViewController pushViewController:bookDetailVC animated:YES];
//     } else if (navFormSheet) {
//       [navFormSheet pushViewController:bookDetailVC animated:YES];
//     } else {
//       UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:bookDetailVC];
//       navVC.modalPresentationStyle = UIModalPresentationFormSheet;
//       [tbc.selectedViewController presentViewController:navVC animated:YES completion:nil];
//     }

     return true;
  }

// - (BOOL)application:(__unused UIApplication *)app
//             openURL:(NSURL *)url
//             options:(__unused NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
// {
//   // URLs should be a permalink to a feed URL
//   NSURL *entryURL = [url URLBySwappingForScheme:@"http"];
//   NSData *data = [NSData dataWithContentsOfURL:entryURL];
//   NYPLXML *xml = [NYPLXML XMLWithData:data];
//   NYPLOPDSEntry *entry = [[NYPLOPDSEntry alloc] initWithXML:xml];
  
//   NYPLBook *book = [NYPLBook bookWithEntry:entry];
//   if (!book) {
//     NSString *alertTitle = @"Error Opening Link";
//     NSString *alertMessage = @"There was an error opening the linked book.";
//     UIAlertController *alert = [NYPLAlertUtils alertWithTitle:alertTitle message:alertMessage];
//     [NYPLAlertUtils presentFromViewControllerOrNilWithAlertController:alert viewController:nil animated:YES completion:nil];
//     NYPLLOG(@"Failed to create book from deep-linked URL.");
//     return NO;
//   }
  
//   NYPLBookDetailViewController *bookDetailVC = [[NYPLBookDetailViewController alloc] initWithBook:book];
//   NYPLRootTabBarController *tbc = (NYPLRootTabBarController *) self.window.rootViewController;

//   if (!tbc || ![tbc.selectedViewController isKindOfClass:[UINavigationController class]]) {
//     NYPLLOG(@"Casted views were not of expected types.");
//     return NO;
//   }

//   [tbc setSelectedIndex:0];

//   UINavigationController *navFormSheet = (UINavigationController *) tbc.selectedViewController.presentedViewController;
//   if (tbc.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
//     [tbc.selectedViewController pushViewController:bookDetailVC animated:YES];
//   } else if (navFormSheet) {
//     [navFormSheet pushViewController:bookDetailVC animated:YES];
//   } else {
//     UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:bookDetailVC];
//     navVC.modalPresentationStyle = UIModalPresentationFormSheet;
//     [tbc.selectedViewController presentViewController:navVC animated:YES completion:nil];
//   }

//   return YES;
// }

// - (void)applicationWillResignActive:(__attribute__((unused)) UIApplication *)application
// {
//   [[NYPLBookRegistry sharedRegistry] save];
//   [[NYPLReaderSettings sharedSettings] save];
// }

// - (void)applicationWillTerminate:(__unused UIApplication *)application
// {
//   [self.audiobookLifecycleManager willTerminate];
//   [[NYPLBookRegistry sharedRegistry] save];
//   [[NYPLReaderSettings sharedSettings] save];
// }

// - (void)application:(__unused UIApplication *)application
// handleEventsForBackgroundURLSession:(NSString *const)identifier
// completionHandler:(void (^const)(void))completionHandler
// {
//   [self.audiobookLifecycleManager
//    handleEventsForBackgroundURLSessionFor:identifier
//    completionHandler:completionHandler];
// }

  // MARK: -
  
  func reportErrorForOpenUrl(reason: String) {
    
  }

// - (void)beginCheckingForUpdates
// {
//   [UpdateCheckShim
//    performUpdateCheckWithURL:[NYPLConfiguration minimumVersionURL]
//    handler:^(NSString *_Nonnull version, NSURL *_Nonnull updateURL) {
//      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//        UIAlertController *const alertController =
//          [UIAlertController
//           alertControllerWithTitle:NSLocalizedString(@"AppDelegateUpdateRequiredTitle", nil)
//           message:[NSString stringWithFormat:NSLocalizedString(@"AppDelegateUpdateRequiredMessageFormat", nil), version]
//           preferredStyle:UIAlertControllerStyleAlert];
//        [alertController addAction:
//         [UIAlertAction
//          actionWithTitle:NSLocalizedString(@"AppDelegateUpdateNow", nil)
//          style:UIAlertActionStyleDefault
//          handler:^(__unused UIAlertAction *_Nonnull action) {
//            [[UIApplication sharedApplication] openURL:updateURL];
//          }]];
//        [alertController addAction:
//         [UIAlertAction
//          actionWithTitle:NSLocalizedString(@"AppDelegateUpdateRemindMeLater", nil)
//          style:UIAlertActionStyleCancel
//          handler:nil]];
//        [self.window.rootViewController
//         presentViewController:alertController
//         animated:YES
//         completion:^{
//           // Try again in 24 hours or on next launch, whichever is sooner.
//           [self performSelector:@selector(beginCheckingForUpdates)
//                      withObject:nil
//                      afterDelay:(60 * 60 * 24)];
//         }];
//      }];
//    }];
// }

// @end

}
