class OESettings : NYPLSettings {
  // MARK: NYPLSdettings
  
  override var settingsAccountsList: [String] {
    get {
      if let libraryAccounts = UserDefaults.standard.array(forKey: NYPLSettings.settingsLibraryAccountsKey) {
        return libraryAccounts as! [String]
      }
      
      // Avoid crash in case currentLibrary isn't set yet
      var accountsList = [String]()
      if let currentLibrary = AccountsManager.shared.currentAccount?.uuid {
        accountsList.append(currentLibrary)
      }
      accountsList.append(AccountsManager.NYPLAccountUUIDs[2])
      self.settingsAccountsList = accountsList
      return accountsList
    }
    set(newAccountsList) {
      UserDefaults.standard.set(newAccountsList, forKey: NYPLSettings.settingsLibraryAccountsKey)
      UserDefaults.standard.synchronize()
    }
  }
}
