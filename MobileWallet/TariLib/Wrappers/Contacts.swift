//  Contacts.swift

/*
	Package MobileWallet
	Created by Jason van den Berg on 2019/11/16
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

import Foundation

enum ContactsError: Error {
    case generic(_ errorCode: Int32)
    case contactNotFound
}

class Contacts {
    private var ptr: OpaquePointer

    var pointer: OpaquePointer {
        return ptr
    }

    var count: (UInt32, Error?) {
        var errorCode: Int32 = -1
        let result = withUnsafeMutablePointer(to: &errorCode, { error in
            contacts_get_length(ptr, error)})
        return (result, errorCode != 0 ? ContactsError.generic(errorCode) : nil)
    }

    var list: ([Contact], Error?) {
        let (count, countError) = self.count
        guard countError == nil else {
            return ([], countError)
        }

        var list: [Contact] = []

        if count > 0 {
            for n in 0...count - 1 {
                do {
                    list.append(try self.at(position: n))
                } catch {
                    return ([], error)
                }
            }
        }

        return (list, nil)
    }

    init(contactsPointer: OpaquePointer) {
        ptr = contactsPointer
    }

    func at(position: UInt32) throws -> Contact {
        var errorCode: Int32 = -1
        let contactPointer = withUnsafeMutablePointer(to: &errorCode, { error in
            contacts_get_at(ptr, position, error)})
        guard errorCode == 0 else {
            throw ContactsError.generic(errorCode)
        }
        if contactPointer == nil {
            throw ContactsError.contactNotFound
        }

        return Contact(contactPointer: contactPointer!)
    }

    // TODO this might be more better to be searched by in the lib instead of iterating though them here
    func find(publicKey: PublicKey) throws -> Contact {
        let (searchHex, seachHexError) = publicKey.hex
        guard seachHexError == nil else {
            throw seachHexError!
        }

        let (count, countError) = self.count
        guard countError == nil else {
            throw countError!
        }

        if count < 1 {
            throw ContactsError.contactNotFound
        }

        for n in 0...count - 1 {
            let contact = try self.at(position: n)
            let (contactPubKey, contactPubKeyError) = contact.publicKey
            guard contactPubKeyError == nil else {
                throw contactPubKeyError!
            }

            let (contactHex, contactHexError) = contactPubKey!.hex
            guard contactHexError == nil else {
                throw contactHexError!
            }

            if searchHex == contactHex {
                return contact
            }
        }

        throw ContactsError.contactNotFound
    }

    deinit {
        contacts_destroy(ptr)
    }
}
