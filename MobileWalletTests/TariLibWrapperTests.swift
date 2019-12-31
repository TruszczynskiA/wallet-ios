//  TariLib.swift
	
/*
	Package MobileWalletTests
	Created by Jason van den Berg on 2019/11/15
	Using Swift 5.0
	Running on macOS 10.15

	Copyright 2019 The Tari Project

	Redistribution and use in source and binary forms, with or
	without modification, are permitted provided that the
	following conditions are met:

	1. Redistributions of source code must retain the above copyright notice,
	this list of conditions and the following disclaimer.

	2. Redistributions in binary form must reproduce the above
	copyright notice, this list of conditions and the following disclaimer in the
	documentation and/or other materials provided with the distribution.

	3. Neither the name of the copyright holder nor the names of
	its contributors may be used to endorse or promote products
	derived from this software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
	CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
	INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
	OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
	DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
	SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
	NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
	LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
	HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
	OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
	SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import XCTest

class TariLibWrapperTests: XCTestCase {
    //Use a random DB path for each test
    private var dbName = "test_db"
        
    private var storagePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test_\(UUID().uuidString)").path
    
    var databasePath: String {
        get {
            return "\(storagePath)/\(dbName)"
        }
    }
    
    var loggingFilePath: String {
       get {
            return "\(storagePath)/log.txt"
       }
    }
    
    override func setUp() {
    }

    override func tearDown() {
    }

    func testByteVector() {
        //Init manually. Initializing from pointers happens in priv/pub key tests.
        do {
            let byteVector = try ByteVector(byteArray: [0, 1, 2, 3, 4, 5])
            
            let (hexString, hexError) = byteVector.hexString
            if hexError != nil {
                XCTFail(hexError!.localizedDescription)
            }
            
            XCTAssertEqual(hexString, "000102030405")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testPrivateKey() {
        //Create priv key from hex, then create hex from that to test ByteVector toString()
        let originalPrivateKeyHex = "6259c39f75e27140a652a5ee8aefb3cf6c1686ef21d27793338d899380e8c801"
        
        do {
            let privateKey = try PrivateKey(hex: originalPrivateKeyHex)
            let (hex, hexError) = privateKey.hex
            if hexError != nil {
                XCTFail(hexError!.localizedDescription)
            }
            
            XCTAssertEqual(hex, originalPrivateKeyHex)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testPublicKey() {
        //Create pub key from hex, then create hex from that to test ByteVector toString()
        let originalPublicKeyHex = "6a493210f7499cd17fecb510ae0cea23a110e8d5b901f8acadd3095c73a3b919"
        
        do {
            let publicKey = try PublicKey(hex: originalPublicKeyHex)
            let (hex, hexError) = publicKey.hex
            if hexError != nil {
                XCTFail(hexError!.localizedDescription)
            }
            XCTAssertEqual(hex, originalPublicKeyHex)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testWallet() {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(atPath: storagePath, withIntermediateDirectories: true, attributes: nil)
            try fileManager.createDirectory(atPath: databasePath, withIntermediateDirectories: true, attributes: nil)
        } catch {
            XCTFail("Unable to create directory \(error.localizedDescription)")
        }
        
        let privateKeyHex = "6259c39f75e27140a652a5ee8aefb3cf6c1686ef21d27793338d899380e8c801"
        
        //MARK: Create new wallet
        var wallet: Wallet? = nil
        do {
            let commsConfig = try CommsConfig(
                privateKey: PrivateKey(hex: privateKeyHex),
                databasePath: databasePath,
                databaseName: dbName,
                controlAddress: "/ip4/127.0.0.1/tcp/80",
                listenerAddress: "/ip4/0.0.0.0/tcp/80"
            )
            
            wallet = try Wallet(commsConfig: commsConfig, loggingFilePath: loggingFilePath)
        } catch {
            XCTFail("Unable to create wallet \(error.localizedDescription)")
        }
        
        let testWalletPublicKey = "30e1dfa197794858bfdbf96cdce5dc8637d4bd1202dc694991040ddecbf42d40"
        
        let (walletPublicKey, pubKeyError) = wallet!.publicKey
        if pubKeyError != nil {
            XCTFail(pubKeyError!.localizedDescription)
        }
        
        let (walletPublicKeyHex, walletPublicKeyHexError) = walletPublicKey!.hex
        if walletPublicKeyHexError != nil {
            XCTFail(walletPublicKeyHexError!.localizedDescription)
        }
        
        XCTAssertEqual(walletPublicKeyHex, testWalletPublicKey)
        
        //MARK: Test data
        do {
            try wallet!.generateTestData()
        } catch {
            XCTFail(error.localizedDescription)
        }
        
        //MARK: Remove Alice contact
        let (contacts, contactsError) = wallet!.contacts
        if contactsError != nil {
            XCTFail(contactsError!.localizedDescription)
        }
        
        do {
            let aliceContact = try contacts!.at(position: 0)
            try wallet!.removeContact(aliceContact)
        }  catch {
            XCTFail(error.localizedDescription)
        }
                
        
        //MARK: Add Alice contact
        do {
            try wallet!.addContact(alias: "BillyBob", publicKeyHex: "a03d9be195e40466e255bd64eb612ad41ae0010519b6cbfc7698e5d0916a1a7c")
        } catch {
            XCTFail("Failed to add contact \(error.localizedDescription)")
        }

        //MARK: Receive a test transaction
        do {
            try wallet!.generateTestReceiveTransaction()
        } catch {
            XCTFail(error.localizedDescription)
        }

        //MARK: Finalize and broadcast received test transaction
        var txId: UInt64?
        do {
            let (pendingInboundTransactions, pendingInboundTransactionsError) = wallet!.pendingInboundTransactions
            if pendingInboundTransactionsError != nil {
                XCTFail(pendingInboundTransactionsError!.localizedDescription)
            }
            
            let (pendingInboundTransactionsCount, pendingInboundTransactionsCountError) = pendingInboundTransactions!.count
            if pendingInboundTransactionsCountError != nil {
                XCTFail(pendingInboundTransactionsCountError!.localizedDescription)
            }
            
            let pendingInboundTransaction = try pendingInboundTransactions!.at(position: pendingInboundTransactionsCount - 1)
            
            let (pendingInboundTransactionId, pendingInboundTransactionIdError) = pendingInboundTransaction.id
            if pendingInboundTransactionIdError != nil {
                XCTFail(pendingInboundTransactionIdError!.localizedDescription)
            }
            
            txId = pendingInboundTransactionId
            
            try wallet!.testFinalizedReceivedTransaction(pendingInboundTransaction: pendingInboundTransaction)
            var completedTx = try wallet!.findCompletedTransactionBy(id: txId!)
            try wallet!.testTransactionBroadcast(completedTransaction: completedTx)
            completedTx = try wallet!.findCompletedTransactionBy(id: txId!)
            let (status, statusError) = completedTx.status
            if statusError != nil {
                XCTFail(statusError!.localizedDescription)
            }
        
            XCTAssertEqual(status, .broadcast)
        } catch {
            XCTFail(error.localizedDescription)
        }

        //MARK: Mine received transaction
        do {
            let broadcastedCompletedTx = try wallet!.findCompletedTransactionBy(id: txId!)
            try wallet!.testTransactionMined(completedTransaction: broadcastedCompletedTx)

            let minedCompletedTx = try wallet!.findCompletedTransactionBy(id: txId!)
            
            let (status, statusError) = minedCompletedTx.status
            if statusError != nil {
                XCTFail(statusError!.localizedDescription)
            }
            
            XCTAssertEqual(status, .mined)
        } catch {
            XCTFail(error.localizedDescription)
        }

        //MARK: Send transaction to bob
        var sendTransactionId: UInt64?
        do {
            let (contacts, contactsError) = wallet!.contacts
            if contactsError != nil {
                XCTFail(contactsError!.localizedDescription)
            }
            
            let bob = try contacts!.at(position: 0)
            let (bobPublicKey, bobPublicKeyError) = bob.publicKey
            if bobPublicKeyError != nil {
                XCTFail(bobPublicKeyError!.localizedDescription)
            }
            
            try wallet!.sendTransaction(destination: bobPublicKey!, amount: 1000, fee: 101, message: "Oh hi bob")
            let (pendingOutboundTransactions, pendingOutboundTransactionsError) = wallet!.pendingOutboundTransactions
            if pendingOutboundTransactionsError != nil {
                XCTFail(pendingOutboundTransactionsError!.localizedDescription)
            }
            
            let pendingOutboundTransaction = try pendingOutboundTransactions!.at(position: 0)
            let (pendingOutboundTransactionId, pendingOutboundTransactionIdError) = pendingOutboundTransaction.id
            if pendingOutboundTransactionIdError != nil {
                XCTFail(pendingOutboundTransactionIdError!.localizedDescription)
            }
            
            sendTransactionId = pendingOutboundTransactionId
        } catch {
            XCTFail(error.localizedDescription)
        }

        //MARK: Complete sent transaction to bob
        do {
            let pendingOutboundTransaction = try wallet!.findPendingOutboundTransactionBy(id: sendTransactionId!)

            try wallet!.testCompleteSend(pendingOutboundTransaction: pendingOutboundTransaction!)

            let broadcastedCompletedTx = try wallet!.findCompletedTransactionBy(id: sendTransactionId!)
            try wallet!.testTransactionMined(completedTransaction: broadcastedCompletedTx)
        } catch {
            XCTFail(error.localizedDescription)
        }

        let (availableBalance, _) = wallet!.availableBalance
        let (pendingIncomingBalance, _) = wallet!.pendingIncomingBalance
        let (pendingOutgoingBalance, _) = wallet!.pendingOutgoingBalance
        
        XCTAssertGreaterThan(availableBalance, 0)
        XCTAssertGreaterThan(pendingIncomingBalance, 0)
        XCTAssertGreaterThan(pendingOutgoingBalance, 0)
    }
}
