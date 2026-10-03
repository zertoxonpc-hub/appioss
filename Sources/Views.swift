import SwiftUI

// MARK: - Thèmes et petits outils

struct Theme {
    let nom: String
    let haut: Color
    let bas: Color
}

let themes: [Theme] = [
    Theme(nom: "Violet", haut: Color(red: 0.45, green: 0.33, blue: 0.85), bas: Color(red: 0.10, green: 0.07, blue: 0.28)),
    Theme(nom: "Océan", haut: Color(red: 0.20, green: 0.55, blue: 0.95), bas: Color(red: 0.03, green: 0.10, blue: 0.30)),
    Theme(nom: "Forêt", haut: Color(red: 0.20, green: 0.70, blue: 0.45), bas: Color(red: 0.02, green: 0.16, blue: 0.10)),
    Theme(nom: "Coucher de soleil", haut: Color(red: 0.98, green: 0.45, blue: 0.40), bas: Color(red: 0.30, green: 0.08, blue: 0.30)),
    Theme(nom: "Nuit", haut: Color(red: 0.30, green: 0.30, blue: 0.35), bas: Color.black)
]

func nombreFr(_ n: Int) -> String {
    let f = NumberFormatter()
    f.numberStyle = .decimal
    f.locale = Locale(identifier: "fr_FR")
    return f.string(from: NSNumber(value: n)) ?? String(n)
}

func dateFr(_ d: Date) -> String {
    let f = DateFormatter()
    f.locale = Locale(identifier: "fr_FR")
    f.dateFormat = "d MMMM, HH:mm"
    return f.string(from: d)
}

extension View {
    func carteBlanche() -> some View {
        self.padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(white: 0.96))
            .cornerRadius(24)
            .padding(.horizontal)
    }
}

struct FondView: View {
    @AppStorage("theme") private var themeIndex = 0

    var theme: Theme {
        themes[min(max(themeIndex, 0), themes.count - 1)]
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [theme.haut, theme.bas], startPoint: .top, endPoint: .bottom)
            Circle()
                .fill(Color.white.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: -90, y: -120)
            Circle()
                .fill(theme.haut.opacity(0.5))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: 120, y: 60)
        }
        .ignoresSafeArea()
    }
}

struct SoldeView: View {
    let valeur: Double
    var taille: CGFloat = 64

    var cents: Int {
        Int((abs(valeur) * 100).rounded())
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text((valeur < 0 ? "-" : "") + nombreFr(cents / 100))
                .font(.system(size: taille, weight: .bold))
            Text(String(format: ",%02ld €", cents % 100))
                .font(.system(size: taille * 0.45, weight: .bold))
                .opacity(0.65)
        }
        .foregroundColor(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
}

struct Variation: View {
    let pct: Double

    var texte: String {
        ((pct >= 0 ? "+" : "") + String(format: "%.2f", pct) + " %")
            .replacingOccurrences(of: ".", with: ",")
    }

    var body: some View {
        Text(texte)
            .font(.caption)
            .bold()
            .foregroundColor(pct >= 0 ? .green : .red)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background((pct >= 0 ? Color.green : Color.red).opacity(0.15))
            .clipShape(Capsule())
    }
}

struct LogoView: View {
    let symbol: String
    var taille: CGFloat = 40
    @EnvironmentObject var bank: Bank

    var urlLogo: URL? {
        if let m = marques.first(where: { $0.symbol == symbol }) {
            return URL(string: "https://www.google.com/s2/favicons?domain=\(m.domaine)&sz=128")
        }
        if let l = bank.logos[symbol] {
            return URL(string: l)
        }
        return nil
    }

    var initiale: some View {
        ZStack {
            Color.gray.opacity(0.25)
            Text(String(symbol.prefix(1)))
                .bold()
                .foregroundColor(.gray)
        }
    }

    var body: some View {
        Group {
            if let url = urlLogo {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(taille * 0.12)
                    } else {
                        initiale
                    }
                }
            } else {
                initiale
            }
        }
        .frame(width: taille, height: taille)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
    }
}

struct BoutonRond: View {
    let icone: String
    let titre: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icone)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 58, height: 58)
                    .background(Color.white.opacity(0.25))
                    .clipShape(Circle())
                Text(titre)
                    .font(.caption)
                    .bold()
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Écran verrouillé

struct LockView: View {
    @EnvironmentObject var auth: Auth

    var body: some View {
        ZStack {
            FondView()
            VStack(spacing: 24) {
                Image(systemName: "faceid")
                    .font(.system(size: 70))
                    .foregroundColor(.white)
                Text("Banque verrouillée")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                Text("Utilise Face ID pour continuer")
                    .foregroundColor(Color.white.opacity(0.8))
                Button("Déverrouiller") { auth.authenticate() }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(14)
            }
        }
    }
}

// MARK: - Structure principale

struct MainView: View {
    @EnvironmentObject var bank: Bank
    @State private var onglet = 0

    var body: some View {
        TabView(selection: $onglet) {
            HomeView(onglet: $onglet)
                .tabItem { Label("Accueil", systemImage: "house.fill") }
                .tag(0)
            MarketView()
                .tabItem { Label("Investir", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(1)
            CarteView()
                .tabItem { Label("Carte", systemImage: "creditcard.fill") }
                .tag(2)
            EpargneView()
                .tabItem { Label("Épargne", systemImage: "eurosign.circle.fill") }
                .tag(3)
        }
        .accentColor(.purple)
        .task {
            while !Task.isCancelled {
                await bank.refresh()
                try? await Task.sleep(nanoseconds: 20_000_000_000)
            }
        }
    }
}

// MARK: - Accueil

enum Feuille: Identifiable {
    case ajouter, envoyer, demander, virement, perso, profil
    case action(String)

    var id: String {
        switch self {
        case .ajouter: return "ajouter"
        case .envoyer: return "envoyer"
        case .demander: return "demander"
        case .virement: return "virement"
        case .perso: return "perso"
        case .profil: return "profil"
        case .action(let s): return "action-" + s
        }
    }
}

struct HomeView: View {
    @Binding var onglet: Int
    @EnvironmentObject var bank: Bank
    @AppStorage("nom") private var nom = "Moi"
    @State private var feuille: Feuille?
    @State private var toutAfficher = false

    var initiales: String {
        String(nom.prefix(2)).uppercased()
    }

    var body: some View {
        ZStack {
            FondView()
            ScrollView {
                VStack(spacing: 22) {
                    barreHaut
                    VStack(spacing: 6) {
                        Text("Compte principal")
                            .font(.title3)
                            .foregroundColor(Color.white.opacity(0.85))
                        SoldeView(valeur: bank.solde)
                    }
                    .padding(.top, 30)
                    boutonsActions
                    if !bank.positions.isEmpty {
                        carteInvestissements
                    }
                    carteMouvements
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(item: $feuille) { f in
            contenuFeuille(f)
        }
    }

    @ViewBuilder
    func contenuFeuille(_ f: Feuille) -> some View {
        switch f {
        case .ajouter:
            FormulaireMontant(titre: "Ajouter de l'argent", bouton: "Ajouter", choixTitre: nil, choix: []) { _, m in
                bank.ajouter(m)
            }
        case .envoyer:
            FormulaireMontant(titre: "Envoyer", bouton: "Envoyer", choixTitre: "Destinataire", choix: contacts) { c, m in
                bank.envoyer(a: c, montant: m)
            }
        case .demander:
            FormulaireMontant(titre: "Demander", bouton: "Envoyer la demande", choixTitre: "À qui ?", choix: contacts) { c, m in
                bank.demander(a: c, montant: m)
            }
        case .virement:
            FormulaireMontant(titre: "Entre mes comptes", bouton: "Valider le virement", choixTitre: "Sens du virement",
                              choix: ["Compte principal → Épargne", "Épargne → Compte principal"]) { c, m in
                bank.deplacer(versEpargne: c.hasPrefix("Compte"), montant: m)
            }
        case .perso:
            PersonnaliserView()
        case .profil:
            ProfilView()
        case .action(let s):
            TradeView(symbol: s)
        }
    }

    var barreHaut: some View {
        HStack(spacing: 12) {
            Button { feuille = .profil } label: {
                Text(initiales)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(Color.white.opacity(0.25))
                    .clipShape(Circle())
            }
            Button { onglet = 1 } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Rechercher")
                    Spacer()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(Color.white.opacity(0.25))
                .clipShape(Capsule())
            }
            Button { onglet = 2 } label: {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(Color.white.opacity(0.25))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    var boutonsActions: some View {
        HStack(alignment: .top, spacing: 4) {
            BoutonRond(icone: "plus", titre: "Ajouter") { feuille = .ajouter }
            BoutonRond(icone: "arrow.right", titre: "Envoyer") { feuille = .envoyer }
            BoutonRond(icone: "arrow.left", titre: "Demander") { feuille = .demander }
            BoutonRond(icone: "arrow.left.arrow.right", titre: "Virement") { feuille = .virement }
            BoutonRond(icone: "paintpalette.fill", titre: "Style") { feuille = .perso }
        }
        .padding(.horizontal, 8)
    }

    var carteInvestissements: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Investissements").font(.headline)
                Spacer()
                Text(eur(bank.valeurPortefeuille)).bold()
            }
            ForEach(bank.positions) { p in
                Button { feuille = .action(p.symbol) } label: {
                    HStack(spacing: 12) {
                        LogoView(symbol: p.symbol, taille: 42)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bank.nom(p.symbol)).bold()
                            Text("\(p.quantity) action(s)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(eur(Double(p.quantity) * (bank.prix[p.symbol] ?? p.avg))).bold()
                            Variation(pct: bank.gainPct(p))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundColor(.black)
        .carteBlanche()
    }

    var carteMouvements: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Opérations").font(.headline)
            if bank.mouvements.isEmpty {
                Text("Aucune opération pour l'instant")
                    .foregroundColor(.gray)
            }
            ForEach(bank.mouvements.prefix(toutAfficher ? 100 : 6)) { m in
                LigneMouvement(m: m)
            }
            if bank.mouvements.count > 6 {
                Button(toutAfficher ? "Réduire" : "Tout afficher") {
                    toutAfficher.toggle()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .foregroundColor(.black)
        .carteBlanche()
    }
}

struct LigneMouvement: View {
    let m: Mouvement

    var body: some View {
        HStack(spacing: 12) {
            if let s = m.symbol {
                LogoView(symbol: s, taille: 42)
            } else {
                Image(systemName: m.icone ?? "creditcard.fill")
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.purple)
                    .clipShape(Circle())
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(m.label).bold()
                Text(dateFr(m.date))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text((m.amount > 0 ? "+" : "") + eur(m.amount))
                .bold()
                .foregroundColor(m.amount > 0 ? .green : .black)
        }
    }
}

// MARK: - Formulaire générique (ajouter, envoyer, demander, virement)

struct FormulaireMontant: View {
    let titre: String
    let bouton: String
    let choixTitre: String?
    let choix: [String]
    let action: (String, Double) -> String

    @Environment(\.dismiss) private var dismiss
    @State private var texte = ""
    @State private var selection = 0
    @State private var message = ""

    var montant: Double {
        Double(texte.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var body: some View {
        NavigationView {
            Form {
                if !choix.isEmpty {
                    Section(header: Text(choixTitre ?? "")) {
                        Picker("", selection: $selection) {
                            ForEach(0..<choix.count, id: \.self) { i in
                                Text(choix[i]).tag(i)
                            }
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()
                    }
                }
                Section(header: Text("Montant en euros")) {
                    TextField("0,00", text: $texte)
                        .keyboardType(.decimalPad)
                }
                if !message.isEmpty {
                    Section { Text(message) }
                }
                Section {
                    Button(bouton) {
                        if montant <= 0 {
                            message = "Entre un montant valide."
                        } else {
                            message = action(choix.isEmpty ? "" : choix[selection], montant)
                        }
                    }
                }
            }
            .navigationTitle(titre)
            .navigationBarItems(trailing: Button("Fermer") { dismiss() })
        }
    }
}

// MARK: - Investir

struct Pick: Identifiable {
    let symbol: String
    var id: String { symbol }
}

struct MarketView: View {
    @EnvironmentObject var bank: Bank
    @State private var recherche = ""
    @State private var resultats: [Resultat] = []
    @State private var choix: Pick?

    var locales: [Marque] {
        marques.filter {
            recherche.isEmpty
            || $0.nom.localizedCaseInsensitiveContains(recherche)
            || $0.symbol.localizedCaseInsensitiveContains(recherche)
        }
    }

    var autres: [Resultat] {
        resultats.filter { r in
            !marques.contains(where: { $0.symbol == r.symbol })
        }
    }

    var body: some View {
        NavigationView {
            List {
                Section(header: Text(recherche.isEmpty ? "Marques populaires" : "Marques")) {
                    ForEach(locales) { m in
                        Button { choix = Pick(symbol: m.symbol) } label: {
                            LigneAction(symbol: m.symbol)
                        }
                        .buttonStyle(.plain)
                    }
                }
                if !autres.isEmpty {
                    Section(header: Text("Autres résultats")) {
                        ForEach(autres) { r in
                            Button { choix = Pick(symbol: r.symbol) } label: {
                                LigneAction(symbol: r.symbol)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Investir")
            .searchable(text: $recherche, prompt: "Rechercher une marque ou un symbole")
            .task(id: recherche) {
                try? await Task.sleep(nanoseconds: 600_000_000)
                if Task.isCancelled { return }
                if recherche.count >= 2 {
                    resultats = await bank.chercher(recherche)
                } else {
                    resultats = []
                }
            }
            .sheet(item: $choix) { p in
                TradeView(symbol: p.symbol)
            }
        }
    }
}

struct LigneAction: View {
    let symbol: String
    @EnvironmentObject var bank: Bank

    var possede: String {
        let q = bank.quantite(symbol)
        return q > 0 ? "\(symbol) · \(q) possédée(s)" : symbol
    }

    var body: some View {
        HStack(spacing: 12) {
            LogoView(symbol: symbol, taille: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(bank.nom(symbol)).bold()
                Text(possede)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(bank.prix[symbol].map { eur($0) } ?? "…").bold()
                if bank.prix[symbol] != nil {
                    Variation(pct: bank.variations[symbol] ?? 0)
                }
            }
        }
        .contentShape(Rectangle())
        .onAppear { bank.vu(symbol) }
        .onDisappear { bank.plusVu(symbol) }
    }
}

struct TradeView: View {
    let symbol: String
    @EnvironmentObject var bank: Bank
    @Environment(\.dismiss) private var dismiss
    @State private var qty = 1
    @State private var message = ""

    var prixUnitaire: Double {
        bank.prix[symbol] ?? 0
    }

    var body: some View {
        ZStack {
            FondView()
            ScrollView {
                VStack(spacing: 18) {
                    HStack {
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(Color.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    LogoView(symbol: symbol, taille: 84)
                    Text(bank.nom(symbol))
                        .font(.title)
                        .bold()
                        .foregroundColor(.white)
                    Text(bank.prix[symbol].map { eur($0) } ?? "Prix indisponible")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.white)
                    if bank.prix[symbol] != nil {
                        Variation(pct: bank.variations[symbol] ?? 0)
                    }

                    VStack(spacing: 16) {
                        if bank.quantite(symbol) > 0 {
                            HStack {
                                Text("Tu possèdes")
                                Spacer()
                                Text("\(bank.quantite(symbol)) action(s)").bold()
                            }
                        }
                        Stepper("Quantité : \(qty)", value: $qty, in: 1...1000)
                        HStack {
                            Text("Total")
                            Spacer()
                            Text(eur(prixUnitaire * Double(qty))).bold()
                        }
                        HStack {
                            Text("Solde disponible")
                            Spacer()
                            Text(eur(bank.solde))
                        }
                        HStack(spacing: 12) {
                            Button {
                                message = bank.acheter(symbol, qty: qty)
                            } label: {
                                Text("Acheter")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                            }
                            Button {
                                message = bank.vendre(symbol, qty: qty)
                            } label: {
                                Text("Vendre")
                                    .bold()
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                            }
                        }
                        if !message.isEmpty {
                            Text(message)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .foregroundColor(.black)
                    .carteBlanche()
                }
                .padding(.bottom, 30)
            }
        }
        .task {
            bank.vu(symbol)
            await bank.chargerProfil(symbol)
        }
        .onDisappear { bank.plusVu(symbol) }
    }
}

// MARK: - Carte

struct CarteView: View {
    @EnvironmentObject var bank: Bank
    @AppStorage("nom") private var nom = "Moi"
    @State private var details = false
    @State private var enLigne = true
    @State private var retraits = true
    @State private var sansContact = true
    @State private var alerte = false

    var carte: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(colors: [Color(white: 0.18), Color.black],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("MA BANQUE")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "wave.3.right")
                        .foregroundColor(.white)
                }
                Spacer()
                Text(details ? "4242 4242 4242 4242" : "•••• •••• •••• 4242")
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                HStack {
                    Text(nom.uppercased())
                    Spacer()
                    Text(details ? "12/29 · 123" : "••/•• · •••")
                }
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.85))
            }
            .padding(22)
            if bank.gele {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.blue.opacity(0.45))
                Text("Carte gelée ❄️")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(height: 210)
        .padding(.horizontal)
    }

    func ligneToggle(_ titre: String, _ icone: String, _ binding: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icone).frame(width: 30)
            Text(titre)
            Spacer()
            Toggle("", isOn: binding).labelsHidden()
        }
        .padding()
    }

    func ligneBouton(_ titre: String, _ icone: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icone).frame(width: 30)
                Text(titre)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }

    var body: some View {
        ZStack {
            FondView()
            ScrollView {
                VStack(spacing: 22) {
                    Text("Ma carte")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    carte

                    VStack(spacing: 0) {
                        ligneToggle("Geler la carte", "snowflake",
                                    Binding(get: { bank.gele }, set: { bank.definirGel($0) }))
                        Divider()
                        ligneToggle("Afficher les détails", "eye.fill", $details)
                        Divider()
                        ligneToggle("Paiements en ligne", "globe", $enLigne)
                        Divider()
                        ligneToggle("Retraits aux distributeurs", "banknote", $retraits)
                        Divider()
                        ligneToggle("Paiement sans contact", "wave.3.right", $sansContact)
                    }
                    .foregroundColor(.black)
                    .background(Color(white: 0.96))
                    .cornerRadius(24)
                    .padding(.horizontal)

                    VStack(spacing: 0) {
                        ligneBouton("Ajouter à Apple Wallet", "wallet.pass.fill") { alerte = true }
                        Divider()
                        ligneBouton("Limites de dépenses", "gauge") { alerte = true }
                        Divider()
                        ligneBouton("Commander une carte physique", "creditcard") { alerte = true }
                        Divider()
                        ligneBouton("Signaler un problème", "exclamationmark.bubble.fill") { alerte = true }
                    }
                    .foregroundColor(.black)
                    .background(Color(white: 0.96))
                    .cornerRadius(24)
                    .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
        }
        .alert("Bientôt disponible", isPresented: $alerte) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Cette fonctionnalité n'est pas encore disponible dans cette banque fictive.")
        }
    }
}

// MARK: - Épargne

enum FeuilleEpargne: Identifiable {
    case deposer, retirer

    var id: Int {
        self == .deposer ? 0 : 1
    }
}

struct EpargneView: View {
    @EnvironmentObject var bank: Bank
    @State private var feuille: FeuilleEpargne?
    @State private var message = ""

    var body: some View {
        ZStack {
            FondView()
            ScrollView {
                VStack(spacing: 22) {
                    Text("Épargne")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    Text("Solde de l'épargne")
                        .foregroundColor(Color.white.opacity(0.85))
                    SoldeView(valeur: bank.epargne)
                    Text("Taux annuel : 3,00 % (simulé)")
                        .font(.subheadline)
                        .foregroundColor(Color.white.opacity(0.8))

                    HStack(alignment: .top, spacing: 4) {
                        BoutonRond(icone: "plus", titre: "Déposer") { feuille = .deposer }
                        BoutonRond(icone: "minus", titre: "Retirer") { feuille = .retirer }
                        BoutonRond(icone: "percent", titre: "Intérêts") { message = bank.interets() }
                    }
                    .padding(.horizontal, 30)

                    if !message.isEmpty {
                        Text(message)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(14)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Comment ça marche ?").font(.headline)
                        Text("Dépose de l'argent depuis ton compte principal. Le bouton Intérêts simule un mois d'intérêts à 3 % par an.")
                            .foregroundColor(.gray)
                    }
                    .foregroundColor(.black)
                    .carteBlanche()
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(item: $feuille) { f in
            if f == .deposer {
                FormulaireMontant(titre: "Déposer sur l'épargne", bouton: "Déposer", choixTitre: nil, choix: []) { _, m in
                    bank.deplacer(versEpargne: true, montant: m)
                }
            } else {
                FormulaireMontant(titre: "Retirer de l'épargne", bouton: "Retirer", choixTitre: nil, choix: []) { _, m in
                    bank.deplacer(versEpargne: false, montant: m)
                }
            }
        }
    }
}

// MARK: - Style et profil

struct PersonnaliserView: View {
    @AppStorage("theme") private var themeIndex = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(0..<themes.count, id: \.self) { i in
                    Button { themeIndex = i } label: {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(LinearGradient(colors: [themes[i].haut, themes[i].bas],
                                                     startPoint: .top, endPoint: .bottom))
                                .frame(width: 40, height: 40)
                            Text(themes[i].nom)
                            Spacer()
                            if themeIndex == i {
                                Image(systemName: "checkmark").foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Personnaliser")
            .navigationBarItems(trailing: Button("Fermer") { dismiss() })
        }
    }
}

struct ProfilView: View {
    @EnvironmentObject var bank: Bank
    @AppStorage("nom") private var nom = "Moi"
    @Environment(\.dismiss) private var dismiss
    @State private var confirmer = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Prénom")) {
                    TextField("Ton prénom", text: $nom)
                }
                Section(header: Text("Compte")) {
                    Button("Réinitialiser le compte") { confirmer = true }
                        .foregroundColor(.red)
                }
                Section(header: Text("À propos")) {
                    Text("Banque fictive pour s'entraîner : aucun argent réel. Les prix des actions viennent de Finnhub.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("Profil")
            .navigationBarItems(trailing: Button("Fermer") { dismiss() })
            .alert("Réinitialiser le compte ?", isPresented: $confirmer) {
                Button("Réinitialiser", role: .destructive) { bank.reinitialiser() }
                Button("Annuler", role: .cancel) {}
            } message: {
                Text("Ton solde repartira à 10 000 € et l'historique sera effacé.")
            }
        }
    }
}