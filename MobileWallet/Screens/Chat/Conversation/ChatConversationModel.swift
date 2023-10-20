//  ChatConversationModel.swift

/*
	Package MobileWallet
	Created by Adrian Truszczyński on 14/09/2023
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

import UIKit
import Combine

final class ChatConversationModel { // TODO: Dynamic separator's format - 13 min. ago -> 14. min. ago

    struct UserData {
        let avatarText: String?
        let avatarImage: UIImage?
        let isOnline: Bool
        let name: String?
    }

    struct MessageSection {
        let relativeDay: String
        let messages: [Message]
    }

    struct Message: Identifiable {
        let id: String
        let isIncomming: Bool
        let isLastInContext: Bool
        let notificationParts: [StylizedLabel.StylizedText]
        let message: String
        let timestamp: String
    }

    enum Action {
        case openContactDetails(contact: ContactsManager.Model)
    }

    // MARK: - View Model

    @Published private(set) var userData: UserData?
    @Published private(set) var messages: [MessageSection] = []
    @Published private(set) var action: Action?

    // MARK: - Properties

    private let address: TariAddress
    private let dateFormatter = DateFormatter.shortDate
    private let hourFormatter = DateFormatter.hour
    private let contactsManager = ContactsManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialisers

    init(address: TariAddress) {
        self.address = address
        setupCallbacks()

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { // TODO: !
            self.messages = []
        }
    }

    // MARK: - Setups

    private func setupCallbacks() {

        try? Tari.shared.chatMessagesService.messages(address: address) // TODO: Try?
            .compactMap { [weak self] in try? self?.messagesSections(chatMessages: $0) } // TODO: try?
            .sink { [weak self] in self?.messages = $0 }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    func updateUserData() {
        generateUserData() // TODO: Merge
    }

    func requestContactDetails() {

        do {
            let contact = try contactsManager.contact(address: address) ?? ContactsManager.Model(address: address)
            action = .openContactDetails(contact: contact)
        } catch {
            // TODO: Handle
            print("[A] \(error)")
        }
    }

    func send(message: String) {
        do {
            try Tari.shared.chatMessagesService.send(message: message, receiver: address)
        } catch {
            // TODO: Handle
            print("[A] \(error)")
        }
    }

    private func generateUserData() {

        Task {
            do {
                try await contactsManager.fetchModels()
                let contact = try contactsManager.contact(address: address)

                userData = try UserData(
                    avatarText: contact?.avatar ?? address.emojis.firstOrEmpty,
                    avatarImage: contact?.avatarImage,
                    isOnline: false, // TODO: !
                    name: contact?.name ?? address.emojis.obfuscatedText
                )
            } catch {
                // TODO: Handle
            }
        }
    }

    // MARK: - Handlers

    private func messagesSections(chatMessages: [ChatMessage]) throws -> [MessageSection] {

        return try chatMessages // TODO: Try?
            .reversed()
            .reduce(into: [String: [Message]]()) { result, chatMessage in

                let timestamp = try Date(timeIntervalSince1970: TimeInterval(chatMessage.timestamp))
//                guard let relativeDay = timestamp.relativeDayFromToday() else { return }
                let relativeDay = dateFormatter.string(from: timestamp)

                let message = try Message(
                    id: chatMessage.identifier.string ?? "",
                    isIncomming: chatMessage.direction == 1, // TODO: Move to extenstion
                    isLastInContext: false, // TODO: !
                    notificationParts: [], // TODO: !
                    message: chatMessage.body.string ?? "",
                    timestamp: hourFormatter.string(from: timestamp)
                )

                var messages = result[relativeDay] ?? []
                messages.append(message)
                result[relativeDay] = messages

            }
            .sorted { $0.key < $1.key } // TODO: Sort
            .map { MessageSection(relativeDay: $0.key, messages: $0.value) }
    }
}
