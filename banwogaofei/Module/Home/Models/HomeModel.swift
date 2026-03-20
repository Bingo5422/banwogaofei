import Foundation

struct User: Identifiable, Codable {
    let id: String
    let name: String
    let role: String
    let avatarName: String
}

struct functionItem: Identifiable, Codable {
    let id: String
    let title: String
    let iconName: String
    
}
