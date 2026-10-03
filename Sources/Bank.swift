import SwiftUI
import UserNotifications

struct Holding: Codable, Identifiable {
    var symbol: String
    var quantity: Int
    var avg: Double
    var id: String { symbol }
}

struct Mouvement: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var label: String
    var amount: Double
    var symbol: String?
    var icone: String?
}

struct SaveData: Codable {
    var solde: Double
    var epargne: Double
    var positions: [Holding]
    var mouvements: [Mouvement]
    var gele: Bool
}

struct Quote: Decodable {
    let c: Double
    let dp: Double?
}

struct Profil: Decodable {
    let name: String?
    let logo: String?
}

struct Resultat: Decodable, Identifiable {
    let description: String
    let symbol: String
    let type: String?
    var id: String { symbol }
}

struct Recherche: Decodable {
    let result: [Resultat]
}

struct TauxChange: Decodable {
    let rates: [String: Double]
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

func eur(_ v: Double) -> String {
    v.formatted(.currency(code: "EUR").locale(Locale(identifier: "fr_FR")))
}

@MainActor
final class Bank: ObservableObject {
    @Published var solde: Double = 10000
    @Published var epargne: Double = 0
    @Published var positions: [Holding] = []
    @Published var mouvements: [Mouvement] = []
    @Published var gele = false
    @Published var prix: [String: Double] = [:]
    @Published var variations: [String: Double] = [:]
    @Published var logos: [String: String] = [:]
    @Published var noms: [String: String] = [:]

    private var taux = 0.86
    private var dernierTaux = Date.distantPast
    private var visibles: Set<String> = []
    private var enCours: Set<String> = []
    private var profilsCharges: Set<String> = []
    private let cle = "banque_v2"

    init() {
        if let data = UserDefaults.standard.data(forKey: cle),
           let s = try? JSONDecoder().decode(SaveData.self, from: data) {
            solde = s.solde
            epargne = s.epargne
            positions = s.positions
            mouvements = s.mouvements
            gele = s.gele
        }
    }

    private func sauver() {
        let s = SaveData(solde: solde, epargne: epargne, positions: positions, mouvements: mouvements, gele: gele)
        if let data = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(data, forKey: cle)
        }
    }

    private func ajouterMouvement(_ label: String, _ montant: Double, symbol: String? = nil, icone: String? = nil) {
        mouvements.insert(Mouvement(label: label, amount: montant, symbol: symbol, icone: icone), at: 0)
        sauver()
    }

    // MARK: - Infos

    func nom(_ s: String) -> String {
        marques.first(where: { $0.symbol == s })?.nom ?? noms[s] ?? s
    }

    func quantite(_ s: String) -> Int {
        positions.first(where: { $0.symbol == s })?.quantity ?? 0
    }

    var valeurPortefeuille: Double {
        positions.reduce(0) { $0 + Double($1.quantity) * (prix[$1.symbol] ?? $1.avg) }
    }

    func gainPct(_ p: Holding) -> Double {
        guard p.avg > 0 else { return 0 }
        let actuel = prix[p.symbol] ?? p.avg
        return (actuel - p.avg) / p.avg * 100
    }

    // MARK: - Données en direct

    func vu(_ s: String) {
        visibles.insert(s)
        if prix[s] == nil {
            Task { await chargerPrix(s) }
        }
    }

    func plusVu(_ s: String) {
        visibles.remove(s)
    }

    func majTaux() async {
        guard Date().timeIntervalSince(dernierTaux) > 3600 else { return }
        dernierTaux = Date()
        guard let url = URL(string: "https://api.frankfurter.dev/v1/latest?base=USD&symbols=EUR") else { return }
        if let (data, _) = try? await URLSession.shared.data(from: url),
           let r = try? JSONDecoder().decode(TauxChange.self, from: data),
           let e = r.rates["EUR"] {
            taux = e
        }
    }

    func chargerPrix(_ s: String) async {
        guard !enCours.contains(s) else { return }
        enCours.insert(s)
        defer { enCours.remove(s) }
        await majTaux()
        guard let url = URL(string: "https://finnhub.io/api/v1/quote?symbol=\(s)&token=\(finnhubKey)") else { return }
        if let (data, _) = try? await URLSession.shared.data(from: url),
           let q = try? JSONDecoder().decode(Quote.self, from: data),
           q.c > 0 {
            prix[s] = q.c * taux
            variations[s] = q.dp ?? 0
        }
    }

    func chargerProfil(_ s: String) async {
        guard marques.first(where: { $0.symbol == s }) == nil,
              !profilsCharges.contains(s),
              let url = URL(string: "https://finnhub.io/api/v1/stock/profile2?symbol=\(s)&token=\(finnhubKey)") else { return }
        profilsCharges.insert(s)
        if let (data, _) = try? await URLSession.shared.data(from: url),
           let p = try? JSONDecoder().decode(Profil.self, from: data) {
            if let l = p.logo, !l.isEmpty { logos[s] = l }
            if let n = p.name, !n.isEmpty { noms[s] = n }
        }
    }

    func refresh() async {
        await majTaux()
        var liste = visibles
        for p in positions { liste.insert(p.symbol) }
        for s in liste {
            await chargerPrix(s)
            await chargerProfil(s)
        }
    }

    func chercher(_ q: String) async -> [Resultat] {
        let texte = q.trimmingCharacters(in: .whitespaces)
        guard texte.count >= 2,
              let enc = texte.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://finnhub.io/api/v1/search?q=\(enc)&token=\(finnhubKey)") else { return [] }
        if let (data, _) = try? await URLSession.shared.data(from: url),
           let r = try? JSONDecoder().decode(Recherche.self, from: data) {
            let filtres = r.result.filter {
                !$0.symbol.contains(".") && !$0.symbol.contains(":") && ($0.type ?? "") == "Common Stock"
            }
            let limites = Array(filtres.prefix(15))
            for x in limites { noms[x.symbol] = x.description.capitalized }
            return limites
        }
        return []
    }

    // MARK: - Actions

    func acheter(_ s: String, qty: Int) -> String {
        if gele { return "Carte gelée ❄️ Dégèle-la dans l'onglet Carte." }
        guard let p = prix[s] else { return "Prix indisponible pour le moment." }
        let cout = p * Double(qty)
        guard cout <= solde else { return "Solde insuffisant sur ton compte principal." }
        solde -= cout
        if let i = positions.firstIndex(where: { $0.symbol == s }) {
            let ancienne = positions[i]
            let total = ancienne.quantity + qty
            positions[i].avg = (ancienne.avg * Double(ancienne.quantity) + cout) / Double(total)
            positions[i].quantity = total
        } else {
            positions.append(Holding(symbol: s, quantity: qty, avg: p))
        }
        ajouterMouvement("Achat \(qty) × \(nom(s))", -cout, symbol: s)
        notifier(titre: "Paiement par carte", texte: "Achat de \(qty) × \(nom(s)) (\(s)) pour \(eur(cout))")
        return "Achat effectué ✅"
    }

    func vendre(_ s: String, qty: Int) -> String {
        guard let p = prix[s] else { return "Prix indisponible pour le moment." }
        guard let i = positions.firstIndex(where: { $0.symbol == s }), positions[i].quantity >= qty else {
            return "Tu n'as pas assez d'actions à vendre."
        }
        let gain = p * Double(qty)
        solde += gain
        positions[i].quantity -= qty
        if positions[i].quantity == 0 { positions.remove(at: i) }
        ajouterMouvement("Vente \(qty) × \(nom(s))", gain, symbol: s)
        notifier(titre: "Vente réalisée", texte: "Vente de \(qty) × \(nom(s)) (\(s)) pour \(eur(gain))")
        return "Vente effectuée ✅"
    }

    func ajouter(_ montant: Double) -> String {
        solde += montant
        ajouterMouvement("Ajout d'argent", montant, icone: "plus")
        notifier(titre: "Argent reçu", texte: "+\(eur(montant)) sur ton compte principal")
        return "\(eur(montant)) ajoutés ✅"
    }

    func envoyer(a contact: String, montant: Double) -> String {
        guard montant <= solde else { return "Solde insuffisant." }
        solde -= montant
        ajouterMouvement("Virement à \(contact)", -montant, icone: "paperplane.fill")
        notifier(titre: "Virement envoyé", texte: "Tu as envoyé \(eur(montant)) à \(contact).")
        return "Virement envoyé ✅"
    }

    func demander(a contact: String, montant: Double) -> String {
        Task {
            try? await Task.sleep(nanoseconds: 6_000_000_000)
            solde += montant
            ajouterMouvement("\(contact) t'a envoyé de l'argent", montant, icone: "arrow.down.left")
            notifier(titre: "Demande acceptée", texte: "\(contact) t'a envoyé \(eur(montant)).")
        }
        return "Demande envoyée à \(contact) ⏳ Réponse dans quelques secondes…"
    }

    func deplacer(versEpargne: Bool, montant: Double) -> String {
        if versEpargne {
            guard montant <= solde else { return "Solde insuffisant." }
            solde -= montant
            epargne += montant
            ajouterMouvement("Vers Épargne", -montant, icone: "arrow.left.arrow.right")
            notifier(titre: "Virement interne", texte: "\(eur(montant)) déplacés vers ton épargne.")
        } else {
            guard montant <= epargne else { return "Épargne insuffisante." }
            epargne -= montant
            solde += montant
            ajouterMouvement("Depuis Épargne", montant, icone: "arrow.left.arrow.right")
            notifier(titre: "Virement interne", texte: "\(eur(montant)) déplacés vers ton compte principal.")
        }
        return "Virement effectué ✅"
    }

    func interets() -> String {
        let gain = epargne * 0.03 / 12
        guard gain >= 0.01 else { return "Dépose d'abord de l'argent sur ton épargne." }
        epargne += gain
        ajouterMouvement("Intérêts d'épargne", gain, icone: "percent")
        notifier(titre: "Intérêts reçus", texte: "+\(eur(gain)) d'intérêts sur ton épargne.")
        return "+\(eur(gain)) d'intérêts ✅"
    }

    func definirGel(_ valeur: Bool) {
        gele = valeur
        sauver()
        notifier(titre: valeur ? "Carte gelée" : "Carte dégelée",
                 texte: valeur ? "Les paiements sont bloqués." : "Les paiements sont de nouveau possibles.")
    }

    func reinitialiser() {
        solde = 10000
        epargne = 0
        positions = []
        mouvements = []
        gele = false
        sauver()
    }
}