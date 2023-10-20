//  ChatTester.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 26/09/2023
	Using Swift 5.0
	Running on macOS 13.5

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

final class ChatTester { // TODO: Remove

    private let corePath = FileManager.default.temporaryDirectory.appendingPathComponent("chat")
    private lazy var dbPath = corePath.path
    private lazy var logPath = corePath.appendingPathComponent("log-\(Date().timeIntervalSince1970)").path
    private lazy var identityFilePath = corePath.appendingPathComponent("id_file").path

    let shared = ChatTester()

    private var chatClient: ChatClient?

    func start() {

//        Task {
//            do {
//                let transportConfig = try await Tari.shared.makeTC()
//                let config = try makeConfig(transportConfig: transportConfig)
//                chatClient = try ChatClient(config: config)
//            } catch {
//                print("[A] \(error)")
//            }
//        }
    }

    private func makeConfig(transportConfig: TransportConfig) throws -> ChatConfig {
        try ChatConfig(
            network: NetworkManager.shared.selectedNetwork.name,
            publicAddress: "/ip4/127.0.0.1/tcp/39069",
            datastorePath: dbPath,
            identityFilePath: identityFilePath,
            torTransportConfig: transportConfig,
            logPath: logPath,
            logVerbosity: 0
        )
    }
}
