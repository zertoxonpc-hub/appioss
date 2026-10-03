import SwiftUI
import UserNotifications

struct Holding: Codable, Identifiable {
    var symbol: String
    var quantity: Int
    var id: String { symbol }
}

struct Operation: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var label: String
    var amount: Double
}

struct SaveData: Codable {
    var cash: Double
    var holdings: [Holding]
    var operations: [Operation]
}

struct Quote: Decodable {
    let c: Double
    let dp: Double?
}

func notifier(titre: String, texte: String) {
    let contenu = UNMutableNotificationContent()
    contenu.title = titre
    contenu.body = texte
    contenu.sound = .default
    let declencheur = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
    let requete = UNNotificationRequest(identifier: UUID().uuidString, content: contenu, trigger: declencheur)
    UNUserNotificationCenter.current().add(requete)
}

func money(_ v: Double) -> String {
    v.formatted(.currency(code: "USD"))
}

@MainActor
final class Bank: ObservableObject {
    @Published var cash: Double = 10000
    @Published var holdings: [Holding] = []
    @Published var operations: [Operation] = []
    @Published var prices: [String: Double] = [:]
    @Published var changes: [String: Double] = [:]

    private let key = "banque_fictive"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let s = try? JSONDecoder().decode(SaveData.self, from: data) {
            cash = s.cash
            holdings = s.holdings
            operations = s.operations
        }
    }

    private func save() {
        let s = SaveData(cash: cash, holdings: holdings, operations: operations)
        if let data = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    var portfolioValue: Double {
        holdings.reduce(0) { $0 + Double($1.quantity) * (prices[$1.symbol] ?? 0) }
    }

    func quantity(of symbol: String) -> Int {
        holdings.first(where: { $0.symbol == symbol })?.quantity ?? 0
    }

    func refresh() async {
        for s in symbols {
            guard let url = URL(string: "https://finnhub.io/api/v1/quote?symbol=\(s)&token=\(finnhubKey)") else { continue }
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let q = try? JSONDecoder().decode(Quote.self, from: data),
               q.c > 0 {
                prices[s] = q.c
                changes[s] = q.dp ?? 0
            }
        }
    }

    @discardableResult
    func buy(_ symbol: String, qty: Int) -> Bool {
        guard let price = prices[symbol] else { return false }
        let cost = price * Double(qty)
        guard cost <= cash else { return false }
        cash -= cost
        if let i = holdings.firstIndex(where: { $0.symbol == symbol }) {
            holdings[i].quantity += qty
        } else {
            holdings.append(Holding(symbol: symbol, quantity: qty))
        }
        operations.insert(Operation(label: "Achat \(qty) × \(symbol)", amount: -cost), at: 0)
        save()
        notifier(titre: "Paiement", texte: "Achat de \(qty) × \(symbol) : \(money(cost))")
        return true
    }

    @discardableResult
    func sell(_ symbol: String, qty: Int) -> Bool {
        guard let price = prices[symbol],
              let i = holdings.firstIndex(where: { $0.symbol == symbol }),
              holdings[i].quantity >= qty else { return false }
        let gain = price * Double(qty)
        cash += gain
        holdings[i].quantity -= qty
        if holdings[i].quantity == 0 { holdings.remove(at: i) }
        operations.insert(Operation(label: "Vente \(qty) × \(symbol)", amount: gain), at: 0)
        save()
        notifier(titre: "Vente", texte: "Vente de \(qty) × \(symbol) : \(money(gain))")
        return true
    }
}