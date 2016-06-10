//
// AccountSettingsViewController.swift
//
// Tigase iOS Messenger
// Copyright (C) 2016 "Tigase, Inc." <office@tigase.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License,
// or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. Look for COPYING file in the top folder.
// If not, see http://www.gnu.org/licenses/.
//

import UIKit
import TigaseSwift

class AccountSettingsViewController: UITableViewController {
    
    var xmppService: XmppService {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate;
        return delegate.xmppService;
    }
    
    var account: String! {
        didSet {
            accountJid = BareJID(account);
        }
    }
    var accountJid: BareJID!;
    
    @IBOutlet var avatarView: UIImageView!
    @IBOutlet var fullNameTextView: UILabel!
    @IBOutlet var companyTextView: UILabel!
    @IBOutlet var addressTextView: UILabel!
    
    @IBOutlet var enabledSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad();
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
        navigationItem.title = account;

        let config = AccountManager.getAccount(account);
        enabledSwitch.on = config?.active ?? false;

        if let vcard = xmppService.dbVCardsCache.getVCard(accountJid) {
            update(vcard);
        }
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.row == 0 && indexPath.section == 1 {
            return nil;
        }
        return indexPath;
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        guard segue.identifier != nil else {
            return;
        }
        switch segue.identifier! {
        case "EditAccountSegue":
            let navigation = segue.destinationViewController as! UINavigationController;
            let destination = navigation.visibleViewController as! AddAccountController;
            destination.account = account;
        case "EditAccountVCardSegue":
            let navigation = segue.destinationViewController as! UINavigationController;
            let destination = navigation.visibleViewController as! VCardEditViewController;
            destination.account = account;
        default:
            break;
        }
    }
    
    @IBAction func enabledSwitchChangedValue(sender: AnyObject) {
        if let config = AccountManager.getAccount(account) {
            config.active = enabledSwitch.on;
            AccountManager.updateAccount(config);
        }
    }
    
    func update(vcard: VCardModule.VCard) {
        avatarView.image = xmppService.avatarManager.getAvatar(accountJid, account: accountJid);
        avatarView.layer.masksToBounds = true;
        avatarView.layer.cornerRadius = avatarView.frame.width / 2;
        
        if let fn = vcard.fn {
            fullNameTextView.text = fn;
        } else if let family = vcard.familyName, let given = vcard.givenName {
            fullNameTextView.text = "\(given) \(family)";
        } else {
            fullNameTextView.text = account;
        }
        
        let company = vcard.orgName;
        let role = vcard.role;
        if role != nil && company != nil {
            companyTextView.text = "\(role!) at \(company!)";
        } else if company != nil {
            companyTextView.text = company;
        } else if role != nil {
            companyTextView.text = role;
        }
        companyTextView.hidden = companyTextView.text == nil;
        
        var addresses = vcard.addresses.filter { (addr) -> Bool in
            return !addr.isEmpty();
        };
        
        if let address = addresses.first {
            var tmp = [String]();
            if address.street != nil {
                tmp.append(address.street!);
            }
            if address.locality != nil {
                tmp.append(address.locality!);
            }
            if address.country != nil {
                tmp.append(address.country!);
            }
            addressTextView.text = tmp.joinWithSeparator(", ");
        } else {
            addressTextView.text = nil;
        }
    }
}
