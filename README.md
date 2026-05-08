# BigTechNavigator

## In a nutshell

- Each feature **declares** its route key in its Interface module.
- Each feature **registers** its handler in its Implementation module.
- The composition root **wires** handlers at startup — one line per feature.
- No feature knows about any other feature's implementation.

---

## Architecture Overview

```
Feature Module                     BigTechNavigator                    Composition Root
─────────────────                  ────────────────                    ─────────────────

 ┌──────────────┐                                                     ┌──────────────┐
 │FeatureAInter-│  declares    ┌───────────┐   resolves view          │  App Startup │
 │face          │─────────────>│ RouteKey  │<──────────────────────── │              │
 │ FeatureAKey  │              └───────────┘                          │  registers   │
 └──────────────┘                    │                                │  handlers    │
                                     │                                └──────┬───────┘
 ┌──────────────┐                    ▼                                       │
 │FeatureA      │  implements  ┌─────────────┐      ┌──────────────┐         │
 │(impl)        │─────────────>│RouteHandler │──────│RouteRegistry │< ───────┘
 │ FeatureARoute│              └─────────────┘      └──────┬───────┘
 │   Handler    │                                          │
 └──────────────┘                                          │
                                                           ▼
 ┌──────────────┐              ┌───────────┐      ┌───────────────────────┐
 │FeatureB      │──navigate──> │ Navigator │──────│RoutingCoordinatorView │
 │(any feature) │  (to: Key)   └───────────┘      └───────────────────────┘
 └──────────────┘
```

**Data flow:**
1. Feature calls `router.navigate(to: ChatRouteKey.self)`.
2. `Navigator` creates a `ResolvedRoute` and appends it to `path` (or sets `presentingSheet`).
3. `RoutingCoordinatorView` observes the change, asks `RouteRegistry` for the view.
4. `RouteRegistry` calls the registered `RouteHandler`, which returns the concrete view.

---

## Concepts & Types

### `RouteKey` (protocol)

Declared in **Interface modules**. A compile-time identifier for a navigation destination.

```swift
// ChatInterface/ChatRouteKey.swift
public enum ChatRouteKey: RouteKey {
    public typealias Parameter = Void   // no data needed
    public static let id = "chat"
}
```

```swift
// MealDetailsInterface/MealDetailsRouteKey.swift
public enum MealDetailsRouteKey: RouteKey {
    public typealias Parameter = FoodEntry  // needs a FoodEntry to display
    public static let id = "mealDetails"
}
```

**Why an enum with no cases?** It's a pure namespace — you never instantiate it. The `Parameter` associated type gives compile-time safety: if you try to navigate to `MealDetailsRouteKey` without passing a `FoodEntry`, it won't compile.

### `RouteHandler` (protocol)

Implemented in **Implementation modules**. A factory that produces the view for a given `RouteKey`.

```swift
// Chat/ChatRouteHandler.swift
struct ChatRouteHandler: RouteHandler {
    typealias Key = ChatRouteKey
    let dependencies: ChatDependenciesContainer

    func destination(for parameter: Void) -> some View {
        ChatCoordinatorView(dependenciesContainer: dependencies)
    }
}
```

### `RouteRegistry` (class)

The "phone book." Maps route key IDs to type-erased view factories.

```swift
let registry = RouteRegistry()
registry.register(ChatRouteHandler(dependencies: chatDeps))
```

Internally stores `[String: (Any) -> AnyView]`. The `AnyView` is an implementation detail of the registry — **features never see it**. The `RoutingCoordinatorView` consumes it.

### `Navigator` (class)

The navigation API that features interact with. Injected via SwiftUI `@Environment` or we can inject it into our Store's Environment or into ViewModel (depending on the arch you choose).

```swift
@Environment(Navigator.self) private var navigator

// Navigate to a Void-parameter route:
navigator.navigate(to: ChatRouteKey.self)

// Navigate with a parameter:
navigator.navigate(to: MealDetailsRouteKey.self, parameter: foodEntry)

// Present as sheet:
navigator.navigate(to: PaywallRouteKey.self, style: .sheet)

// Programmatic back:
navigator.pop()
navigator.dismiss()
```

### `RoutingCoordinatorView` (struct)

The SwiftUI integration point.

```swift
RoutingCoordinatorView(navigator: navigator, registry: registry) {
    DailyLogView(store: ...)
}
```

It:
- Binds `navigator.path` to `NavigationStack(path:)`.
- Binds `navigator.presentingSheet` to `.sheet(item:)`.
- Resolves each `ResolvedRoute` via `registry.resolve(_:)`.
- Injects `navigator` and `registry` into the environment.

### `ResolvedRoute` (struct)

An internal type that pairs a route key ID with its type-erased parameter. You rarely interact with this directly — `Navigator` creates them for you.

---

## FAQ

### Q: There's an `AnyView` inside `RouteRegistry`. Doesn't that defeat the purpose of SwiftUI structured identity?

The `AnyView` is **contained inside the registry's type-erasure mechanism** — it never appears in feature code. SwiftUI's diffing impact is negligible because:
- The `AnyView` wraps an entire coordinator view (heavy subtree), not a leaf.
- Navigation destinations are created lazily on push, not during body evaluation.
- This is the same trade-off UIKit made with `UIViewController` — the container doesn't know the concrete type.

The important thing is that **features never write `AnyView`** and **the composition root never writes `AnyView`**. It's an implementation detail of the infrastructure.


### Q: How does deep linking work?

Parse the deep link URL into a `NavigationIntent`, then call `navigator.perform(_:)`. Since route keys have stable string IDs, the mapping is straightforward:

```swift
func intent(from url: URL) -> NavigationIntent? {
    switch url.path {
    case "/chat": NavigationIntent(ChatRouteKey.self)
    case "/meal": NavigationIntent(MealDetailsRouteKey.self, parameter: parseFoodEntry(from: url))
    default: nil
    }
}
//...
navigator.perform(intent(from: "https://..."))
```

### Q: Can push notifications work with this?

Yes, same as with deeplinks/universal links, parse the payloads and convert them into intents. Store those intents for deferred navigation (if you need some auth or whatever) or execute them immediately by passing intents to the navigator.

### Q: What about UIKit?

Wrap your UIKit stuff into `UIViewControllerRepresentable` and treat those views as any other SwiftUI views.
If you use UIKit Coordinators, you can embed `RoutingCoordinatorView` into `UIHostingController`. Let your coordinator hold the reference to the navigator and route registry.

### Q: What about tab-based navigation?

Each tab gets its own `Navigator` + `RouteRegistry` pair. The tab bar view holds multiple `RoutingCoordinatorView` instances:

```swift
TabView {
    RoutingCoordinatorView(router: homeRouter, registry: homeRegistry) { ... }
        .tabItem { Label("Home", systemImage: "house") }

    RoutingCoordinatorView(router: discoverRouter, registry: discoverRegistry) { ... }
        .tabItem { Label("Discover", systemImage: "magnifyingglass") }
}
```

## To run the project
- Install tuist
- run `tuist generate` from the root of the repo
