import Foundation


class WebSocketService {
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    
    var onMessageReceived: ((String) -> Void)?
    
    
    
    
    
    func connect(api: LiveWSApi) {
        // 关键点：在开启新连接前，先强行断开并清理旧任务
        disconnect()
        
        guard let url = api.buildURL else {
            print("❌ WebSocket URL 组装失败")
            return
        }
        
        let request = URLRequest(url: url)
        
        // 发起新连接
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        print("✅ WebSocket 开始新连接: \(url.absoluteString)")
        
        receiveMessage()
    }

    
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    let fixedText = self.fixDoubleEscapedJSON(text)
                    print("【WebSocket：】📩 收到原始消息: \(fixedText)")
                    self.onMessageReceived?(fixedText)
                    
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        let fixedText = self.fixDoubleEscapedJSON(text)
                        self.onMessageReceived?(fixedText)
                    }
                @unknown default:
                    break
                }
                self.receiveMessage()
                
            case .failure(let error):
                if (error as NSError).code != URLError.cancelled.rawValue {
                    print("❌ WebSocket 断开或报错: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - 终极修复：彻底去掉 \ 反斜杠
    private func fixDoubleEscapedJSON(_ text: String) -> String {
        var cleanedText = text
        
        // 1. 去掉首尾引号
        if cleanedText.first == "\"" && cleanedText.last == "\"" {
            cleanedText.removeFirst()
            cleanedText.removeLast()
        }
        
        // 2. 把 \" 变成 "
        cleanedText = cleanedText.replacingOccurrences(of: "\\\"", with: "\"")
        
        // 3. 清除所有残留的反斜杠
        cleanedText = cleanedText.replacingOccurrences(of: "\\", with: "")
        
        return cleanedText
    }
    
    func disconnect() {
        // cancel 会触发 receiveMessage 里的 .failure，错误代码为 URLError.cancelled
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil // 彻底释放对象
        print("🛑 WebSocket 已彻底关闭旧任务")
    }
}
