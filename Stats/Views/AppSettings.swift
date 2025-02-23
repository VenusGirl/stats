//
//  AppSettings.swift
//  Stats
//
//  Created by Serhiy Mytrovtsiy on 15/04/2020.
//  Using Swift 5.0.
//  Running on macOS 10.15.
//
//  Copyright © 2020 Serhiy Mytrovtsiy. All rights reserved.
//

import Cocoa
import Kit

class ApplicationSettings: NSStackView {
    private var updateIntervalValue: String {
        get {
            return Store.shared.string(key: "update-interval", defaultValue: AppUpdateInterval.silent.rawValue)
        }
    }
    
    private var temperatureUnitsValue: String {
        get {
            return Store.shared.string(key: "temperature_units", defaultValue: "system")
        }
        set {
            Store.shared.set(key: "temperature_units", value: newValue)
        }
    }
    
    private let updateWindow: UpdateWindow = UpdateWindow()
    
    init() {
        super.init(frame: NSRect(
            x: 0,
            y: 0,
            width: 540,
            height: 480
        ))
        
        self.orientation = .vertical
        self.distribution = .fill
        self.spacing = 0
        
        self.addArrangedSubview(self.informationView())
        self.addArrangedSubview(self.separatorView())
        self.addArrangedSubview(self.settingsView())
        self.addArrangedSubview(self.separatorView())
        self.addArrangedSubview(self.buttonsView())
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func informationView() -> NSView {
        let view = NSStackView()
        view.heightAnchor.constraint(equalToConstant: 240).isActive = true
        view.orientation = .vertical
        view.distribution = .fill
        view.alignment = .centerY
        view.spacing = 0
        
        let container: NSGridView = NSGridView()
        container.heightAnchor.constraint(equalToConstant: 180).isActive = true
        container.rowSpacing = 0
        container.yPlacement = .center
        container.xPlacement = .center
        
        let iconView: NSImageView = NSImageView(image: NSImage(named: NSImage.Name("AppIcon"))!)
        
        let statsName: NSTextField = TextView(frame: NSRect(x: 0, y: 0, width: view.frame.width, height: 22))
        statsName.alignment = .center
        statsName.font = NSFont.systemFont(ofSize: 20, weight: .regular)
        statsName.stringValue = "Stats"
        statsName.isSelectable = true
        
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        
        let statsVersion: NSTextField = TextView(frame: NSRect(x: 0, y: 0, width: view.frame.width, height: 16))
        statsVersion.alignment = .center
        statsVersion.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        statsVersion.stringValue = "\(localizedString("Version")) \(versionNumber)"
        statsVersion.isSelectable = true
        statsVersion.toolTip = "\(localizedString("Build number")) \(buildNumber)"
        
        let updateButton: NSButton = NSButton()
        updateButton.title = localizedString("Check for update")
        updateButton.bezelStyle = .rounded
        updateButton.target = self
        updateButton.action = #selector(self.updateAction)
        
        container.addRow(with: [iconView])
        container.addRow(with: [statsName])
        container.addRow(with: [statsVersion])
        container.addRow(with: [updateButton])
        
        container.row(at: 1).height = 22
        container.row(at: 2).height = 20
        container.row(at: 3).height = 30
        
        view.addArrangedSubview(container)
        
        return view
    }
    
    private func settingsView() -> NSView {
        let view: NSView = NSView(frame: NSRect(x: 0, y: 0, width: self.frame.width, height: 0))
        
        let grid: NSGridView = NSGridView(frame: NSRect(x: 0, y: 0, width: view.frame.width, height: 0))
        grid.rowSpacing = 10
        grid.columnSpacing = 20
        grid.xPlacement = .trailing
        grid.rowAlignment = .firstBaseline
        grid.translatesAutoresizingMaskIntoConstraints = false
        
        grid.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        grid.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        grid.addRow(with: [
            self.titleView(localizedString("Check for updates")),
            selectView(
                action: #selector(self.toggleUpdateInterval),
                items: AppUpdateIntervals,
                selected: self.updateIntervalValue
            )
        ])
        grid.addRow(with: [
            self.titleView(localizedString("Temperature")),
            selectView(
                action: #selector(self.toggleTemperatureUnits),
                items: TemperatureUnits,
                selected: self.temperatureUnitsValue
            )
        ])
        grid.addRow(with: [NSGridCell.emptyContentView, self.toggleView(
            action: #selector(self.toggleDock),
            state: Store.shared.bool(key: "dockIcon", defaultValue: false),
            text: localizedString("Show icon in dock")
        )])
        grid.addRow(with: [NSGridCell.emptyContentView, self.toggleView(
            action: #selector(self.toggleLaunchAtLogin),
            state: LaunchAtLogin.isEnabled,
            text: localizedString("Start at login")
        )])
        
        view.addSubview(grid)
        
        NSLayoutConstraint.activate([
            grid.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grid.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }
    
    private func buttonsView() -> NSView {
        let view = NSStackView()
        view.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let reset: NSButton = NSButton()
        reset.title = localizedString("Reset settings")
        reset.bezelStyle = .rounded
        reset.target = self
        reset.action = #selector(self.resetSettings)
        
        view.addArrangedSubview(reset)
        
        return view
    }
    
    // MARK: - helpers
    
    private func separatorView() -> NSBox {
        let view = NSBox()
        view.boxType = .separator
        return view
    }
    
    private func titleView(_ value: String) -> NSTextField {
        let field: NSTextField = TextView(frame: NSRect(x: 0, y: 0, width: 120, height: 17))
        field.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        field.textColor = .secondaryLabelColor
        field.stringValue = value
        
        return field
    }
    
    private func toggleView(action: Selector, state: Bool, text: String) -> NSView {
        let button: NSButton = NSButton(frame: NSRect(x: 0, y: 0, width: 30, height: 20))
        button.setButtonType(.switch)
        button.state = state ? .on : .off
        button.title = text
        button.action = action
        button.isBordered = false
        button.isTransparent = false
        button.target = self
        
        return button
    }
    
    // MARK: - actions
    
    @objc func updateAction(_ sender: NSObject) {
        updater.check(force: true, completion: { result, error in
            if error != nil {
                debug("error updater.check(): \(error!.localizedDescription)")
                return
            }
            
            guard error == nil, let version: version_s = result else {
                debug("download error(): \(error!.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async(execute: {
                self.updateWindow.open(version)
                return
            })
        })
    }
    
    @objc private func toggleUpdateInterval(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else {
            return
        }
        
        Store.shared.set(key: "update-interval", value: key)
    }
    
    @objc private func toggleTemperatureUnits(_ sender: NSMenuItem) {
        guard let key = sender.representedObject as? String else {
            return
        }
        self.temperatureUnitsValue = key
    }
    
    @objc func toggleDock(_ sender: NSButton) {
        let state = sender.state
        
        Store.shared.set(key: "dockIcon", value: state == NSControl.StateValue.on)
        let dockIconStatus = state == NSControl.StateValue.on ? NSApplication.ActivationPolicy.regular : NSApplication.ActivationPolicy.accessory
        NSApp.setActivationPolicy(dockIconStatus)
        if state == .off {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
    }
    
    @objc func toggleLaunchAtLogin(_ sender: NSButton) {
        LaunchAtLogin.isEnabled = sender.state == NSControl.StateValue.on
        if !Store.shared.exist(key: "runAtLoginInitialized") {
            Store.shared.set(key: "runAtLoginInitialized", value: true)
        }
    }
    
    @objc func resetSettings(_ sender: NSObject) {
        let alert = NSAlert()
        alert.messageText = localizedString("Reset settings")
        alert.informativeText = localizedString("Reset settings text")
        alert.alertStyle = .warning
        alert.addButton(withTitle: localizedString("Yes"))
        alert.addButton(withTitle: localizedString("No"))
        
        if alert.runModal() == .alertFirstButtonReturn {
            Store.shared.reset()
            if let path = Bundle.main.resourceURL?.deletingLastPathComponent().deletingLastPathComponent().absoluteString {
                asyncShell("/usr/bin/open \(path)")
                NSApp.terminate(self)
            }
        }
    }
}
