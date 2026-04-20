# Navigator

A small, compile-time-safe navigation engine for SwiftUI apps built from many feature modules.

## Why

A feature module should be able to say **"open profile for user 42"** without knowing where
Profile lives, what it imports, or how its view tree is assembled. Navigator lets each
feature:

- **Declare** routes in its Interface module (types only, no views).
- **Implement** routes in its Feature module (view code + dependencies).
- **Register** routes in a composition root (one line per feature).
- **Navigate** between features with compile-time parameter safety.

Hundreds of modules can contribute routes without ever touching each other's code or a
shared enum.

## Core concepts

| Type | Owner | Purpose |
|---|---|---|
| `RouteKey` | Interface module | Compile-time id + `Parameter` type for a destination |
| `RouteHandler` | Feature module | Factory that builds the destination `View` |
| `RouteRegistry` | Composition root | Phone book: id → factory |
| `AppRouteModule` | Feature module | Bundles every handler a feature contributes |
| `Navigator` | Injected into env | Feature-facing navigation API |
| `NavigationIntent` | Anywhere | Router-independent "navigate here" value, e.g. for deep links |
| `RoutingCoordinatorView` | Composition root | SwiftUI integration — binds router state to `NavigationStack` |

## Feature checklist

When you add a new feature, say **Recipes**:

1. Create `RecipesInterface` library. Declare:
   ```swift
   public enum RecipesRouteKey: RouteKey {
       public typealias Parameter = RecipeID
   }
   ```
2. In `Recipes` (the implementation target), add:
   ```swift
   public struct RecipesRouteModule: AppRouteModule {
       let dependencies: RecipesDependencies
       public init(dependencies: RecipesDependencies) { self.dependencies = dependencies }

       public func registerRoutes(in registry: RouteRegistry) {
           registry.register(RecipesRouteKey.self) { id in
               RecipesView(dependencies: self.dependencies, recipeID: id)
           }
       }
   }
   ```
3. In the composition root:
   ```swift
   registry.register(RecipesRouteModule(dependencies: rootContainer.recipes))
   ```
4. Any other feature that wants to open a recipe:
   ```swift
   import RecipesInterface
   @Environment(Navigator.self) private var router
   router.navigate(to: RecipesRouteKey.self, parameter: recipeID)
   ```

No other file needs to change.

## Navigation API

```swift
router.navigate(to: ChatRouteKey.self)                                // push, Void parameter
router.navigate(to: ProfileRouteKey.self, parameter: userID)          // push, with parameter
router.navigate(to: PaywallRouteKey.self, style: .present)            // sheet
router.navigate(to: OrdersRouteKey.self, style: .overridingRoot)      // replace root

router.pop()                                                          // pop 1
router.pop(count: 2)                                                  // pop 2
router.pop(to: HistoryRouteKey.self)                                  // pop back to a key
router.popToRoot()
router.dismiss()

router.perform(intent)                                                // NavigationIntent
router.setPath([intent1, intent2, intent3])                           // deep link
```

## Observing navigation

```swift
router.onEvent = { event in analytics.track(event) }
```

Or in tests:

```swift
var captured: [NavigationEvent] = []
router.onEvent = { captured.append($0) }
```

## Deep linking

Each feature's interface module ships a tiny URL → intent decoder:

```swift
// RecipesInterface/RecipesDeepLink.swift
public enum RecipesDeepLink {
    public static func intent(from url: URL) -> NavigationIntent? {
        guard url.pathComponents.dropFirst().first == "recipe",
              let id = url.pathComponents.dropFirst(2).first.flatMap(RecipeID.init)
        else { return nil }
        return NavigationIntent(RecipesRouteKey.self, parameter: id)
    }
}
```

Composition root strings them together:

```swift
let decoders: [(URL) -> NavigationIntent?] = [
    ChatDeepLink.intent(from:),
    RecipesDeepLink.intent(from:),
    ProfileDeepLink.intent(from:),
]

if let intent = decoders.lazy.compactMap({ $0(url) }).first {
    router.perform(intent)
}
```

## Diagnostics

Two teams stomping on the same `RouteKey.id`? Forgot to register a handler? Want an
analytics/crash-reporter hook? Inject a `NavigatorDiagnostics`:

```swift
let diagnostics = NavigatorDiagnostics(
    duplicatePolicy: .assertInDebug,
    logger: { logger.warning("[Navigator] \($0)") },
    onUnresolvedRoute: { key in crashReporter.log("unresolved route: \(key)") },
    onParameterTypeMismatch: { key, expected, actual in
        crashReporter.log("type mismatch on \(key): expected \(expected), got \(actual)")
    }
)
let registry = RouteRegistry(diagnostics: diagnostics)
```

The default policy asserts in debug and replaces silently in release.

## Nested coordinators

A large feature can host its own `RoutingCoordinatorView` with a private `Navigator` and
`RouteRegistry` for sub-routes. The parent coordinator never sees those sub-routes.
See `BigTechNavigator/Sources/DemoCatalogFeature/CatalogFeature.swift` for a working
example (`CheckoutCoordinatorView`).

## FlowScope: exactly-once construction for flow-scoped objects

SwiftUI's `@State` is **eager**. `@State private var store = FooStore(...)` evaluates the
initializer every time the view struct is reinitialised — and SwiftUI silently discards all
but the first. Those discarded instances are fully constructed and then `deinit`. A coordinator
view hosted inside `.sheet(item:)` or `.navigationDestination(for:)` is typically reinitialised
**at least twice** per presentation, which is why `deinit` appears to fire more than once.

For expensive stores, observable work, or anything with a visible `deinit` side effect, use
`@FlowScope`:

```swift
@MainActor
private final class FavoritesFlow {
    let navigator = Navigator()
    let registry: RouteRegistry
    let store: FavoritesStore

    init(dependencies: DependenciesContainer) { /* ... */ }
}

struct CoordinatedFavoritesView: View {
    let dependencies: DependenciesContainer
    @FlowScope private var flow: FavoritesFlow

    var body: some View {
        RoutingCoordinatorView(router: flow.navigator, registry: flow.registry) {
            FavoritesView(store: flow.store)
        }
        .flowScope($flow) { FavoritesFlow(dependencies: dependencies) }
    }
}
```

`FlowScope` constructs the flow object the first time the body asks for it and caches it in a
stable `@State` box. Subsequent body evaluations reuse the existing instance — no throwaway
construction, no spurious `deinit`.

## Testing

Because `Navigator` is `@MainActor` and `@Observable`, tests can drive it directly:

```swift
@Test("route is pushed")
@MainActor func push() {
    let router = Navigator()
    router.navigate(to: ProfileRouteKey.self, parameter: .id42)
    #expect(router.path.count == 1)
    #expect(router.path.first?.key == ProfileRouteKey.id)
}
```

Or observe via `onEvent` to assert fire-and-forget intents.
