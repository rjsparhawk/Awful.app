//  SettingsUbiquitousThemesController.swift
//
//  Copyright 2016 Awful Contributors. CC BY-NC-SA 3.0 US https://github.com/Awful/Awful.app

import UIKit

final class SettingsUbiquitousThemesController: TableViewController {
    
    private var ignoreSettingsChanges = false
    private var observer: NSKeyValueObservation?
    private var selectedThemeNames: Set<String> = []
    private var themes: [Theme] = []
    
    init() {
        super.init(style: .grouped)
        
        title = "Forum-Specific Themes"
        loadData()
    }
    
    private func loadData() {
        themes = Theme.allThemes.filter { $0.forumID != nil }
        selectedThemeNames = Set(UserDefaults.standard.ubiquitousThemeNames ?? [])
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellID)
        tableView.separatorStyle = .none
        
        observer = UserDefaults.standard.observeOnMain(\.ubiquitousThemeNames, changeHandler: { [unowned self] defaults, change in
            self.loadData()
            self.tableView.reloadData()
        })
    }
    
    // MARK: UITableViewDataSource and UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return themes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        let theme = themes[(indexPath as NSIndexPath).row]
        
        cell.textLabel?.text = theme.descriptiveName
        cell.textLabel?.textColor = theme["listTextColor"]
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: UIFont.TextStyle.subheadline)
        guard let fontName = theme[string: "listFontName"] ?? descriptor.object(forKey: .name) as? String else {
            fatalError("\(#function) couldn't find font name")
        }
        cell.textLabel?.font = UIFont(name: fontName, size: descriptor.pointSize)
        
        cell.accessoryType = selectedThemeNames.contains(theme.name) ? .checkmark : .none
        cell.backgroundColor = theme["listBackgroundColor"]
        cell.tintColor = theme["listSecondaryTextColor"]
        
        let selectedBackground = cell.selectedBackgroundView ?? UIView()
        selectedBackground.backgroundColor = theme["listSelectedBackgroundColor"]
        cell.selectedBackgroundView = selectedBackground
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Selected themes become available in every forum."
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let text = tableView.dataSource?.tableView?(tableView, titleForFooterInSection: section) else { return 0 }
        let maxSize = CGSize(width: tableView.bounds.width - 40, height: .greatestFiniteMagnitude)
        let expected = (text as NSString).boundingRect(with: maxSize, options: .usesLineFragmentOrigin, attributes: [.font: UIFont.preferredFont(forTextStyle: .footnote)], context: nil)
        return ceil(expected.height) + 14
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let theme = themes[(indexPath as NSIndexPath).row]
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        if selectedThemeNames.contains(theme.name) {
            selectedThemeNames.remove(theme.name)
            cell.accessoryType = .none
        } else {
            selectedThemeNames.insert(theme.name)
            cell.accessoryType = .checkmark
        }
        
        ignoreSettingsChanges = true
        UserDefaults.standard.ubiquitousThemeNames = Array(selectedThemeNames)
        ignoreSettingsChanges = false
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let headerView = view as? UITableViewHeaderFooterView else { return }
        headerView.contentView.backgroundColor = theme["listHeaderBackgroundColor"]
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard let footerView = view as? UITableViewHeaderFooterView else { return }
        footerView.textLabel?.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.footnote)
        footerView.contentView.backgroundColor = theme["listHeaderBackgroundColor"]
    }
    
    // MARK: Gunk
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private let cellID = "Cell"
