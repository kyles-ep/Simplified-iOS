fileprivate let MinimumBackgroundFetchInterval = TimeInterval(60 * 60 * 24)

@UIApplicationMain
class SEAppDelegate : NYPLAppDelegate, UIApplicationDelegate {
  override init() {
    super.init()
  }

  // MARK: UIApplicationDelegate

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    // Swap superclass shared value with subclass
    NYPLConfiguration.shared = SEConfiguration.seShared
    
    // Perform data migrations as early as possible before anything has a chance to access them
    NYPLKeychainManager.validateKeychain()
    
    SEMigrationManager.migrate()
    
    AccountsManager.shared.delayedInit()
    
    self.audiobookLifecycleManager.didFinishLaunching()

    UIApplication.shared.setMinimumBackgroundFetchInterval(MinimumBackgroundFetchInterval)

    if #available(iOS 10.0, *) {
      NYPLUserNotifications.init().authorizeIfNeeded()
    }

    // This is normally not called directly, but we put all programmatic appearance setup in
    // NYPLConfiguration's class initializer.
    NYPLConfiguration.initConfig()

    NetworkQueue.shared().addObserverForOfflineQueue()

    self.window = UIWindow.init(frame: UIScreen.main.bounds)
    self.window!.tintColor = NYPLConfiguration.shared.mainColor
    self.window!.tintAdjustmentMode = .normal
    self.window!.makeKeyAndVisible()
    
    NYPLRootTabBarController.shared()?.setCatalogNav(SECatalogNavigationController())
    NYPLRootTabBarController.shared()?.setMyBooksNav(SEMyBooksNavigationController())
    NYPLRootTabBarController.shared()?.setHoldsNav(SEHoldsNavigationController())
    
    if NYPLSettings.shared.userHasSeenWelcomeScreen {
      self.window!.rootViewController = NYPLRootTabBarController.shared()
    } else {
      self.window!.rootViewController = SETutorialViewController()
    }
    
    self.beginCheckingForUpdates()

    return true;
  }
}
