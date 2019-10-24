class OEConfiguration : NYPLConfiguration {
  static let NYPLCirculationBaseURLProduction = "https://circulation.openebooks.us"
  static let NYPLCirculationBaseURLTesting = "http://qa.circulation.openebooks.us"
  
  fileprivate static let _dummyUrl = URL.init(fileURLWithPath: Bundle.main.path(forResource: "OpenEBooks_OPDS2_Catalog_Feed", ofType: "json")!)
  fileprivate static let _dummyUrlHash = _dummyUrl.absoluteString.md5().base64EncodedStringUrlSafe().trimmingCharacters(in: ["="])
  
  static var oeShared = OEConfiguration()
  
  let openEBooksRequestCodesURL = URL.init(string: "http://openebooks.net/getstarted.html")!
  let circulationURL = URL.init(string: NYPLCirculationBaseURLProduction)!
  
  // MARK: NYPLConfiguration
  
  override var betaUrl: URL {
    return OEConfiguration._dummyUrl
  }
  
  override var prodUrl: URL {
    return OEConfiguration._dummyUrl
  }
  
  override var betaUrlHash: String {
    return OEConfiguration._dummyUrlHash
  }
  
  override var prodUrlHash: String {
    return OEConfiguration._dummyUrlHash
  }
}
