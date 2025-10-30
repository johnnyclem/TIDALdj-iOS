import Foundation

struct UserProfile: Equatable {
    let id: String
    let fullName: String
    let firstName: String?
    let lastName: String?
    let nickname: String?
    let email: String?
    let countryCode: String?

    var displayName: String {
        if let nickname = nickname, !nickname.isEmpty {
            return nickname
        }
        let components = [firstName, lastName].compactMap { component -> String? in
            guard let trimmed = component?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
                return nil
            }
            return trimmed
        }
        if !components.isEmpty {
            return components.joined(separator: " ")
        }
        if !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fullName
        }
        return id
    }
}
