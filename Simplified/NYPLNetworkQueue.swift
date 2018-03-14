import Foundation
import SQLite

/**
 The NetworkQueue is insantiated once on app startup and listens
 for a valid network notification from a reachability class. It then
 will retry any queued requests and purge them if necessary.
 */
final class NetworkQueue: NSObject {

  static let shared = NetworkQueue()

  override init() {
    super.init()
    NotificationCenter.default.addObserver(forName: NSNotification.Name.NYPLReachabilityHostIsReachable,
                                           object: nil,
                                           queue: nil) { notification in self.retryQueue() }
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  static let StatusCodes = [NSURLErrorTimedOut,
                            NSURLErrorCannotFindHost,
                            NSURLErrorCannotConnectToHost,
                            NSURLErrorNetworkConnectionLost,
                            NSURLErrorNotConnectedToInternet,
                            NSURLErrorInternationalRoamingOff,
                            NSURLErrorCallIsActive,
                            NSURLErrorDataNotAllowed,
                            NSURLErrorSecureConnectionFailed]
  let MaxRetriesInQueue = 5

  let serialQueue = DispatchQueue(label: Bundle.main.bundleIdentifier!
                                  + "."
                                  + String(describing: NetworkQueue.self))

  enum HTTPMethodType: String {
    case GET, POST, HEAD, PUT, DELETE, OPTIONS, CONNECT
  }

  private var retryRequestCount = 0
  private let path = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first!
  
  private let sqlTable = Table("offline_queue")
  
  private let sqlID = Expression<Int>("id")
  private let sqlLibraryID = Expression<Int>("library_identifier")
  private let sqlUpdateID = Expression<String?>("update_identifier")
  private let sqlUrl = Expression<String>("request_url")
  private let sqlMethod = Expression<String>("request_method")
  private let sqlParameters = Expression<Data?>("request_parameters")
  private let sqlHeader = Expression<Data?>("request_header")
  private let sqlRetries = Expression<Int>("retry_count")
  private let sqlDateCreated = Expression<Data>("date_created")
  
  
  // MARK: - Public Functions

  func addRequest(_ libraryID: Int,
                        _ updateID: String?,
                        _ requestUrl: URL,
                        _ method: HTTPMethodType,
                        _ parameters: Data?,
                        _ headers: [String : String]?) -> Void
  {
    // Serialize Data
    let urlString = requestUrl.absoluteString
    let methodString = method.rawValue
    let dateCreated = NSKeyedArchiver.archivedData(withRootObject: Date())
    
    let headerData: Data?
    if headers != nil {
      headerData = NSKeyedArchiver.archivedData(withRootObject: headers!)
    } else {
      headerData = nil
    }
    
    guard let db = startDatabaseConnection() else { return }
    
    // Get or create table
    do {
      try db.run(sqlTable.create(ifNotExists: true) { t in
        t.column(sqlID, primaryKey: true)
        t.column(sqlLibraryID)
        t.column(sqlUpdateID)
        t.column(sqlUrl)
        t.column(sqlMethod)
        t.column(sqlParameters)
        t.column(sqlHeader)
        t.column(sqlRetries)
        t.column(sqlDateCreated)
      })
    } catch {
      Log.error(#file, "SQLite Error: Could not create table")
      return
    }
    
    // Update (not insert) if uniqueID and libraryID match existing row in table
    let query = sqlTable.filter(sqlLibraryID == libraryID && sqlUpdateID == updateID)
                        .filter(sqlUpdateID != nil)
    
    do {
      //Try to update row
      let result = try db.run(query.update(sqlParameters <- parameters, sqlHeader <- headerData))
      if result > 0 {
        Log.debug(#file, "SQLite: Row Updated")
      } else {
        //Insert new row
        try db.run(sqlTable.insert(sqlLibraryID <- libraryID, sqlUpdateID <- updateID, sqlUrl <- urlString, sqlMethod <- methodString, sqlParameters <- parameters, sqlHeader <- headerData, sqlRetries <- 0, sqlDateCreated <- dateCreated))
        Log.debug(#file, "SQLite: Row Added")
      }
    } catch {
      Log.error(#file, "SQLite Error: Could not insert or update row")
    }
  }

  // MARK: - Private Functions

  private func retryQueue()
  {
    self.serialQueue.async {

      if self.retryRequestCount > 0 {
        Log.debug(#file, "Retry requests are still in progress. Cancelling this attempt.")
        return
      }

      guard let db = self.startDatabaseConnection() else {
        Log.error(#file, "Failed to start database connection for a retry attempt.")
        return
      }

      let expiredRows = self.sqlTable.filter(self.sqlRetries > self.MaxRetriesInQueue)
      do {
        try db.run(expiredRows.delete())

        self.retryRequestCount = try db.scalar(self.sqlTable.count)
        Log.debug(#file, "Executing \"retry\" with \(self.retryRequestCount) row(s) in the table.")

        for row in try db.prepare(self.sqlTable) {
          Log.debug(#file, "Retrying row: \(row[self.sqlID])")
          self.retry(db, requestRow: row)
        }
      } catch {
        Log.error(#file, "SQLite Error: Failure to prepare table or run deletion")
      }
    }
  }

  private func retry(_ db: Connection, requestRow: Row)
  {
    do {
      let ID = Int(requestRow[sqlID])
      let newValue = Int(requestRow[sqlRetries]) + 1
      try db.run(sqlTable.filter(sqlID == ID).update(sqlRetries <- newValue))
    } catch {
      Log.error(#file, "SQLite Error incrementing retry count")
    }
    
    // Re-attempt network request
    var urlRequest = URLRequest(url: URL(string: requestRow[sqlUrl])!)
    urlRequest.httpMethod = requestRow[sqlMethod]
    urlRequest.httpBody = requestRow[sqlParameters]
    
    if let headerData = requestRow[sqlHeader],
       let headers = NSKeyedUnarchiver.unarchiveObject(with: headerData) as? [String:String] {
      for (headerKey, headerValue) in headers {
        urlRequest.setValue(headerValue, forHTTPHeaderField: headerKey)
      }
    }
    
    let task = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
      self.serialQueue.async {
        if let response = response as? HTTPURLResponse {
          if response.statusCode == 200 {
            Log.info(#file, "Queued Request Upload: Success")
            self.deleteRow(db, id: requestRow[self.sqlID])
          }
        }
        self.retryRequestCount -= 1
      }
    }
    task.resume()
  }

  private func deleteRow(_ db: Connection, id: Int)
  {
    let rowToDelete = sqlTable.filter(sqlID == id)
    if let _ = try? db.run(rowToDelete.delete()) {
      Log.info(#file, "SQLite: deleted row from queue")
    } else {
      Log.error(#file, "SQLite Error: Could not delete row")
    }
  }
  
  private func startDatabaseConnection() -> Connection?
  {
    let db: Connection
    do {
      db = try Connection("\(path)/simplified.db")
    } catch {
      Log.error(#file, "SQLite: Could not start DB connection.")
      return nil
    }
    return db
  }
}
