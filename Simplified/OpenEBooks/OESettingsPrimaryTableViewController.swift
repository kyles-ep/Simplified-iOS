import HelpStack

class OESettingsPrimaryTableViewController : UITableViewController {
  let items: [OESettingsPrimaryTableItem]
  
  init() {
    self.items = [
      OESettingsPrimaryTableItem.init(
        indexPath: IndexPath.init(row: 0, section: 0),
        title: "Accounts",
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
        viewController: RemoteHTMLViewController.init(
          URL: URL.init(string: "http://www.librarysimplified.org/openebooksacknowledgments.html")!,
          title: "Acknowledgements",
          failureMessage: NSLocalizedString("SettingsConnectionFailureMessage", "")
        )
      ),
      OESettingsPrimaryTableItem.init(
        indexPath: IndexPath.init(row: 1, section: 2),
        title: "User Agreement",
        viewController: RemoteHTMLViewController.init(
          URL: URL.init(string: "http://www.librarysimplified.org/openebookseula.html")!,
          title: "User Agreement",
          failureMessage: NSLocalizedString("SettingsConnectionFailureMessage", "")
        )
      ),
      OESettingsPrimaryTableItem.init(
        indexPath: IndexPath.init(row: 2, section: 2),
        title: "Privacy Policy",
        viewController: RemoteHTMLViewController.init(
          URL: URL.init(string: "http://www.librarysimplified.org/oeiprivacy.html")!,
          title: "Privacy Policy",
          failureMessage: NSLocalizedString("SettingsConnectionFailureMessage", "")
        )
      )
    ]
    super.init(nibName: nil, bundle: nil)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  
}
