extension ChatVCAttachment {
    func checkOnline() {
        if isOnline {
            self.lblStatus.text = "online".localized
        } else {
            self.lblStatus.text = "offline".localized
        }
        getSupporter()
    }

    func getSupporter() {
    
        if supporters.count > 0 {
            setSupporterState()
            return
        }
        
        let query = GetSupportersQuery(integrationId: integrationId)
        apollo.fetch(query: query) { [weak self] result, error in
            
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            if let list = result?.data?.messengerSupporters, list.count > 0 {
                supporters = list as! [GetSupportersQuery.Data.MessengerSupporter]
                let supporter = supporters[0]
                supporterName = supporter.details?.fullName
                supporterAvatar = supporter.details?.avatar
                self?.setSupporterState()
            }
        }
    }
    
    func setSupporterState() {
        if supporters.count == 0 {
            supporterAvatar = "avatar.png"
            supporterName = "Хэрэглэгчид туслах"
            return
        }
        var title = ""
        for n in 0...supporters.count-1 {
            let user = supporters[n]
            if let iv = self.view.viewWithTag(101 + n) as? UIImageView {
                if let avatar = user.details?.avatar {
                    iv.downloadedFrom(link: avatar)
                    iv.layer.borderColor = erxesColor!.cgColor
                    iv.layer.borderWidth = 1
                    if n == 0 {
                        supporterAvatar = avatar
                    }
                }
            }
            if let names = user.details?.fullName?.split(separator: " ") {
                if names.count == 0 {
                    break
                }
                title += names[0]
                if n < supporters.count - 1 {
                    title += ", "
                }
            }
        }
        self.lblSupporterName.text = title
        if let supporterAvatar = supporterAvatar {
            self.ivSupporterAvatar.downloadedFrom(link: supporterAvatar)
        }
    }
}
