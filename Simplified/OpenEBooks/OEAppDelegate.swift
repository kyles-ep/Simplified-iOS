fileprivate let MinimumBackgroundFetchInterval = TimeInterval(60 * 60 * 24)

extension Notification.Name {
  static let NYPLAppDelegateDidReceiveCleverRedirectURL = Notification.Name("NYPLAppDelegateDidReceiveCleverRedirectURL")
}

@UIApplicationMain
class OEAppDelegate : NYPLAppDelegate, UIApplicationDelegate {
  override init() {
    super.init()
  }

  // MARK: UIApplicationDelegate

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    OEMigrationManager.migrate()
    
    self.audiobookLifecycleManager.didFinishLaunching()

    UIApplication.shared.setMinimumBackgroundFetchInterval(MinimumBackgroundFetchInterval)

    if #available(iOS 10.0, *) {
      NYPLUserNotifications.init().authorizeIfNeeded()
    }

    // This is normally not called directly, but we put all programmatic appearance setup in
    // NYPLConfiguration's class initializer.
    OEConfiguration.initConfig()

    NetworkQueue.shared().addObserverForOfflineQueue()

    self.window = UIWindow.init(frame: UIScreen.main.bounds)
    self.window!.tintColor = NYPLConfiguration.shared.mainColor
    self.window!.tintAdjustmentMode = .normal
    self.window!.makeKeyAndVisible()
    
    NYPLRootTabBarController.shared()?.setCatalogNav(OECatalogNavigationController())
    NYPLRootTabBarController.shared()?.setMyBooksNav(OEMyBooksNavigationController())
    NYPLRootTabBarController.shared()?.setHoldsNav(OEHoldsNavigationController())
    NYPLRootTabBarController.shared()?.setSettingsSplitView(OESettingsSplitViewController())
    
    if NYPLSettings.shared.userHasSeenWelcomeScreen {
      self.window!.rootViewController = NYPLRootTabBarController.shared()
    } else {
      self.window!.rootViewController = OETutorialViewController()
    }
    
    self.beginCheckingForUpdates()

    return true;
  }
}
