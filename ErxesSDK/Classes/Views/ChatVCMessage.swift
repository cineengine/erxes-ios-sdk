import LiveGQL

public class ChatVCMessage: UIViewController {

    @IBOutlet weak var tfInput: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var tv: UITableView!
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var wvChat: UIWebView!
    @IBOutlet weak var progress: UIProgressView!
    @IBOutlet weak var btnCancel: UIButton!
    @IBOutlet weak var uploadView: UIView!
    @IBOutlet weak var uploadLoader: UIActivityIndicatorView!
    @IBOutlet weak var ivPicked: UIImageView!
    @IBOutlet weak var lblFilesize: UILabel!
    @IBOutlet weak var loader: UIView!
    @IBOutlet weak var lblLoader: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    var bg = "#7754b3"
    var css = ""
    var attachments = [AttachmentInput]()
    var inited = false
    var attached = false
    var isNewConversation = false
    let gql = LiveGQL(socket: subsUrl)

    var receivedMessage = ""

    func subscribe() {
        
        if isSaas {
            gql.subscribe(graphql: "subscription{conversationMessageInserted(_id:\"\(conversationId!)\"){content,userId,createdAt,customerId,user,attachments{url,name,type,size}}}", variables: nil, operationName: nil, identifier: "conversationMessageInserted")
        }else {
            gql.subscribe(graphql: "subscription{conversationMessageInserted(_id:\"\(conversationId!)\"){content,userId,createdAt,customerId,user{details{avatar}},attachments{url,name,type,size}}}", variables: nil, operationName: nil, identifier: "conversationMessageInserted")
        }
        
    }

    func initChat() {

        bg = erxesColorHex

        var str = ""
        let now = Utils.now()

        if msgGreetings.count > 0, conversationId == nil {
            str = "<div class=\"row\"><div class=\"img\"><img src=\"\(supporterAvatar!)\"/></div><div class=\"text\"><a>\(msgGreetings ?? "")</a></div><div class=\"date\">\(now!)</div></div>"
        }

        css = "<style>.row,.row .text{overflow:hidden}body{background:url(bg-1.png);background:#f4f4f4;padding:0;margin:0 20px}.row{position:relative;margin-bottom:10px;margin-top:15px;font-family:Roboto,Arial,sans-serif;font-weight:500}.row .text a{float:left;padding:12px 20px;background:#ebebeb;border-radius:20px 20px 20px 2px;color:#444;margin-bottom:5px;margin-left:38px;margin-right:40px;font-size:14px;box-shadow:0 1px 1px 0 rgba(0,0,0,.2)}.me .text a{float:right;background:\(bg);color:#fff;border-radius:20px 2px 20px 20px;margin-left:50px;margin-right:0}.row .text img{max-width:100%;padding-top:3px}.row .date{color:#cbcbcb;font-size:11px;margin-left:36px}.me .date{text-align:right}.row .img{float:left;position:absolute;bottom:17px;left:0;margin-right:8px}.row .img img{width:30px;height:30px;border-radius:15px;box-sizing:border-box;border:1px solid white;}.me .img{display:none}.me .img img{margin-right:0;margin-left:8px}p{display:inline}</style>\(str)"
    }

    func sendMessage(_ msg: String) {

        if attachments.count == 0 && msg.count == 0 {
            return
        }

        var mutation = InsertMessageMutation(integrationId: integrationId, customerId: erxesCustomerId, message: msg)

        if conversationId != nil {
            mutation.conversationId = conversationId
        }

        if attachments.count > 0 {
            mutation.attachments = attachments
            mutation.message = "attachment"
        }

        apollo.perform(mutation: mutation) { [weak self] result, error in
            self?.uploadView.isHidden = true
            if let error = error {
                print(error.localizedDescription)
                return
            }
            self?.tfInput.text = ""
            
            
            
            if conversationId == nil {
                conversationId = result?.data?.insertMessage?.fragments.messageObject.conversationId
                self?.subscribe()
                self?.loadMessages()
            }else {
                if let item = result?.data?.insertMessage?.fragments.messageObject {
//                    self!.appendToChat(item)
                }
                
            }
            self?.attachments = [AttachmentInput]()
        }
    }

    func appendToChat(_ item: MessageObject) {
        if let message:MessageObject = item {
            var str = ""
            if let content = message.content {
                str = content
            }
            let now = Utils.now()
            var me = ""
            if let customerId = message.customerId {
                if customerId == erxesCustomerId {
                    me = "me"
                }
            }
            var avatar = "avatar.png"
            if let userAvatar = message.user?.details?.avatar {
                avatar = userAvatar
            }
            var image = ""
            if let attachments = message.attachments, attachments.count > 0 {
                let attachment = attachments[0]
                if ((attachment?.url) != nil) && attachment?.url.count != 0 {
                    image = attachment!.url
                    attached = true
                }
            }
            var chat = message.content!.withoutHtml
            if chat.contains("http") {
                let types: NSTextCheckingResult.CheckingType = .link

                let detector = try! NSDataDetector(types: types.rawValue)
                let matches = detector.matches(in: message.content!, options: [], range: NSMakeRange(0, message.content!.utf16.count))
                if matches.count != 0 {
                    for match in matches {
                        let host = match.url?.host
                        let url = match.url?.absoluteString
                        
                        if (chat.contains(url!)) {
                            chat = chat.replacingOccurrences(of: url!, with: "<a href=\(url!)>\(host!)</a><a>")
                        }else {
                            let decodedUrl = url?.removingPercentEncoding?.withoutHtml
                            chat = chat.replacingOccurrences(of: decodedUrl!, with: "<a href=\(decodedUrl!)>\(host!)</a><a>")
                        }
                    }
                }

            }
            str = "<div class=\"row \(me)\"><div class=\"img\"><img src=\"\(avatar)\"/></div><div class=\"text\"><a>\(chat)<img src=\"\(image)\"/></a></div><div class=\"date\">\(now!)</div></div>"
            str = "document.body.innerHTML += '\(str)';window.location.href = \"inapp://scroll\""
            self.wvChat.stringByEvaluatingJavaScript(from: str)
        }
    }
    
    func insertAdminMessage(_ item: MessageSubs) {
        if let message = item.payload?.data?.conversationMessageInserted {
            
            var str = ""
            
            if let content = message.content {
                str = content
            }
            
            let now = Utils.now()
            
            var me = ""
            
            if let customerId = message.customerId {
                if customerId == erxesCustomerId {
                    me = "me"
                }
            }
            
            var avatar = "avatar.png"
            
            if let userAvatar = message.user?.details?.avatar {
                avatar = userAvatar
            }
            
            var image = ""
            
            if let attachments = message.attachments, attachments.count > 0 {
                let attachment = attachments[0]
                if let img = attachment!.url {
                    image = img
                    attached = true
                }
            }
            
            
            var chat = message.content!.withoutHtml
            
            if chat.contains("http") {
                let types: NSTextCheckingResult.CheckingType = .link
                
                let detector = try! NSDataDetector(types: types.rawValue)
                let matches = detector.matches(in: message.content!, options: [], range: NSMakeRange(0, message.content!.utf16.count))
                if matches.count != 0 {
                    for match in matches {
                        let host = match.url?.host
                        let url = match.url?.absoluteString
                        
                        if (chat.contains(url!)) {
                            chat = chat.replacingOccurrences(of: url!, with: "<a href=\(url!)>\(host!)</a><a>")
                        }else {
                            let decodedUrl = url?.removingPercentEncoding?.withoutHtml
                            chat = chat.replacingOccurrences(of: decodedUrl!, with: "<a href=\(decodedUrl!)>\(host!)</a><a>")
                        }
                    }
                }
                
            }
            str = "<div class=\"row \(me)\"><div class=\"img\"><img src=\"\(avatar)\"/></div><div class=\"text\"><a>\(chat)<img src=\"\(image)\"/></a></div><div class=\"date\">\(now!)</div></div>"
            
            str = "document.body.innerHTML += '\(str)';window.location.href = \"inapp://scroll\""
            
            self.wvChat.stringByEvaluatingJavaScript(from: str)
            
        }
    }
    
    
    

    func loadMessages() {
        if conversationId == nil {
            return
        }

        let messagesQuery = MessagesQuery(conversationId: conversationId!)
        apollo.fetch(query: messagesQuery, cachePolicy: .fetchIgnoringCacheData) { [weak self] result, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let allMessages = result?.data?.messages as? [MessagesQuery.Data.Message] {
                self?.processMessagesResult(messages: allMessages)
            }
        }
    }

    func processMessagesResult(messages: [MessagesQuery.Data.Message]) {
        let messagesArray = messages.map { ($0.fragments.messageObject) }
        var me = ""
        var str = ""

        for item in messagesArray {
            
            let created = item.createdAt!
            let now = Utils.formatDate(time: created)
   
            var avatar = "avatar.png"

            if let user = item.user {
                if let userAvatar = user.details?.avatar {
                    avatar = userAvatar
                }
            }

            me = ""
            if let customerId = item.customerId {
                if customerId == erxesCustomerId {
                    me = "me"
                }
            }
            let image: String = self.extractAttachment(item: item)


            var chat = item.content?.withoutHtml
            if (chat?.contains("http"))! {
                let types: NSTextCheckingResult.CheckingType = .link
                let detector = try! NSDataDetector(types: types.rawValue)
                let matches = detector.matches(in: item.content!, options: [], range: NSMakeRange(0, item.content!.utf16.count))
                
                if matches.count != 0 {
                    for match in matches {
                        let host = match.url?.host
                        let url = match.url?.absoluteString
                       
                        if (chat?.contains(url!))! {
                            chat = chat!.replacingOccurrences(of: url!, with: "<a href=\(url!)>\(host!)</a><a>")
                        }else {
                            let decodedUrl = url?.removingPercentEncoding?.withoutHtml
                            chat = chat!.replacingOccurrences(of: decodedUrl!, with: "<a href=\(decodedUrl!)>\(host!)</a><a>")
                        }
                    }
                }
            }

            str = str + "<div class=\"row \(me)\"><div class=\"img\"><img src=\"\(avatar)\"/></div><div class=\"text\"><a>\(chat!)<img src=\"\(image)\"/></a></div><div class=\"date\">\(now!)</div></div>"
        }

        self.inited = true
        str = "document.body.innerHTML += '\(str)';window.location.href = \"inapp://scroll\""
        self.wvChat.stringByEvaluatingJavaScript(from: str)
    }

    func extractAttachment(item: MessageObject) -> String {
        var image = ""
        if let attachments = item.attachments {
            if attachments.count > 0 {
                let attachment = attachments[0]

                if let url = attachment?.url {
                    image = url
                    self.attached = true
                }
            }
        }
        return image
    }
}

extension ChatVC: LiveGQLDelegate {

    public func receivedRawMessage(text: String) {
      
            
            do {
                if receivedMessage != text {
                    receivedMessage = text
                
                    if let dataFromString = receivedMessage.data(using: .utf8, allowLossyConversion: false) {
                        let item = try JSONDecoder().decode(MessageSubs.self, from: dataFromString)
                        self.insertAdminMessage(item)
                    }
                }
            }
            catch {
                print(error)
            }
        
       
    }


}

extension ChatVC: UIWebViewDelegate {

    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {

        if navigationType == UIWebViewNavigationType.linkClicked {
            UIApplication.shared.openURL(request.url!)
            return false
        }

        if request.url?.scheme == "inapp" {
            if request.url?.host == "scroll" {
                let scrollPoint = CGPoint(x: 0, y: self.wvChat.scrollView.contentSize.height - self.wvChat.frame.size.height)
                self.wvChat.scrollView.setContentOffset(scrollPoint, animated: true)

                if attached {
                    attached = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                        let scrollPoint = CGPoint(x: 0, y: self.wvChat.scrollView.contentSize.height - self.wvChat.frame.size.height)
                        self.wvChat.scrollView.setContentOffset(scrollPoint, animated: true)
                    })
                }

                return false
            }
        }
        return true
    }

    public func webViewDidFinishLoad(_ webView: UIWebView) {

        loadEnd()

        if(!inited) {
            loadMessages()
        }
    }
}
