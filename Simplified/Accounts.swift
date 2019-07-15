import Foundation

let currentAccountIdentifierKey  = "NYPLCurrentAccountIdentifier"
let userAboveAgeKey              = "NYPLSettingsUserAboveAgeKey"
let userAcceptedEULAKey          = "NYPLSettingsUserAcceptedEULA"
let accountSyncEnabledKey        = "NYPLAccountSyncEnabledKey"
let betaUrl = URL(string: "https://libraryregistry.librarysimplified.org/libraries/qa")!
let prodUrl = URL(string: "https://libraryregistry.librarysimplified.org/libraries")!
let betaUrlHash = betaUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
let prodUrlHash = prodUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
let userAddedAccountsKey = "userAddedAccounts"
let customAccountUsernameKey = "NYPLCustomAccountUsernameKey"
let customAccountPasswordKey = "NYPLCustomAccountPasswordKey"

/**
 Switchboard for fetching data, whether it's from a cache source or fresh from the endpoint.
 @param url target URL to fetch from
 @param cacheUrl the target file URL to save the data to
 @param options load options to determine the behaviour of this method;
 noCache - don't fetch from cache under any circumstances
 preferCache - fetches from cache if cache exists
 cacheOnly - only fetch from cache, unless `noCache` is specified
 @param completion callback method when this is complete, providing the data or nil if unsuccessful
 */
fileprivate func loadDataWithCache(url: URL, cacheUrl: URL, options: AccountsManager.LoadOptions, completion: @escaping (Data?) -> ()) {
  if !options.contains(.noCache) {
    let modified = (try? FileManager.default.attributesOfItem(atPath: cacheUrl.path)[.modificationDate]) as? Date
    if let modified = modified, let expiry = Calendar.current.date(byAdding: .day, value: 1, to: modified), expiry > Date() || options.contains(.preferCache) {
      if let data = try? Data(contentsOf: cacheUrl) {
        completion(data)
        return
      }
    }
    
    if options.contains(.cacheOnly) {
      completion(nil)
      return
    }
  }
  
  // Load data from the internet if either the cache wasn't recent enough (or preferred), or somehow failed to load
  let request = URLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60)
  
  let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
    guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
      completion(nil)
      return
    }
    try? data.write(to: cacheUrl)
    completion(data)
  }
  dataTask.resume()
}

fileprivate func removeBasicAuthCredentialsFromKeychain(url: String) {
  let hash = url.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
  let usernameKey = "\(customAccountUsernameKey)_\(hash)"
  let passwordKey = "\(customAccountPasswordKey)_\(hash)"
  NYPLKeychain.shared()?.removeObject(forKey: usernameKey)
  NYPLKeychain.shared()?.removeObject(forKey: passwordKey)
}

/// Manage the library accounts for the app.
/// Initialized with JSON.
@objcMembers final class AccountsManager: NSObject
{
  struct LoadOptions: OptionSet {
    let rawValue: Int

    // Cache control
    static let preferCache = LoadOptions(rawValue: 1 << 0)
    static let cacheOnly = LoadOptions(rawValue: 1 << 1)
    static let noCache = LoadOptions(rawValue: 1 << 2)
    
    static let online: LoadOptions = []
    static let strict_online: LoadOptions = [.noCache]
    static let offline: LoadOptions = [.preferCache]
    static let strict_offline: LoadOptions = [.preferCache, .cacheOnly]
  }

  // MARK: Static vars
  
  static let shared = AccountsManager()
  static let NYPLAccountUUIDs = [
    "urn:uuid:065c0c11-0d0f-42a3-82e4-277b18786949",
    "urn:uuid:edef2358-9f6a-4ce6-b64f-9b351ec68ac4",
    "urn:uuid:56906f26-2c9a-4ae9-bd02-552557720b99"
  ]
  
  // MARK: Class methods
  
  // For Objective-C classes
  class func sharedInstance() -> AccountsManager {
    return AccountsManager.shared
  }
  
  // MARK: Member vars
  
  private var accountSets = [String: [Account]]()
  private var _accountSet: String
  private let defaults: UserDefaults
  private let completionHandlerAccessQueue = DispatchQueue(label: "libraryListCompletionHandlerAccessQueue")
  private var loadingCompletionHandlers = [String: [(Bool) -> ()]]()
  
  // MARK: Properties
  
  var accountSet: String {
    return _accountSet
  }
  var accountsHaveLoaded: Bool {
    if let accounts = accountSets[accountSet] {
      return !accounts.isEmpty
    }
    return false
  }
  
  var currentAccount: Account? {
    get {
      return account(defaults.string(forKey: currentAccountIdentifierKey) ?? "")
    }
    set {
      defaults.set(newValue?.uuid, forKey: currentAccountIdentifierKey)
      NotificationCenter.default.post(name: NSNotification.Name.NYPLCurrentAccountDidChange, object: nil)
    }
  }
  
  var currentAccountId: String? {
    return defaults.string(forKey: currentAccountIdentifierKey)
  }
  
  var userAddedAccounts: [Account] {
    return accounts(userAddedAccountsKey)
  }

  // MARK: Methods
  
  fileprivate override init() {
    self.defaults = UserDefaults.standard
    self._accountSet = NYPLSettings.shared.useBetaLibraries ? betaUrlHash : prodUrlHash
    
    super.init()
    
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(updateAccountSetFromSettings),
      name: NSNotification.Name.NYPLUseBetaDidChange,
      object: nil
    )
    DispatchQueue.main.async {
      self.loadCatalogs(options: .offline, completion: {_ in })
    }
    DispatchQueue.main.async {
      self.loadCatalogs(options: .strict_offline, url: NYPLSettings.shared.useBetaLibraries ? prodUrl : betaUrl, completion: { _ in })
      self.loadUserAddedAccounts()
    }
  }
  
  
  // Returns whether loading was happening already
  func addLoadingCompletionHandler(key: String, _ handler: @escaping (Bool) -> ()) -> Bool {
    var wasEmpty = false
    completionHandlerAccessQueue.sync {
      if loadingCompletionHandlers[key] == nil {
        loadingCompletionHandlers[key] = [(Bool)->()]()
      }
      wasEmpty = loadingCompletionHandlers[key]!.isEmpty
      loadingCompletionHandlers[key]!.append(handler)
    }
    return !wasEmpty
  }
  
  /**
   Resolves any complation handlers that may have been queued waiting for a registry fetch
   and clears the queue.
   @param key the key for the completion handler list, since there are multiple
   @param success success indicator to pass on to each handler
   */
  func callAndClearLoadingCompletionHandlers(key: String, _ success: Bool) {
    var handlers = [(Bool) -> ()]()
    completionHandlerAccessQueue.sync {
      if let h = loadingCompletionHandlers[key] {
        handlers = h
        loadingCompletionHandlers[key] = []
      }
    }
    for handler in handlers {
      handler(success)
    }
  }
  
  func libraryListCacheUrl(name: String) -> URL {
    let applicationSupportUrl = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let url = applicationSupportUrl.appendingPathComponent("library_list_\(name).json")
    return url
  }
  
  private func handleAccountChange(account: Account, preferringCache: Bool, completion: @escaping (Bool) -> ()) {
    account.loadAuthenticationDocument(preferringCache: preferringCache, completion: { (success) in
      if !success {
        Log.error(#file, "Failed to load authentication document for current account; a bunch of things likely won't work")
      }
      DispatchQueue.main.async {
        var mainFeed = URL(string: account.catalogUrl ?? "")
        let resolveFn = {
          NYPLSettings.shared.accountMainFeedURL = mainFeed
          UIApplication.shared.delegate?.window??.tintColor = NYPLConfiguration.mainColor()
          NotificationCenter.default.post(name: NSNotification.Name.NYPLCurrentAccountDidChange, object: nil)
          completion(true)
        }
        if account.details?.needsAgeCheck ?? false {
          AgeCheck.shared().verifyCurrentAccountAgeRequirement { meetsAgeRequirement in
            DispatchQueue.main.async {
              mainFeed = meetsAgeRequirement ? account.details?.coppaOverUrl : account.details?.coppaUnderUrl
              resolveFn()
            }
          }
        } else {
          resolveFn()
        }
      }
    })
  }
  
  // Take the library list data (either from cache or the internet), load it into self.accounts, and load the auth document for the current account if necessary
  private func loadCatalogs(data: Data, options: LoadOptions, key: String, completion: @escaping (Bool) -> ()) {
    do {
      let catalogsFeed = try OPDS2CatalogsFeed.fromData(data)
      let hadAccount = self.currentAccount != nil
      self.accountSets[key] = catalogsFeed.catalogs.map { Account(publication: $0) }
      if hadAccount != (self.currentAccount != nil) {
        handleAccountChange(account: self.currentAccount!, preferringCache: options.contains(.preferCache), completion: completion)
      } else {
        completion(true)
      }
    } catch (let error) {
      Log.error(#file, "Couldn't load catalogs. Error: \(error.localizedDescription)")
      completion(false)
    }
  }
  
  func loadCatalogs(options: LoadOptions, url: URL? = nil, completion: @escaping (Bool) -> ()) {
    let isBeta = NYPLSettings.shared.useBetaLibraries
    let targetUrl = url != nil ? url! :
      isBeta ? betaUrl : prodUrl
    let hash = targetUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
    
    let wasAlreadyLoading = addLoadingCompletionHandler(key: hash, completion)
    if wasAlreadyLoading {
      return
    }
    
    let cacheUrl = libraryListCacheUrl(name: hash)
    
    loadDataWithCache(url: targetUrl, cacheUrl: cacheUrl, options: options) { (data) in
      if let data = data {
        self.loadCatalogs(data: data, options: options, key: hash) { (success) in
          self.callAndClearLoadingCompletionHandlers(key: hash, success)
          NotificationCenter.default.post(name: NSNotification.Name.NYPLCatalogDidLoad, object: nil)
        }
      } else {
        self.callAndClearLoadingCompletionHandlers(key: hash, false)
      }
    }
  }
  
  func loadUserAddedAccounts() {
    let customAccounts: [String] = (defaults.array(forKey: userAddedAccountsKey) as? [String]) ?? []
    var dispatchCounter = 0
    for customAccount in customAccounts {
      if let customAccountUrl = URL.init(string: customAccount) {
        let delegate = CustomAccountDelegate.init(url: customAccount, view: nil, prompt: false)
        let session = URLSession.init(configuration: .default, delegate: delegate, delegateQueue: .main)
        let request = URLRequest.init(url: customAccountUrl, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 60)
        let dataTask = session.dataTask(with: request) { (data, response, error) in
          guard let data = data, let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            return
          }
          if let feed = NYPLOPDSFeed.init(xml: NYPLXML.init(data: data)) {
            dispatchCounter += 1
            DispatchQueue.main.async {
              dispatchCounter -= 1
              let account = Account(feed: feed, url: customAccount)
              if account.uuid == self.currentAccountId {
                self.handleAccountChange(account: account, preferringCache: true, completion: {_ in })
              }
              var accounts = self.accountSets[userAddedAccountsKey] ?? []
              accounts.append(account)
              accounts.sort(by: { (a1, a2) -> Bool in
                return a1.name < a2.name
              })
              self.accountSets[userAddedAccountsKey] = accounts
              if dispatchCounter == 0 {
                NotificationCenter.default.post(name: NSNotification.Name.NYPLCustomLibraryListDidChange, object: nil)
              }
            }
          }
        }
        dataTask.resume()
      }
    }
  }
  
  func addCustomAccount(url: String, viewToPresentAuthOn: UIViewController?) {
    if let accountURL = URL.init(string: url) {
      let delegate = CustomAccountDelegate.init(url: url, view: viewToPresentAuthOn, prompt: true)
      let session = URLSession.init(configuration: .default, delegate: delegate, delegateQueue: .main)
      let request = URLRequest.init(url: accountURL, cachePolicy: .reloadRevalidatingCacheData, timeoutInterval: 60)
      let dataTask = session.dataTask(with: request) { (data, responseParam, error) in
        guard let data = data, let response = responseParam as? HTTPURLResponse, response.statusCode == 200 else {
          // Remove any potential auth keys that were added during basic auth
          removeBasicAuthCredentialsFromKeychain(url: url)
          
          // Fire off alert
          let alert = error == nil ?
            NYPLAlertUtils.alert(title: "Unable to add library", message: "Unable to get a valid response") :
            NYPLAlertUtils.alert(title: "Unable to add library", message: error!.localizedDescription)
          NYPLAlertUtils.presentFromViewControllerOrNil(alertController: alert, viewController: viewToPresentAuthOn, animated: true, completion: nil)
          return
        }
        if let feed = NYPLOPDSFeed.init(xml: NYPLXML.init(data: data)) {
          DispatchQueue.main.async {
            // Add account to memory
            let account = Account(feed: feed, url: url)
            var accounts = self.accountSets[userAddedAccountsKey] ?? []
            accounts.append(account)
            accounts.sort(by: { (a1, a2) -> Bool in
              return a1.name < a2.name
            })
            self.accountSets[userAddedAccountsKey] = accounts
            
            // Add account to app storage
            var customAccounts: [String] = (self.defaults.array(forKey: userAddedAccountsKey) as? [String]) ?? []
            customAccounts.append(url)
            self.defaults.set(customAccounts, forKey: userAddedAccountsKey)
            
            // Notify
            NotificationCenter.default.post(name: NSNotification.Name.NYPLCustomLibraryListDidChange, object: account)
          }
        } else {
          // Remove any potential auth keys that were added during basic auth
          removeBasicAuthCredentialsFromKeychain(url: url)
          
          // Fire off alert
          let alert = NYPLAlertUtils.alert(title: "Unable to add library", message: "Could not parse feed")
          NYPLAlertUtils.presentFromViewControllerOrNil(alertController: alert, viewController: viewToPresentAuthOn, animated: true, completion: nil)
        }
      }
      dataTask.resume()
    } else {
      // Fire off alert
      let alert = NYPLAlertUtils.alert(title: "Invalid URL", message: "\(url) is not a valid URL")
      NYPLAlertUtils.presentFromViewControllerOrNil(alertController: alert, viewController: viewToPresentAuthOn, animated: true, completion: nil)
    }
  }
  
  func removeCustomAccount(url: String) {
    // Remove from memory storage
    var customAccounts = userAddedAccounts
    let initialCount = customAccounts.count
    customAccounts = customAccounts.filter { $0.catalogUrl != url }
    // Sorting because we don't know if filter is stable; please remove if it is
    customAccounts.sort(by: { (a1, a2) -> Bool in
      return a1.name < a2.name
    })
    self.accountSets[userAddedAccountsKey] = customAccounts
    
    // Remove from app storage
    var customAccountURLs: [String] = (self.defaults.array(forKey: userAddedAccountsKey) as? [String]) ?? []
    customAccountURLs = customAccountURLs.filter { $0 != url }
    self.defaults.set(customAccountURLs, forKey: userAddedAccountsKey)
    
    // Remove any potential basic auth credentials from keychain
    removeBasicAuthCredentialsFromKeychain(url: url)
    
    // Notify
    if initialCount != customAccounts.count {
      NotificationCenter.default.post(name: NSNotification.Name.NYPLCustomLibraryListDidChange, object: nil)
    }
  }
  
  func account(_ uuid:String) -> Account? {
    // Check primary account set first
    if let accounts = self.accountSets[self.accountSet] {
      if let account = accounts.filter({ $0.uuid == uuid }).first {
        return account
      }
    }
    // Check existing account lists
    for accountEntry in self.accountSets {
      if accountEntry.key == self.accountSet {
        continue
      }
      if let account = accountEntry.value.filter({ $0.uuid == uuid }).first {
        return account
      }
    }
    return nil
  }
  
  func accounts(_ key: String? = nil) -> [Account] {
    let k = key != nil ? key! : self.accountSet
    return self.accountSets[k] ?? []
  }
  
  func updateAccountSetFromSettings() {
    self._accountSet = NYPLSettings.shared.useBetaLibraries ? betaUrlHash : prodUrlHash
    if self.accounts().isEmpty {
      loadCatalogs(options: .offline, completion: {_ in })
    }
  }
}

// Extra data that gets loaded from an OPDS2AuthenticationDocument,
@objcMembers final class AccountDetails: NSObject {
  enum AuthType: String {
    case basic = "http://opds-spec.org/auth/basic"
    case coppa = "http://librarysimplified.org/terms/authentication/gate/coppa"
    case anonymous = "http://librarysimplified.org/rel/auth/anonymous"
    case none
  }
  
  let defaults:UserDefaults
  let authType:AuthType
  let uuid:String
  let authPasscodeLength:UInt
  let patronIDKeyboard:LoginKeyboard
  let pinKeyboard:LoginKeyboard
  let supportsSimplyESync:Bool
  let supportsBarcodeScanner:Bool
  let supportsBarcodeDisplay:Bool
  let supportsCardCreator:Bool
  let supportsReservations:Bool
  let mainColor:String?
  let userProfileUrl:String?
  let cardCreatorUrl:String?
  let coppaUnderUrl:URL?
  let coppaOverUrl:URL?
  let loansUrl:URL?
  
  var needsAuth:Bool {
    return authType == .basic
  }
  var needsAgeCheck:Bool {
    return authType == .coppa
  }
  
  fileprivate var urlAnnotations:URL?
  fileprivate var urlAcknowledgements:URL?
  fileprivate var urlContentLicenses:URL?
  fileprivate var urlEULA:URL?
  fileprivate var urlPrivacyPolicy:URL?
  
  var eulaIsAccepted:Bool {
    get {
      guard let result = getAccountDictionaryKey(userAcceptedEULAKey) else { return false }
      return result as! Bool
    }
    set {
      setAccountDictionaryKey(userAcceptedEULAKey, toValue: newValue as AnyObject)
    }
  }
  var syncPermissionGranted:Bool {
    get {
      guard let result = getAccountDictionaryKey(accountSyncEnabledKey) else { return false }
      return result as! Bool
    }
    set {
      setAccountDictionaryKey(accountSyncEnabledKey, toValue: newValue as AnyObject)
    }
  }
  var userAboveAgeLimit:Bool {
    get {
      guard let result = getAccountDictionaryKey(userAboveAgeKey) else { return false }
      return result as! Bool
    }
    set {
      setAccountDictionaryKey(userAboveAgeKey, toValue: newValue as AnyObject)
    }
  }
  
  init(authenticationDocument: OPDS2AuthenticationDocument, uuid: String) {
    defaults = .standard
    self.uuid = uuid
    
    supportsReservations = authenticationDocument.features?.disabled?.contains("https://librarysimplified.org/rel/policy/reservations") != true
    userProfileUrl = authenticationDocument.links?.first(where: { $0.rel == "http://librarysimplified.org/terms/rel/user-profile" })?.href
    loansUrl = URL.init(string: authenticationDocument.links?.first(where: { $0.rel == "http://opds-spec.org/shelf" })?.href ?? "")
    supportsSimplyESync = userProfileUrl != nil
    
    mainColor = authenticationDocument.colorScheme
    
    // TODO: Should we preference different authentication schemes, rather than just getting the first?
    let auth = authenticationDocument.authentication?.first
    if let auth = auth {
      authType = AuthType(rawValue: auth.type) ?? .none
    } else {
      authType = .none
    }
    patronIDKeyboard = LoginKeyboard(auth?.inputs?.login.keyboard) ?? .standard
    pinKeyboard = LoginKeyboard(auth?.inputs?.password.keyboard) ?? .standard
    // Default to 100; a value of 0 means "don't show this UI element at all", not "unlimited characters"
    authPasscodeLength = auth?.inputs?.password.maximumLength ?? 99
    // In the future there could be more formats, but we only know how to support this one
    supportsBarcodeScanner = auth?.inputs?.login.barcodeFormat == "Codabar"
    supportsBarcodeDisplay = supportsBarcodeScanner
    coppaUnderUrl = URL.init(string: auth?.links?.first(where: { $0.rel == "http://librarysimplified.org/terms/rel/authentication/restriction-not-met" })?.href ?? "")
    coppaOverUrl = URL.init(string: auth?.links?.first(where: { $0.rel == "http://librarysimplified.org/terms/rel/authentication/restriction-met" })?.href ?? "")
    
    let registerUrl = authenticationDocument.links?.first(where: { $0.rel == "register" })?.href
    if let url = registerUrl, url.hasPrefix("nypl.card-creator:") == true {
      supportsCardCreator = true
      cardCreatorUrl = String(url.dropFirst("nypl.card-creator:".count))
    } else {
      supportsCardCreator = false
      cardCreatorUrl = registerUrl
    }
    
    super.init()
    
    if let urlString = authenticationDocument.links?.first(where: { $0.rel == "privacy-policy" })?.href,
      let url = URL(string: urlString) {
      setURL(url, forLicense: .privacyPolicy)
    }
    
    if let urlString = authenticationDocument.links?.first(where: { $0.rel == "terms-of-service" })?.href,
      let url = URL(string: urlString) {
      setURL(url, forLicense: .eula)
    }
    
    if let urlString = authenticationDocument.links?.first(where: { $0.rel == "license" })?.href,
      let url = URL(string: urlString) {
      setURL(url, forLicense: .contentLicenses)
    }
    
    if let urlString = authenticationDocument.links?.first(where: { $0.rel == "copyright" })?.href,
      let url = URL(string: urlString) {
      setURL(url, forLicense: .acknowledgements)
    }
  }

  func setURL(_ URL: URL, forLicense urlType: URLType) -> Void {
    switch urlType {
    case .acknowledgements:
      urlAcknowledgements = URL
      setAccountDictionaryKey("urlAcknowledgements", toValue: URL.absoluteString as AnyObject)
    case .contentLicenses:
      urlContentLicenses = URL
      setAccountDictionaryKey("urlContentLicenses", toValue: URL.absoluteString as AnyObject)
    case .eula:
      urlEULA = URL
      setAccountDictionaryKey("urlEULA", toValue: URL.absoluteString as AnyObject)
    case .privacyPolicy:
      urlPrivacyPolicy = URL
      setAccountDictionaryKey("urlPrivacyPolicy", toValue: URL.absoluteString as AnyObject)
    case .annotations:
      urlAnnotations = URL
      setAccountDictionaryKey("urlAnnotations", toValue: URL.absoluteString as AnyObject)
    }
  }
  
  func getLicenseURL(_ type: URLType) -> URL? {
    switch type {
    case .acknowledgements:
      if let url = urlAcknowledgements {
        return url
      } else {
        guard let urlString = getAccountDictionaryKey("urlAcknowledgements") as? String else { return nil }
        guard let result = URL(string: urlString) else { return nil }
        return result
      }
    case .contentLicenses:
      if let url = urlContentLicenses {
        return url
      } else {
        guard let urlString = getAccountDictionaryKey("urlContentLicenses") as? String else { return nil }
        guard let result = URL(string: urlString) else { return nil }
        return result
      }
    case .eula:
      if let url = urlEULA {
        return url
      } else {
        guard let urlString = getAccountDictionaryKey("urlEULA") as? String else { return nil }
        guard let result = URL(string: urlString) else { return nil }
        return result
      }
    case .privacyPolicy:
      if let url = urlPrivacyPolicy {
        return url
      } else {
        guard let urlString = getAccountDictionaryKey("urlPrivacyPolicy") as? String else { return nil }
        guard let result = URL(string: urlString) else { return nil }
        return result
      }
    case .annotations:
      if let url = urlAnnotations {
        return url
      } else {
        guard let urlString = getAccountDictionaryKey("urlAnnotations") as? String else { return nil }
        guard let result = URL(string: urlString) else { return nil }
        return result
      }
    }
  }
  
  fileprivate func setAccountDictionaryKey(_ key: String, toValue value: AnyObject) {
    if var savedDict = defaults.value(forKey: self.uuid) as? [String: AnyObject] {
      savedDict[key] = value
      defaults.set(savedDict, forKey: self.uuid)
    } else {
      defaults.set([key:value], forKey: self.uuid)
    }
  }
  
  fileprivate func getAccountDictionaryKey(_ key: String) -> AnyObject? {
    let savedDict = defaults.value(forKey: self.uuid) as? [String: AnyObject]
    guard let result = savedDict?[key] else { return nil }
    return result
  }
}

/// Object representing one library account in the app. Patrons may
/// choose to sign up for multiple Accounts.
@objcMembers final class Account: NSObject
{
  let logo:UIImage
  let uuid:String
  let name:String
  let subtitle:String?
  let supportEmail:String?
  let catalogUrl:String?
  var details:AccountDetails?
  
  let authenticationDocumentUrl:String?
  var authenticationDocument:OPDS2AuthenticationDocument? {
    didSet {
      guard let authenticationDocument = authenticationDocument else {
        return
      }
      details = AccountDetails(authenticationDocument: authenticationDocument, uuid: uuid)
    }
  }
  
  var authenticationDocumentCacheUrl: URL {
    let applicationSupportUrl = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    let nonColonUuid = uuid.replacingOccurrences(of: ":", with: "_")
    return applicationSupportUrl.appendingPathComponent("authentication_document_\(nonColonUuid).json")
  }
  
  var loansUrl: URL? {
    return details?.loansUrl
  }
  
  init(publication: OPDS2Publication) {
    name = publication.metadata.title
    subtitle = publication.metadata.description
    uuid = publication.metadata.id
    
    catalogUrl = publication.links.first(where: { $0.rel == "http://opds-spec.org/catalog" })?.href
    supportEmail = publication.links.first(where: { $0.rel == "help" })?.href.replacingOccurrences(of: "mailto:", with: "")
    
    authenticationDocumentUrl = publication.links.first(where: { $0.type == "application/vnd.opds.authentication.v1.0+json" })?.href
    
    let logoString = publication.images?.first(where: { $0.rel == "http://opds-spec.org/image/thumbnail" })?.href
    if let modString = logoString?.replacingOccurrences(of: "data:image/png;base64,", with: ""),
      let logoData = Data.init(base64Encoded: modString),
      let logoImage = UIImage(data: logoData) {
      logo = logoImage
    } else {
      logo = UIImage.init(named: "LibraryLogoMagic")!
    }
  }
  
  init(feed: NYPLOPDSFeed, url: String) {
    logo = UIImage.init(named: "LibraryLogoMagic")!
    uuid = feed.identifier ?? url
    name = feed.title ?? url
    subtitle = nil
    supportEmail = nil
    catalogUrl = url
    let links: [NYPLOPDSLink] = feed.links as? [NYPLOPDSLink] ?? []
    authenticationDocumentUrl = links.first(where: { $0.rel == "http://opds-spec.org/auth/document" })?.href?.absoluteString
  }
  
  func loadAuthenticationDocument(preferringCache: Bool, completion: @escaping (Bool) -> ()) {
    guard let urlString = authenticationDocumentUrl, let url = URL(string: urlString) else {
      Log.error(#file, "Invalid or missing authentication document URL")
      completion(false)
      return
    }
    
    loadDataWithCache(url: url, cacheUrl: authenticationDocumentCacheUrl, options: preferringCache ? .preferCache : []) { (data) in
      if let data = data {
        do {
          self.authenticationDocument = try OPDS2AuthenticationDocument.fromData(data)
          completion(true)
          
        } catch (let error) {
          Log.error(#file, "Failed to load authentication document for library: \(error.localizedDescription)")
          completion(false)
        }
      } else {
        Log.error(#file, "Failed to load data of authentication document from cache or network")
        completion(false)
      }
    }
  }
}

@objc enum URLType: Int {
  case acknowledgements
  case contentLicenses
  case eula
  case privacyPolicy
  case annotations
}

@objc enum LoginKeyboard: Int {
  case standard
  case email
  case numeric
  case none

  init?(_ stringValue: String?) {
    if stringValue == "Default" {
      self = .standard
    } else if stringValue == "Email address" {
      self = .email
    } else if stringValue == "Number pad" {
      self = .numeric
    } else if stringValue == "No input" {
      self = .none
    } else {
      Log.error(#file, "Invalid init parameter for PatronPINKeyboard: \(stringValue ?? "nil")")
      return nil
    }
  }
}

class CustomAccountDelegate : NSObject, URLSessionDelegate, URLSessionTaskDelegate {
  let url: String
  let view: UIViewController?
  let prompt: Bool
  
  init(url: String, view: UIViewController?, prompt: Bool) {
    self.url = url
    self.view = view
    self.prompt = prompt
  }
  
  // Session challenge
  func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
      if let trust = challenge.protectionSpace.serverTrust, prompt {
        var ptr = UnsafeMutablePointer<SecTrustResultType>.allocate(capacity: 1)
        SecTrustEvaluate(trust, ptr)
        if ptr.pointee != SecTrustResultType.proceed && ptr.pointee != SecTrustResultType.unspecified {
          let alert = UIAlertController.init(title: "Untrusted Endpoint", message: "Could not automatically trust remote host.\nTrust and connect anyway?", preferredStyle: .alert)
          alert.addAction(UIAlertAction.init(title: "Cancel", style: .cancel, handler: { (action) in
            completionHandler(.cancelAuthenticationChallenge, nil)
          }))
          alert.addAction(UIAlertAction.init(title: "Trust", style: .default, handler: { (action) in
            completionHandler(.useCredential, URLCredential(trust: trust))
          }))
          NYPLAlertUtils.presentFromViewControllerOrNil(alertController: alert, viewController: view, animated: true, completion: nil)
          return
        }
      }
      completionHandler(.performDefaultHandling, nil)
    } else {
      completionHandler(.performDefaultHandling, nil)
    }
  }
  
  // Task challenge
  func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic) {
      let hash = self.url.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
      let usernameKey = "\(customAccountUsernameKey)_\(hash)"
      let passwordKey = "\(customAccountPasswordKey)_\(hash)"
      if !prompt {
        if let username = NYPLKeychain.shared()?.object(forKey: usernameKey), let password = NYPLKeychain.shared()?.object(forKey: passwordKey) {
          let credentials = URLCredential(user: username as! String, password: password as! String, persistence: .none)
          completionHandler(.useCredential, credentials)
        } else {
          completionHandler(.cancelAuthenticationChallenge, nil)
        }
      } else {
        let alert = UIAlertController.init(title: "Auth Required", message: "", preferredStyle: .alert)
        alert.addTextField { (textfield) in
          textfield.placeholder = "username"
        }
        alert.addTextField { (textfield) in
          textfield.placeholder = "password"
          textfield.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction.init(title: "Login", style: .default, handler: { (action) in
          if let username = alert.textFields![0].text, let password = alert.textFields![1].text {
            if username.count > 0 {
              NYPLKeychain.shared()?.setObject(username, forKey: usernameKey)
              NYPLKeychain.shared()?.setObject(password, forKey: passwordKey)
              let credentials = URLCredential(user: username, password: password, persistence: .none)
              completionHandler(.useCredential, credentials)
              return
            }
          }
          completionHandler(.cancelAuthenticationChallenge, nil)
        }))
        alert.addAction(UIAlertAction.init(title: "Cancel", style: .default, handler: { (action) in
          completionHandler(.cancelAuthenticationChallenge, nil)
        }))
        NYPLAlertUtils.presentFromViewControllerOrNil(alertController: alert, viewController: view, animated: true, completion: nil)
        return
      }
    } else {
      completionHandler(.rejectProtectionSpace, nil)
    }
  }
}
