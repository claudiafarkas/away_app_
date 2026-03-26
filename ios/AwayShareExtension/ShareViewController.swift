import Social
import UniformTypeIdentifiers

final class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        return true
    }

    override func didSelectPost() {
        extractSharedUrl { [weak self] sharedUrl in
            guard let self = self else { return }

            if let sharedUrl = sharedUrl,
                 let encoded = sharedUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                 let deepLink = URL(string: "away://import?url=\(encoded)") {
                self.openHostApp(deepLink)
            }

            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }

    override func configurationItems() -> [Any]! {
        return []
    }

    private func extractSharedUrl(completion: @escaping (String?) -> Void) {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
                    let attachments = extensionItem.attachments,
                    !attachments.isEmpty else {
            completion(nil)
            return
    }

        let group = DispatchGroup()
        var foundUrl: String?

        for provider in attachments {
            if foundUrl != nil { break }

            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                    defer { group.leave() }
                    if let url = item as? URL {
                        foundUrl = url.absoluteString
                    } else if let str = item as? String {
                        foundUrl = str
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                group.enter()
                provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, _ in
                    defer { group.leave() }
                    if let str = item as? String,
                         str.contains("instagram.com/") {
                        foundUrl = str
                    }
                }
            }
    }

        group.notify(queue: .main) {
            completion(foundUrl)
        }
    }

    private func openHostApp(_ url: URL) {
        var responder: UIResponder? = self
        let selector = NSSelectorFromString("openURL:")

        while responder != nil {
            if responder?.responds(to: selector) == true {
                _ = responder?.perform(selector, with: url)
                return
            }
            responder = responder?.next
        }
    }
}
