class OESettingsSplitViewController : UISplitViewController, UISplitViewControllerDelegate {
  fileprivate var isFirstLoad: Bool
  fileprivate let navVC: UINavigationController
  
  init() {
    self.isFirstLoad = true
    let primaryTableVC = OESettingsPrimaryTableViewController()
    self.navVC = UINavigationController.init(rootViewController: primaryTableVC)
    super.init(nibName: nil, bundle: nil)
    
    self.delegate = self
    self.title = NSLocalizedString("Settings", comment: "")
    self.tabBarItem.image = UIImage.init(named: "Settings")
    self.viewControllers = [self.navVC]
    self.presentsWithGesture = false
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: UIView
  override func viewDidLoad() {
    super.viewDidLoad()
    self.preferredDisplayMode = .allVisible
  }
  
  // MARK: UISplitViewControllerDelegate
  func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
    let rVal = self.isFirstLoad
    self.isFirstLoad = false
    return rVal
  }
}
