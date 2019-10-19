class SECatalogNavigationController : NYPLCatalogNavigationController {
  override func loadTopLevelCatalogViewController() {
    super.loadTopLevelCatalogViewController()
    // The top-level view controller uses the same image used for the tab bar in place of the usual
    // title text.
    self.viewController.navigationItem.leftBarButtonItem = UIBarButtonItem.init(
      image: UIImage.init(named: "Catalog"),
      style: .plain,
      target: self,
      action: #selector(switchLibrary)
    )
    self.viewController.navigationItem.leftBarButtonItem.accessibilityLabel = NSLocalizedString("AccessibilitySwitchLibrary", "nil")
  }
  
  
}
