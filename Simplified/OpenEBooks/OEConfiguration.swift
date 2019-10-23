class OEConfiguration : NYPLConfiguration {
  static let NYPLCirculationBaseURLProduction = "https://circulation.openebooks.us"
  static let NYPLCirculationBaseURLTesting = "http://qa.circulation.openebooks.us"
  
  static var oeShared = OEConfiguration()
  
  let openEBooksRequestCodesURL = URL.init(string: "http://openebooks.net/getstarted.html")!
  let circulationURL = URL.init(string: NYPLCirculationBaseURLProduction)!
  
  // MARK: NYPLConfiguration
}
