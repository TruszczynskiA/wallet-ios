//  ChatSandbox.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 24/08/2023
	Using Swift 5.0
	Running on macOS 13.4

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

struct ChatError: CoreError {
    var code: Int
    var domain: String { "Chat" }

    init(code: Int32) {
        self.code = Int(code)
    }
}

final class ChatSandbox {

    private let corePath = FileManager.default.temporaryDirectory.appendingPathComponent("chat")
    private lazy var dbPath = corePath.path // .appendingPathComponent("chat_db.sqlite3").path
    private lazy var logPath = corePath.appendingPathComponent("log-\(Date().timeIntervalSince1970)").appendingPathExtension("txt").path
    private lazy var identityFilePath = corePath.appendingPathComponent("id_file").path

    private var client: ChatClient?

    init() {
        Task {
            do {
                print("[A] Logs: \(corePath)")
                print("[A][1]")

                let torTransportConfig = try await Tari.shared.makeTC()

                let config = try ApplicationConfig(
                    network: "stagenet",
                    publicAddress: "/ip4/127.0.0.1/tcp/39069",
                    datastorePath: dbPath,
                    identityFilePath: identityFilePath,
                    torTransportConfig: torTransportConfig,
                    logPath: logPath
                )

                //            var error: Int32 = -1
                //            let errorPointer = PointerHandler.pointer(for: &error)
                //            create_identity_file(config.pointer, errorPointer)
                //            print("[A] -> \(error)")

                print("[A][2]")
                client = try ChatClient(config: config)
                print("[A][3]")

                let tariAddress = try TariAddress(hex: "d02eedc0b102de4858b378d68f33c3ea7a0259eb750999377f66bcf766a32831d4")

                let message = try ChatMessage(address: tariAddress, message: "Hello World!")
//                var metadataType: Int32 = 1
//                let metadataTypePointer = PointerHandler.pointer(for: &metadataType)
                var errorCode: Int32 = -1
                let errorCodePointer = PointerHandler.pointer(for: &errorCode)

//                add_chat_message_metadata(message.pointer, metadataTypePointer, "Foo Bar Buzz", errorCodePointer)
                add_chat_message_metadata(message.pointer, 1, "Foo Bar Buzz", errorCodePointer)

                print("[A][4]")
                try await Task.sleep(nanoseconds: 60000000000 * 5)
//                try await Task.sleep(nanoseconds: 5000000000 * 1)
                try client?.send(message: message)
                print("[A][5]")

            } catch {
                print("[A] \(error)")
            }
        }
    }
}

final class ChatClient {

    private let pointer: OpaquePointer

    init(config: ApplicationConfig) throws {

        let contactStatusChangeCallback: (@convention(c) (UnsafeMutablePointer<ChatFFIContactsLivenessData>?) -> Void)? = { livenessData in
            print("[A] contactStatusChangeCallback: \(livenessData)")
        }

        let messageReceivedCallback: (@convention(c) (UnsafeMutablePointer<ChatFFIMessage>?) -> Void)? = { message in
            print("[A] \(message)")
        }

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = create_chat_client(config.pointer, errorCodePointer, contactStatusChangeCallback, messageReceivedCallback)

        guard errorCode == 0, let result else { throw ChatError(code: errorCode) }
        pointer = result
    }

    func send(message: ChatMessage) throws {

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        send_chat_message(pointer, message.pointer, errorCodePointer)

        guard errorCode == 0 else { throw ChatError(code: errorCode) }
    }

    deinit {
        destroy_chat_client_ffi(pointer)
    }
}

final class ApplicationConfig {

    let pointer: OpaquePointer

    init(network: String, publicAddress: String, datastorePath: String, identityFilePath: String, torTransportConfig: ChatTransportConfig, logPath: String) throws {

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = create_chat_config(network, publicAddress, datastorePath, identityFilePath, torTransportConfig.pointer, logPath, errorCodePointer)

        guard errorCode == 0, let result else { throw ChatError(code: errorCode) }
        pointer = result
    }

    deinit {
        destroy_chat_config(pointer)
    }
}

final class ChatMessage {

    let pointer: OpaquePointer

    init(address: TariAddress, message: String) throws {

        var errorCode: Int32 = -1
        let errorCodePointer = PointerHandler.pointer(for: &errorCode)
        let result = create_chat_message(address.pointer, message, errorCodePointer)

        guard errorCode == 0, let result else { throw ChatError(code: errorCode) }
        pointer = result
    }
}
