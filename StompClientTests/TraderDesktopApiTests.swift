//
//  TraderDesktopApiTests.swift
//  StompClient
//
//  Created by ShengHua Wu on 4/6/16.
//  Copyright © 2016 shenghuawu. All rights reserved.
//

import XCTest
import Starscream
@testable import StompClient

class TraderDesktopApiTests: XCTestCase {
    
    private var client: StompClient!
    private var socket: WebSocket!
    private let host = "http://10.1.20.28:8080"
    
    override func setUp() {
        super.setUp()
        
        let url = NSURL(string: host + "/traderdesktop")!.appendServerIdAndSessionId()
        socket = WebSocket(url: url)
        client = StompClient(socket: socket)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    // MARK: - Disabled Tests
    func disable_testSubscribeAccountPNL() {
        let delegate = AccountPNLDelegate()
        delegate.expectation = expectationWithDescription("Subscribe account pnl")
        client.delegate = delegate

        let session = NSURLSession.sharedSession()
        let loginURLString = host + "/trader/desktop/auth/login"
        let request = NSMutableURLRequest(URL: NSURL(string: loginURLString)!)
        request.HTTPMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let param = ["id" : "laphone", "pass" : "laphone"]
        let data = try! NSJSONSerialization.dataWithJSONObject(param, options: NSJSONWritingOptions(rawValue: 0))
        request.HTTPBody = data
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            let res = response as! NSHTTPURLResponse
            if res.statusCode == 200 {
                let fields = res.allHeaderFields as! [String : String]
                let cookies = NSHTTPCookie.cookiesWithResponseHeaderFields(fields, forURL: res.URL!)
                let cookie = cookies.filter({
                    $0.name == "JSESSIONID"
                }).first!
                self.socket.headers["Cookie"] = cookie.name + "=" + cookie.value
                self.client.connect()
            } else {
                debugPrint(res)
                XCTAssert(false, "Status code isn't 200. Login failed.")
                delegate.expectation.fulfill()
            }
        }
        task.resume()
     
        waitForExpectationsWithTimeout(500.0, handler: nil)
    }
    
}

// MARK: - Stub Delegate
class AccountPNLDelegate: NSObject, StompClientDelegate {
    
    // MARK: - Public Properties
    var expectation: XCTestExpectation!
    
    // MARK: - Private Properties
    private let destination = "/account/accountpnl/laphone"
    
    // MARK: - Stomp Client Delegate
    func stompClientDidConnected(client: StompClient) {
        client.subscribe(destination, parameters: nil)
    }
    
    func stompClient(client: StompClient, didErrorOccurred error: NSError) {
        XCTAssertTrue(false, "Error: \(error.localizedDescription)")
        expectation.fulfill()
    }
    
    func stompClient(client: StompClient, didReceivedData data: NSData) {
        let json = try! NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        XCTAssertEqual(json["accountId"], "laphone", "Account Id is wrong.")
        
        client.unsubscribe(destination)
        
        XCTAssertNotNil(expectation, "Expectation doesn't setup.")
        expectation.fulfill()
    }
    
}
