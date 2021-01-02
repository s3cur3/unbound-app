
func cancellableAlert(title: String, body: String) -> NSApplication.ModalResponse {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = body
    alert.addButton(withTitle: "OK")
    alert.addButton(withTitle: "Cancel")
    return alert.runModal()
}

func modalAlert(title: String, body: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = body
    alert.addButton(withTitle: "OK")
    alert.runModal()
}
