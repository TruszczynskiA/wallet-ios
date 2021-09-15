//  iCloudServiceMock.swift
	
/*
	Package MobileWallet
	Created by S.Shovkoplyas on 10.07.2020
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
import CloudKit

class ICloudServiceMock {
    private static let testICloudFolder = "test_icloud_folder"
    private static let backupName = "Tari-Aurora-Backup"
    
    static func downloadBackup() throws -> Backup {
        let directory = try getTestICloudDirectory()
        let backupUrl = directory.appendingPathComponent(backupName)
        return try Backup(url: backupUrl)
    }
    
    static func uploadBackup(_ backup: Backup) throws {
        let directory = try getTestICloudDirectory()
        if !FileManager.default.secureCopyItem(at: backup.url, to: directory.appendingPathComponent(backup.url.lastPathComponent)) {
            throw ICloudBackupError.failedToCreateZip
        }
    }
    
    static func removeBackups() throws {
        try FileManager.default.removeItem(atPath: getTestICloudDirectory().path)
    }
    
    private static func getTestICloudDirectory() throws -> URL {
        if let iCloudDirectory = FileManager.default.documentDirectory()?.appendingPathComponent(testICloudFolder) {
            
            if !FileManager.default.fileExists(atPath: iCloudDirectory.path) {
                try FileManager.default.createDirectory(at: iCloudDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            
            return iCloudDirectory
        } else { throw ICloudBackupError.iCloudContainerNotFound }
    }
}
