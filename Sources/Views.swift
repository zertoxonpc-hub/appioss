import SwiftUI

let violet = Color(red: 0.25, green: 0.18, blue: 0.5)

struct LockView: View {
    @EnvironmentObject var auth: Auth

    var body: some View {
        ZStack {
            LinearGradient(colors: [violet, .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "faceid")
                    .font(.system(size: 70))
                    .foregroundColor(.white)
                Text("Banque verrouillée")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
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

struct MainView: View {
    @EnvironmentObject var bank: Bank

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Accueil", systemImage: "house.fill") }
            MarketView()
                .tabItem { Label("Actions", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .task {
            while !Task.isCancelled {
                await bank.refresh()
                try? await Task.sleep(nanoseconds: 15_000_000_000)
            }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var bank: Bank

    var body: some View {
        ZStack {
            LinearGradient(colors: [violet, Color(red: 0.1, green: 0.07, blue: 0.25)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    Text("Compte principal")
                        .foregroundColor(Color.white.opacity(0.8))
                        .padding(.top, 40)
                    Text(money(bank.cash))
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                    Text("Portefeuille : \(money(bank.portfolioValue))")
                        .foregroundColor(Color.white.opacity(0.8))

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Opérations").font(.headline)
                        if bank.operations.isEmpty {
                            Text("Aucune opération pour l'instant")
                                .foregroundColor(.gray)
                        }
                        ForEach(bank.operations.prefix(15)) { op in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(op.label).bold()
                                    Text(op.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Text(money(op.amount))
                                    .foregroundColor(op.amount < 0 ? .black : .green)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(white: 0.95))
                    .foregroundColor(.black)
                    .cornerRadius(22)
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct Pick: Identifiable {
    let symbol: String
    var id: String { symbol }
}

struct MarketView: View {
    @EnvironmentObject var bank: Bank
    @State private var selected: String?

    var body: some View {
        NavigationView {
            List(symbols, id: \.self) { s in
                Button { selected = s } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(s).bold()
                            Text("Possédées : \(bank.quantity(of: s))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(bank.prices[s].map { money($0) } ?? "…").bold()
                            Text(String(format: "%+.2f %%", bank.changes[s] ?? 0))
                                .font(.caption)
                                .foregroundColor((bank.changes[s] ?? 0) >= 0 ? .green : .red)
                        }
                    }
                }
            }
            .navigationTitle("Actions")
            .sheet(item: Binding(get: { selected.map { Pick(symbol: $0) } },
                                 set: { selected = $0?.symbol })) { p in
                TradeView(symbol: p.symbol)
            }
        }
    }
}

struct TradeView: View {
    let symbol: String
    @EnvironmentObject var bank: Bank
    @Environment(\.dismiss) private var dismiss
    @State private var qty = 1
    @State private var message = ""

    var body: some View {
        VStack(spacing: 20) {
            Text(symbol).font(.largeTitle).bold()
            Text(bank.prices[symbol].map { money($0) } ?? "Prix indisponible")
                .font(.title)
            Stepper("Quantité : \(qty)", value: $qty, in: 1...1000)
                .padding(.horizontal)
            Text("Total : \(money((bank.prices[symbol] ?? 0) * Double(qty)))")
            HStack(spacing: 16) {
                Button("Acheter") {
                    message = bank.buy(symbol, qty: qty) ? "Achat effectué ✅" : "Fonds insuffisants ou prix indisponible"
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                Button("Vendre") {
                    message = bank.sell(symbol, qty: qty) ? "Vente effectuée ✅" : "Tu n'en as pas assez"
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            Text(message).foregroundColor(.gray)
            Button("Fermer") { dismiss() }
        }
        .padding()
    }
}