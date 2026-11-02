import SwiftUI
import SwiftData

@main
struct DosenjaegerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
        .modelContainer(for: [Flavor.self, CanItem.self])
    }
}

struct RootView: View {
    enum Tab: Hashable { case collection, countries, missing }

    @Environment(\.modelContext) private var context
    @State private var tab: Tab = .collection

    init() {
        let tabBar = UITabBarAppearance()
        tabBar.configureWithOpaqueBackground()
        tabBar.backgroundColor = .black
        UITabBar.appearance().standardAppearance = tabBar
        UITabBar.appearance().scrollEdgeAppearance = tabBar

        let navBar = UINavigationBarAppearance()
        navBar.configureWithTransparentBackground()
        navBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navBar
        UINavigationBar.appearance().scrollEdgeAppearance = navBar
    }

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { CollectionView() }
                .tabItem { Label("Sammlung", systemImage: "square.grid.2x2") }
                .tag(Tab.collection)

            NavigationStack { CountriesView() }
                .tabItem { Label("Länder", systemImage: "globe") }
                .tag(Tab.countries)

            NavigationStack { MissingView() }
                .tabItem { Label("Fehlend", systemImage: "checklist") }
                .tag(Tab.missing)
        }
        .task { await Catalog.seed(into: context) }
    }
}

/// Gemeinsame Navigationsziele aller Tabs.
struct AppDestinations: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: Flavor.self) { flavor in
                FlavorDetailView(flavor: flavor)
            }
            .navigationDestination(for: TradeRoute.self) { _ in
                TradeView()
            }
    }
}

struct TradeRoute: Hashable {}

extension View {
    func appDestinations() -> some View { modifier(AppDestinations()) }
}
