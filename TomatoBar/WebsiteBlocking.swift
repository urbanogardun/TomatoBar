// ABOUTME: Manages website blocking during work sessions using /etc/hosts
// ABOUTME: Uses sudoers configuration to avoid password prompts

import Foundation
import AppKit

class WebsiteBlockingHelper {
    static let shared = WebsiteBlockingHelper()
    
    private let hostsFilePath = "/etc/hosts"
    private let blockingIP = "127.0.0.1"
    private let markerStart = "# TomatoBar Blocking START - DO NOT EDIT"
    private let markerEnd = "# TomatoBar Blocking END"
    private let helperScriptPath = "/usr/local/bin/tomatobar-hosts"
    
    private init() {}
    
    func enableBlocking() {
        print("Enabling website blocking")
        
        // Check if helper script is set up
        if !isHelperConfigured() {
            showSetupInstructions()
        } else {
            updateHostsFile(enable: true)
        }
    }
    
    func disableBlocking() {
        print("Disabling website blocking")
        updateHostsFile(enable: false)
    }
    
    private func isHelperConfigured() -> Bool {
        // Check if our helper script exists and sudoers is configured
        return FileManager.default.fileExists(atPath: helperScriptPath)
    }
    
    private func showSetupInstructions() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "One-Time Setup Required"
            alert.informativeText = """
            TomatoBar needs to set up password-free website blocking.
            
            This will:
            • Create a helper script
            • Configure your system to allow TomatoBar to block sites without passwords
            • Only needs to be done once
            
            You'll be asked for your password once during setup.
            """
            alert.addButton(withTitle: "Run Setup Now")
            alert.addButton(withTitle: "Use with Password")
            
            if alert.runModal() == .alertFirstButtonReturn {
                self.runSetupScript()
            } else {
                // Use password method for now
                self.updateHostsFileWithPassword(enable: true)
            }
        }
    }
    
    private func runSetupScript() {
        // Create a temporary script file
        let scriptContent = getSetupScript()
        let tempScriptPath = NSTemporaryDirectory() + "tomatobar_setup.sh"
        
        do {
            try scriptContent.write(toFile: tempScriptPath, atomically: true, encoding: .utf8)
            
            // Make it executable
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: tempScriptPath)
            
            // Run the script with AppleScript (this will prompt for password)
            let appleScript = """
            do shell script "bash '\(tempScriptPath)'" with administrator privileges
            """
            
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: appleScript) {
                let result = scriptObject.executeAndReturnError(&error)
                
                if let error = error {
                    print("Setup error: \(error)")
                    showSetupError()
                } else {
                    print("Setup completed successfully")
                    showSetupSuccess()
                    
                    // Clean up temp file
                    try? FileManager.default.removeItem(atPath: tempScriptPath)
                    
                    // Now enable blocking
                    updateHostsFile(enable: true)
                }
            }
        } catch {
            print("Error creating setup script: \(error)")
            showSetupError()
        }
    }
    
    private func showSetupSuccess() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Setup Complete!"
            alert.informativeText = "TomatoBar can now block websites without asking for passwords. Website blocking is now active."
            alert.runModal()
        }
    }
    
    private func showSetupError() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Setup Failed"
            alert.informativeText = "There was an error setting up password-free blocking. You can still use website blocking with password prompts."
            alert.runModal()
        }
    }
    
    private func getSetupScript() -> String {
        return """
        #!/bin/bash
        # TomatoBar Website Blocking Setup Script
        
        # Create helper script
        sudo tee /usr/local/bin/tomatobar-hosts > /dev/null << 'EOF'
        #!/bin/bash
        # TomatoBar hosts file helper
        
        HOSTS_FILE="/etc/hosts"
        MARKER_START="# TomatoBar Blocking START - DO NOT EDIT"
        MARKER_END="# TomatoBar Blocking END"
        
        case "$1" in
            enable)
                # Remove existing block
                sudo sed -i '' "/$MARKER_START/,/$MARKER_END/d" "$HOSTS_FILE"
                
                # Add new block
                echo "" >> "$HOSTS_FILE"
                echo "$MARKER_START" >> "$HOSTS_FILE"
                shift
                for site in "$@"; do
                    echo "127.0.0.1 $site" >> "$HOSTS_FILE"
                    echo "127.0.0.1 www.$site" >> "$HOSTS_FILE"
                done
                echo "$MARKER_END" >> "$HOSTS_FILE"
                
                # Flush DNS
                dscacheutil -flushcache
                ;;
                
            disable)
                # Remove block
                sudo sed -i '' "/$MARKER_START/,/$MARKER_END/d" "$HOSTS_FILE"
                dscacheutil -flushcache
                ;;
        esac
        EOF
        
        # Make it executable
        sudo chmod +x /usr/local/bin/tomatobar-hosts
        
        # Add sudoers entry (allows running without password)
        echo "$USER ALL=(ALL) NOPASSWD: /usr/local/bin/tomatobar-hosts" | sudo tee /etc/sudoers.d/tomatobar
        
        echo "Setup complete! TomatoBar can now block websites without asking for passwords."
        """
    }
    
    private func updateHostsFile(enable: Bool) {
        let blockedSites = UserDefaults.standard.blockedWebsites
        
        if enable {
            // Use helper script if available
            let args = ["enable"] + blockedSites
            runHelperScript(args: args)
        } else {
            runHelperScript(args: ["disable"])
        }
    }
    
    private func runHelperScript(args: [String]) {
        let task = Process()
        task.launchPath = "/usr/bin/sudo"
        task.arguments = [helperScriptPath] + args
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                print("Hosts file updated successfully")
            } else {
                print("Error updating hosts file")
                // Fall back to password method
                updateHostsFileWithPassword(enable: args[0] == "enable")
            }
        } catch {
            print("Error running helper script: \(error)")
            updateHostsFileWithPassword(enable: args[0] == "enable")
        }
    }
    
    private func updateHostsFileWithPassword(enable: Bool) {
        let script: String
        
        if enable {
            let blockedSites = UserDefaults.standard.blockedWebsites
            var entries = "\n\(markerStart)\n"
            
            for site in blockedSites {
                entries += "\(blockingIP) \(site)\n"
                entries += "\(blockingIP) www.\(site)\n"
            }
            entries += "\(markerEnd)\n"
            
            script = """
            do shell script "
                # Remove existing TomatoBar entries
                sed -i '' '/\(markerStart)/,/\(markerEnd)/d' \(hostsFilePath)
                
                # Add new entries
                echo '\(entries)' >> \(hostsFilePath)
                
                # Flush DNS cache
                dscacheutil -flushcache
            " with administrator privileges
            """
        } else {
            script = """
            do shell script "
                # Remove TomatoBar entries
                sed -i '' '/\(markerStart)/,/\(markerEnd)/d' \(hostsFilePath)
                
                # Flush DNS cache
                dscacheutil -flushcache
            " with administrator privileges
            """
        }
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            
            if let error = error {
                print("Error updating hosts file: \(error)")
            } else {
                print("Hosts file updated with password")
            }
        }
    }
    
    static func requestAuthorization() async throws {
        // No authorization needed
    }
    
    static func isAuthorized() -> Bool {
        return true
    }
}

// Extension to store blocked websites
extension UserDefaults {
    private static let blockedWebsitesKey = "blockedWebsites"
    private static let toggleWebsiteBlockingKey = "toggleWebsiteBlocking"
    
    var blockedWebsites: [String] {
        get {
            return array(forKey: UserDefaults.blockedWebsitesKey) as? [String] ?? [
                "twitter.com",
                "x.com",
                "instagram.com",
                "youtube.com",
                "reddit.com",
                "tiktok.com",
                "facebook.com"
            ]
        }
        set {
            set(newValue, forKey: UserDefaults.blockedWebsitesKey)
        }
    }
    
    var toggleWebsiteBlocking: Bool {
        get {
            return bool(forKey: UserDefaults.toggleWebsiteBlockingKey)
        }
        set {
            set(newValue, forKey: UserDefaults.toggleWebsiteBlockingKey)
        }
    }
}