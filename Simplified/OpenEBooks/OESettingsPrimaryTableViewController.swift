import HelpStack

fileprivate func generateRemoteView(title: String, url: String) -> UIViewController {
  let remoteView = RemoteHTMLViewController.init(
    URL: URL.init(string: url)!,
    title: title,
    failureMessage: NSLocalizedString("SettingsConnectionFailureMessage", comment: "")
  )
  if UIDevice.current.userInterfaceIdiom == .pad {
    return UINavigationController.init(rootViewController: remoteView)
  }
  return remoteView
}

class OESettingsPrimaryTableViewController : UITableViewController {
  let items: [OESettingsPrimaryTableItem]
  let infoLabel: UILabel
  var shouldShowDeveloperMenuItem: Bool
  
  init() {
    self.items = [
      OESettingsPrimaryTableItem.init(
        indexPath: IndexPath.init(row: 0, section: 0),
        title: "Account",
        viewController: NYPLSettingsAccountDetailViewController(
          account: AccountsManager.shared.currentAccountId
        )
      ),
      OESettingsPrimaryTableItem.init(
        indexPath: IndexPath.init(row: 0, section: 1),
        title: "Help",
        selectionHandler: { (splitVC, tableVC) in
          let hs = HSHelpStack.instance() as! HSHelpStack
          hs.showHelp(splitVC)
        }
      ),
      OESettingsPrimaryTableItem.init(
        indexPath: IndexPath.init(row: 0, section: 2),
        title: "Acknowledgements",
        viewController: generateRemoteView(
          title: "Acknowledgements",
          url: "http://www.librarysimplified.org/openebooksacknowledgments.html"
        )
      ),
      OESettingsPrimaryTableItem.init(
        indexPath: IndexPath.init(row: 1, section: 2),
        title: "User Agreement",
        viewController: generateRemoteView(
          title: "User Agreement",
          url: "http://www.librarysimplified.org/openebookseula.html"
        )
      ),
      OESettingsPrimaryTableItem.init(
        indexPath: IndexPath.init(row: 2, section: 2),
        title: "Privacy Policy",
        viewController: generateRemoteView(
          title: "Privacy Policy",
          url: "http://www.librarysimplified.org/oeiprivacy.html"
        )
      ),
      OESettingsPrimaryTableItem.init(
        indexPath: IndexPath.init(row: 0, section: 3),
        title: "Developer Settings",
        viewController: NYPLDeveloperSettingsTableViewController()
      )
    ]
    
    // Init info label
    self.infoLabel = UILabel()
    self.infoLabel.font = UIFont.systemFont(ofSize: 12.0)
    let productName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? ""
    self.infoLabel.text = "\(productName) version \(version) (\(build))"
    self.infoLabel.textAlignment = .center
    self.infoLabel.sizeToFit()
    
    self.shouldShowDeveloperMenuItem = false
    
    super.init(nibName: nil, bundle: nil)
    
    let tap = UITapGestureRecognizer.init(target: self, action: #selector(revealDeveloperSettings))
    tap.numberOfTapsRequired = 7;
    self.infoLabel.isUserInteractionEnabled = true
    self.infoLabel.addGestureRecognizer(tap)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  var splitVCAncestor: OESettingsSplitViewController? {
    var ancestor = self.parent
    while ancestor != nil {
      guard let splitVC = ancestor as? OESettingsSplitViewController else {
        ancestor = ancestor!.parent
        continue
      }
      return splitVC
    }
    return nil
  }
  
  @objc func revealDeveloperSettings() {
    // Insert a URL to force the field to show.
    self.shouldShowDeveloperMenuItem = true
    self.tableView.reloadData()
  }
  
  func settingsPrimaryTableViewCell(text: String) -> UITableViewCell {
    let cell = UITableViewCell.init(style: .default, reuseIdentifier: nil)
    cell.textLabel?.text = text
    cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
    if self.splitVCAncestor?.traitCollection.horizontalSizeClass == .compact {
      cell.accessoryType = .disclosureIndicator
    } else {
      cell.accessoryType = .none
    }
    return cell
  }
  
  // MARK: UIViewController
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = OEConfiguration.oeShared.backgroundColor
  }
  
  // MARK: UITableViewDelegate
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let splitVC = splitVCAncestor else {
      Log.error("SettingsTableView", "Unable to find split view ancestor")
      return
    }
    for item in self.items {
      if item.path == indexPath {
        item.handleItemTouched(splitVC: splitVC, tableVC: self)
      }
    }
  }
  
  override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    let sectionCount = self.numberOfSections(in: self.tableView)
    if section == sectionCount - 1 {
      return 45.0
    }
    return 15.0
  }
  
  override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    let sectionCount = self.numberOfSections(in: self.tableView)
    if section == sectionCount - 1 {
      return self.infoLabel
    }
    return nil
  }
  
  // MARK: UITableViewDataSource
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    for item in self.items {
      if item.path == indexPath {
        return settingsPrimaryTableViewCell(text: item.name)
      }
    }

    return settingsPrimaryTableViewCell(text: "?")
  }
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    var n = 3
    if self.shouldShowDeveloperMenuItem || (OESettings.oeShared.customMainFeedURL != nil) {
      n += 1
    }
    return n
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return false
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 2 {
      return 3
    }
    return 1
  }
}
