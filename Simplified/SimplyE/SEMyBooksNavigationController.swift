class SEMyBooksNavigationController : NYPLMyBooksNavigationController {
  override init() {
    super.init()
    self.topViewController?.navigationItem.leftBarButtonItem = UIBarButtonItem.init(image: UIImage.init(named: "Catalog"), style: .plain, target: self, action: #selector(switchLibrary))
    self.topViewController?.navigationItem.leftBarButtonItem?.accessibilityLabel = NSLocalizedString("AccessibilitySwitchLibrary", tableName: "", comment: "")
    self.topViewController?.navigationItem.leftBarButtonItem?.isEnabled = true
  }
  
  @objc func switchLibrary() {
    let viewController = self.visibleViewController as? NYPLMyBooksViewController
    let style = (viewController != nil) ? UIAlertController.Style.actionSheet : UIAlertController.Style.alert
    let alert = UIAlertController.init(title: NSLocalizedString("PickYourLibrary", comment: ""), message: nil, preferredStyle: style)
    alert.popoverPresentationController?.barButtonItem = viewController?.navigationItem.leftBarButtonItem
    alert.popoverPresentationController?.permittedArrowDirections = .up
    
    let accounts = NYPLSettings.shared.settingsAccountsList
    for acct in accounts {
      guard let account = AccountsManager.shared.account(acct) else {
        continue
      }
      
      alert.addAction(UIAlertAction.init(title: account.name, style: .default, handler: { (action) in
        var workflowsInProgress = NYPLBookRegistry.shared()?.syncing ?? false
        #if FEATURE_DRM_CONNECTOR
        workflowsInProgress = workflowsInProgress || (NYPLADEPT.sharedInstance()?.workflowsInProgress ?? false)
        #endif
        
        if (workflowsInProgress) {
          self.present(NYPLAlertUtils.alert(title: "PleaseWait", message: "PleaseWaitMessage"), animated: true, completion: nil)
        } else {
          NYPLBookRegistry.shared()?.save()
          AccountsManager.sharedInstance().currentAccount = account
          self.reloadSelected()
        }
      }))
    }
    
    alert.addAction(UIAlertAction.init(title: NSLocalizedString("ManageAccounts", comment: ""), style: .default, handler: { (action) in
      let tabCount = NYPLRootTabBarController.shared()?.viewControllers?.count ?? 1
      let splitViewVC = NYPLRootTabBarController.shared()?.viewControllers?.last as? UISplitViewController
      let masterNavVC = splitViewVC?.viewControllers.first as? UINavigationController
      masterNavVC?.popToRootViewController(animated: false)
      NYPLRootTabBarController.shared().selectedIndex = tabCount - 1
      let tableVC = masterNavVC?.viewControllers.first as? NYPLSettingsPrimaryTableViewController
      tableVC?.delegate.settingsPrimaryTableViewController(tableVC, didSelect: .account)
    }))
    
    alert.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
    
    NYPLRootTabBarController.shared()?.safelyPresentViewController(alert, animated: true, completion: nil)
  }
  
  func reloadSelected() {
    let catalog = NYPLRootTabBarController.shared()?.viewControllers?.first as? NYPLCatalogNavigationController
    catalog?.updateFeedAndRegistryOnAccountChange()
    
    let viewController = self.visibleViewController as? NYPLHoldsViewController
    viewController?.navigationItem.title = AccountsManager.sharedInstance().currentAccount?.name
  }
}
