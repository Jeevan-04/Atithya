# Flutter & This Project — Complete Beginner's Guide

> Start from zero. By the end of this document you will understand every line of this codebase.

---

## Table of Contents

### Part A — Flutter Foundations
1. [What is Flutter?](#1-what-is-flutter)
2. [Dart Language Essentials](#2-dart-language-essentials)
3. [OOP in Dart](#3-oop-in-dart)
4. [Widgets — Everything is a Widget](#4-widgets--everything-is-a-widget)
5. [Widget Lifecycle](#5-widget-lifecycle)
6. [State in Flutter](#6-state-in-flutter)
7. [Layouts & Composition](#7-layouts--composition)
8. [Navigation & Routing](#8-navigation--routing)
9. [Async Programming in Dart](#9-async-programming-in-dart)
10. [HTTP & REST in Flutter](#10-http--rest-in-flutter)
11. [SharedPreferences (Local Storage)](#11-sharedpreferences-local-storage)
12. [Flutter Riverpod (State Management)](#12-flutter-riverpod-state-management)
13. [pubspec.yaml — Dependencies & Assets](#13-pubspecyaml--dependencies--assets)
14. [Imports in Dart](#14-imports-in-dart)

### Part B — This Project: File by File
15. [Project Map](#15-project-map)
16. [main.dart](#16-maindart)
17. [core/colors.dart](#17-corecolorsdart)
18. [core/typography.dart](#18-coretyographydart)
19. [core/theme.dart](#19-corethemedart)
20. [core/network/api_client.dart](#20-corenetworkapi_clientdart)
21. [providers/auth_provider.dart](#21-providersauth_providerdart)
22. [providers/estate_provider.dart](#22-providersestate_providerdart)
23. [providers/booking_provider.dart](#23-providersbooking_providerdart)
24. [providers/notifications_provider.dart](#24-providersnotifications_providerdart)
25. [features/shell/app_shell.dart](#25-featuresshellapp_shelldart)
26. [features/splash/splash_screen.dart](#26-featuressplashsplash_screendart)
27. [features/auth/auth_foyer_screen.dart](#27-featuresauthauth_foyer_screendart)
28. [features/discover/discover_screen.dart](#28-featuresdiscoverscreen)
29. [features/estates/estates_screen.dart](#29-featuresestates)
30. [features/booking/booking_flow_screen.dart](#30-featuresbooking)
31. [features/payment/payment_screen.dart](#31-featurespayment)
32. [features/dossier/dossier_screen.dart](#32-featuresdossier)
33. [features/sanctum/sanctum_screen.dart](#33-featuressanctum)
34. [features/concierge/concierge_modal.dart](#34-featuresconcierge)
35. [features/admin/admin_shell.dart](#35-featuresadmin)
36. [backend/server.js](#36-backendserverjs)
37. [backend/reset_estates.js](#37-backendresetestatesjs)
38. [backend/models/](#38-backendmodels)

---

# PART A — FLUTTER FOUNDATIONS

---

## 1. What is Flutter?

Flutter is a **UI toolkit made by Google** that lets you write one codebase and run it on:
- Android, iOS
- Web (Chrome, Firefox, Safari)
- Windows, macOS, Linux

It uses the **Dart** programming language and renders its own pixels using the **Skia / Impeller** graphics engine. It does NOT use native HTML elements or native Android/iOS views — it draws everything itself, like a game engine.

### Why Flutter for this project?
This project targets **Flutter Web** deployed on GitHub Pages. One codebase serves both web and mobile.

### How Flutter renders
```
Your Dart Code
     ↓
  Widget Tree
     ↓
  Element Tree (Flutter framework)
     ↓
  Render Tree (layout, paint)
     ↓
  Skia / Impeller (GPU)
     ↓
  Pixels on screen
```

---

## 2. Dart Language Essentials

Dart is a **statically-typed, object-oriented** language. If you know Java, Swift, Kotlin or TypeScript you will feel at home.

### Variables

```dart
// Typed declarations
String name = 'Atithya';
int price = 85000;
double rating = 4.9;
bool isFeatured = true;

// Type inferred (Dart figures out the type)
var title = 'Taj Mahal Palace';   // String inferred
final basePrice = 85000;          // int inferred, cannot be reassigned
const Pi = 3.14159;               // compile-time constant
```

**`var`** — mutable, type inferred once assigned  
**`final`** — mutable value set once at runtime  
**`const`** — compile-time constant, value known before running

### Null Safety

Dart has **sound null safety** — variables cannot be null unless you explicitly allow it:

```dart
String name = 'Jeevan';      // cannot be null
String? error = null;        // nullable: can be null, needs '?' 
print(error?.length);        // safe access: prints null if error is null
print(error ?? 'No error');  // null coalescing: 'No error' if null
```

This prevents the NullPointerException class of bugs at compile time.

### Collections

```dart
// List (ordered, allows duplicates)
List<String> images = ['img1.jpg', 'img2.jpg'];
images.add('img3.jpg');
images[0];                   // 'img1.jpg'

// Map (key-value pairs)
Map<String, dynamic> estate = {
  'title': 'Taj Mahal Palace',
  'city': 'Mumbai',
  'price': 85000,
};
estate['title'];             // 'Taj Mahal Palace'

// Set (unordered, no duplicates)
Set<String> cities = {'Mumbai', 'Jodhpur', 'Varanasi'};
```

### Functions

```dart
// Named function
String greet(String name) {
  return 'Welcome, $name';
}

// Arrow function (single expression)
String greet(String name) => 'Welcome, $name';

// Optional named parameters (with defaults)
void createBooking({
  required String estateId,
  required DateTime checkIn,
  int guests = 2,
  String? roomType,
}) { ... }

// Called as:
createBooking(estateId: 'abc123', checkIn: DateTime.now());
```

### String Interpolation

```dart
String city = 'Mumbai';
int price = 85000;
print('Estate in $city costs ₹$price per night');
print('Length: ${city.length}');      // expressions need ${}
```

### Conditional Expressions

```dart
// Ternary
String status = isAvailable ? 'Available' : 'Fully Booked';

// Null coalescing
String display = userName ?? 'Guest';

// Null-aware assignment
userName ??= 'Guest';  // only assigns if userName is null
```

---

## 3. OOP in Dart

Everything in Dart is an **object** — even `int` and `String` are objects. Dart supports all standard OOP concepts.

### Classes

```dart
class Estate {
  // Fields
  final String title;
  final String city;
  final double rating;
  bool isFeatured;

  // Constructor
  Estate({
    required this.title,
    required this.city,
    required this.rating,
    this.isFeatured = false,
  });

  // Method
  String get displayName => '$title, $city';

  // Override toString
  @override
  String toString() => 'Estate($title, $city)';
}

// Usage
final estate = Estate(title: 'Taj', city: 'Mumbai', rating: 5.0);
print(estate.displayName);   // Taj, Mumbai
```

### Constructors

```dart
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  // Default constructor
  const AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  // Named constructor
  AuthState.loading() : isLoading = true, isAuthenticated = false, error = null;

  // Factory constructor (can return existing instance or subtype)
  factory AuthState.fromJson(Map<String, dynamic> json) {
    return AuthState(
      isLoading: json['loading'] ?? false,
      isAuthenticated: json['authenticated'] ?? false,
    );
  }
}
```

### `copyWith` Pattern (Immutability)

In Flutter state management, state objects are **immutable** — you never modify them in place. Instead you create a new copy with some fields changed:

```dart
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  const AuthState({this.isLoading = false, this.isAuthenticated = false, this.error});

  // Returns a new AuthState with specified fields replaced
  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    bool clearError = false,    // special flag to null-out error
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Usage:
var state = const AuthState();
state = state.copyWith(isLoading: true);
state = state.copyWith(isLoading: false, isAuthenticated: true);
// Original state object is never modified
```

### Inheritance

```dart
class Animal {
  String name;
  Animal(this.name);
  void speak() => print('...');
}

class Dog extends Animal {
  Dog(String name) : super(name);  // call parent constructor

  @override
  void speak() => print('$name says: Woof!');
}
```

### Abstract Classes & Interfaces

```dart
// Abstract class — cannot be instantiated directly
abstract class Repository {
  Future<List<Estate>> fetchAll();
  Future<Estate?> findById(String id);
}

// Concrete implementation
class EstateRepository implements Repository {
  @override
  Future<List<Estate>> fetchAll() async {
    // fetch from API
    return [];
  }

  @override
  Future<Estate?> findById(String id) async {
    return null;
  }
}
```

### Mixins

Mixins let you **reuse code across unrelated class hierarchies** without full inheritance:

```dart
mixin LoadingMixin {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  void startLoading() => _isLoading = true;
  void stopLoading() => _isLoading = false;
}

class BookingScreen extends StatefulWidget with LoadingMixin { ... }
```

### Enums

```dart
enum AuthStep { idle, otp, name, authenticated }
enum BookingStatus { pending, confirmed, cancelled, refunded }

// Usage:
AuthStep step = AuthStep.otp;
if (step == AuthStep.otp) { showOtpInput(); }

// Enhanced enum (Dart 2.17+)
enum BookingStatus {
  pending('Pending'),
  confirmed('Confirmed'),
  cancelled('Cancelled');

  final String label;
  const BookingStatus(this.label);
}
print(BookingStatus.confirmed.label);  // 'Confirmed'
```

### Generics

```dart
// Generic class
class ApiResponse<T> {
  final T? data;
  final String? error;
  const ApiResponse({this.data, this.error});
}

ApiResponse<List<Estate>> response = ApiResponse(data: estates);
ApiResponse<String> tokenResponse = ApiResponse(data: 'eyJ...');

// Generic function
T parseJson<T>(String json, T Function(Map<String, dynamic>) fromJson) {
  return fromJson(jsonDecode(json));
}
```

---

## 4. Widgets — Everything is a Widget

In Flutter, **every visual element is a widget**. Buttons, text, padding, rows, columns, screens — all widgets.

### Widget Types

```
                    Widget
                   /      \
          StatelessWidget  StatefulWidget
```

**StatelessWidget** — describes UI that depends only on its configuration (no changing state). Built once, rebuilds only when parent passes new data.

```dart
class PriceTag extends StatelessWidget {
  final int price;
  const PriceTag({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    return Text(
      '₹${price.toString()}',
      style: const TextStyle(color: Color(0xFFD4AF6A), fontSize: 18),
    );
  }
}
```

**StatefulWidget** — has mutable state that can change over the widget's lifetime. Rebuilt every time `setState()` is called.

```dart
class CounterButton extends StatefulWidget {
  const CounterButton({super.key});

  @override
  State<CounterButton> createState() => _CounterButtonState();
}

class _CounterButtonState extends State<CounterButton> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        setState(() => _count++);    // triggers rebuild
      },
      child: Text('Count: $_count'),
    );
  }
}
```

**ConsumerWidget** (Riverpod) — like StatelessWidget but can read providers:

```dart
class EstateCard extends ConsumerWidget {
  const EstateCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estates = ref.watch(estateProvider).estates;
    return ListView.builder(
      itemCount: estates.length,
      itemBuilder: (_, i) => Text(estates[i]['title']),
    );
  }
}
```

### Common Flutter Widgets

| Widget | Purpose |
|--------|---------|
| `Text` | Display text |
| `Container` | Box with padding, margin, decoration, size |
| `Row` | Horizontal layout |
| `Column` | Vertical layout |
| `Stack` | Overlapping widgets |
| `Expanded` | Fill remaining space in Row/Column |
| `Flexible` | Flexible space in Row/Column |
| `SizedBox` | Fixed-size box or spacing gap |
| `Padding` | Add space around a child |
| `Center` | Center a child |
| `GestureDetector` | Detect taps, swipes, long-presses |
| `InkWell` | Tap with ripple effect |
| `ListView` | Scrollable list |
| `GridView` | Scrollable grid |
| `Image.network` | Load image from URL |
| `Scaffold` | Screen structure (appbar, body, fab, bottomNav) |
| `AppBar` | Top application bar |
| `BottomNavigationBar` | Tab navigation |
| `FloatingActionButton` | Circular action button |
| `ElevatedButton` | Raised button |
| `TextField` | Text input field |
| `CircularProgressIndicator` | Loading spinner |
| `SnackBar` | Toast notification at bottom |
| `Dialog` | Modal dialog |
| `BottomSheet` | Bottom sliding panel |
| `FutureBuilder` | Rebuild on Future completion |
| `StreamBuilder` | Rebuild on Stream events |
| `AnimatedContainer` | Animated box transitions |
| `Hero` | Shared-element animation between routes |
| `ClipRRect` | Clip child to rounded rectangle |
| `BackdropFilter` | Blur behind widget (glassmorphism) |

---

## 5. Widget Lifecycle

### StatefulWidget Lifecycle

```
Constructor → createState() → initState() → build() → [updates] → dispose()
```

| Method | When called | Use for |
|--------|------------|---------|
| `constructor` | When widget created | Pass configuration |
| `createState()` | Once | Create the State object |
| `initState()` | Once, after first build | Init controllers, listeners, one-time setup |
| `didChangeDependencies()` | After initState + when InheritedWidget changes | Access context-dependent things |
| `build()` | Every rebuild | Return widget tree (pure, no side effects) |
| `didUpdateWidget(old)` | When parent rebuilds with new config | React to config changes |
| `setState()` | Called by you | Mark state dirty → triggers build() |
| `deactivate()` | Removed from tree temporarily | Cleanup that may be re-added |
| `dispose()` | Permanently removed | Dispose controllers, cancel streams |

```dart
class _MyScreenState extends State<MyScreen> {
  late AnimationController _ctrl;   // late = initialized later

  @override
  void initState() {
    super.initState();                           // ALWAYS call super first
    _ctrl = AnimationController(                 // init here, not in constructor
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _ctrl.forward();                             // start animation once
  }

  @override
  void dispose() {
    _ctrl.dispose();                             // ALWAYS dispose controllers
    super.dispose();                             // call super last
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(opacity: _ctrl.value, child: const Text('Hello')),
    );
  }
}
```

### ConsumerStatefulWidget (Riverpod)

```dart
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with TickerProviderStateMixin {    // mixin for vsync
  // 'ref' is available here (from ConsumerState)
  // TickerProviderStateMixin provides vsync for animations
}
```

---

## 6. State in Flutter

"State" is any data that can change and whose change should update the UI.

### Local State — `setState()`

For small, widget-local state (is a button pressed? is a dropdown open?):

```dart
class _TabBarState extends State<TabBar> {
  int _selected = 0;

  void _selectTab(int i) {
    setState(() => _selected = i);   // marks dirty → rebuild
  }
}
```

### App-Level State — Riverpod

For state shared across many screens (auth, estates list, bookings), use Riverpod. See [Section 12](#12-flutter-riverpod-state-management).

### State Lifting

When two widgets need the same state, "lift" it to their nearest common ancestor:

```dart
// Parent holds state
class SearchPage extends StatefulWidget { ... }
class _SearchPageState extends State<SearchPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SearchBar(onChanged: (q) => setState(() => _query = q)),
      ResultsList(query: _query),    // passed down
    ]);
  }
}
```

---

## 7. Layouts & Composition

Flutter UI is built by **composing small widgets** into trees.

### Row & Column

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,   // vertical axis
  crossAxisAlignment: CrossAxisAlignment.start,  // horizontal axis
  children: [
    Text('Title'),
    const SizedBox(height: 8),          // spacer
    Row(
      children: [
        const Icon(Icons.star),
        Text('4.9'),
        const Spacer(),                 // push next to end
        Text('₹85,000'),
      ],
    ),
  ],
)
```

### Stack

```dart
Stack(
  children: [
    Image.network(heroUrl, fit: BoxFit.cover),   // background
    Positioned(
      bottom: 16, left: 16,
      child: Text('Taj Mahal Palace'),            // overlay
    ),
    Positioned(
      top: 16, right: 16,
      child: const Icon(Icons.bookmark_border),  // top-right corner
    ),
  ],
)
```

### Container Decoration

```dart
Container(
  width: 300,
  height: 200,
  padding: const EdgeInsets.all(16),
  margin: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
    color: const Color(0xFF12161E),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.white12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
    gradient: const LinearGradient(
      colors: [Color(0xFF1A1E28), Color(0xFF080A0E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  child: Text('Palace Card'),
)
```

### Glassmorphism (BackdropFilter)

Used throughout this app for floating nav, cards, modals:

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(20),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Container(
      color: Colors.black.withOpacity(0.4),
      child: const Text('Glass Panel'),
    ),
  ),
)
```

### Responsive Layouts

```dart
@override
Widget build(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final isWide = width > 600;

  return isWide
    ? Row(children: [Sidebar(), MainContent()])         // tablet / web
    : Column(children: [MainContent(), BottomNav()]);   // phone
}
```

---

## 8. Navigation & Routing

### push / pop (imperative)

```dart
// Go to a new screen
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => const EstateDetailScreen()),
);

// Go back
Navigator.of(context).pop();

// Pass data back
Navigator.of(context).pop({'confirmed': true, 'bookingId': '...'});

// Replace current screen (no back)
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => const AppShell()),
);

// Clear stack + go (logout pattern)
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const AuthFoyerScreen()),
  (_) => false,    // remove ALL previous routes
);
```

### Bottom Sheets

```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,          // allow full height
  backgroundColor: Colors.transparent,
  builder: (_) => const BookingFlowSheet(),
);
```

---

## 9. Async Programming in Dart

All network calls, file reads, and timers are **asynchronous**. Dart uses `Future` and `async/await`.

### Future

A `Future<T>` represents a value that will be available later:

```dart
Future<String> fetchEstateName(String id) async {
  // 'await' pauses here until the http call completes
  final response = await http.get(Uri.parse('$baseUrl/estates/$id'));
  final data = jsonDecode(response.body);
  return data['title'];
}

// Calling it:
void loadEstate() async {
  try {
    final name = await fetchEstateName('abc123');
    print(name);
  } catch (e) {
    print('Error: $e');
  }
}
```

### try / catch / finally

```dart
Future<void> fetchData() async {
  try {
    final data = await apiClient.get('/estates');
    state = state.copyWith(estates: data);
  } on SocketException {
    state = state.copyWith(error: 'No internet connection');
  } catch (e) {
    state = state.copyWith(error: e.toString());
  } finally {
    state = state.copyWith(isLoading: false);   // always runs
  }
}
```

### Future.microtask()

`Future.microtask()` schedules work to run **after the current synchronous frame** — on the next event loop iteration. Used in provider `build()` functions to avoid modifying state during build:

```dart
@override
EstateState build() {
  Future.microtask(() => fetchEstates());   // deferred — safe
  return EstateState(isLoading: true);      // return immediately
}
```

If you called `fetchEstates()` directly inside `build()`, it might trigger another state change while the current build is in progress — that would throw an error.

### Streams

Streams are sequences of async values — like a river of data:

```dart
Stream<int> countdown(int from) async* {
  for (int i = from; i >= 0; i--) {
    yield i;                               // emit a value
    await Future.delayed(const Duration(seconds: 1));
  }
}

// Listen to stream
countdown(10).listen((n) => print('$n seconds left'));

// Consume in widget with StreamBuilder
StreamBuilder<int>(
  stream: countdown(10),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const CircularProgressIndicator();
    return Text('${snapshot.data} seconds');
  },
)
```

---

## 10. HTTP & REST in Flutter

The `http` package performs HTTP requests. It is imported as `http` and methods return `Future<http.Response>`.

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

// GET
final response = await http.get(
  Uri.parse('https://api.example.com/estates'),
  headers: {'Authorization': 'Bearer $token'},
);

if (response.statusCode == 200) {
  final List data = jsonDecode(response.body);
} else {
  throw Exception('Failed: ${response.statusCode}');
}

// POST
final response = await http.post(
  Uri.parse('https://api.example.com/bookings'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: jsonEncode({
    'estateId': 'abc123',
    'checkIn': '2026-04-01',
    'checkOut': '2026-04-05',
  }),
);
```

### JSON Encoding & Decoding

```dart
import 'dart:convert';

// Dart object → JSON string
String json = jsonEncode({'name': 'Jeevan', 'age': 21});
// → '{"name":"Jeevan","age":21}'

// JSON string → Dart object
Map<String, dynamic> map = jsonDecode('{"name":"Jeevan"}');
// → {name: Jeevan}
```

---

## 11. SharedPreferences (Local Storage)

`shared_preferences` stores small key-value data (like JWT tokens) **persistently** on device:

```dart
import 'package:shared_preferences/shared_preferences.dart';

// Save
final prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', 'eyJ...');
await prefs.setBool('onboarded', true);

// Read
final token = prefs.getString('auth_token');   // null if not set
final done  = prefs.getBool('onboarded') ?? false;

// Delete
await prefs.remove('auth_token');

// Clear all
await prefs.clear();
```

This is where the JWT is stored in this project. When the app launches, `AuthNotifier._checkInitialAuth()` reads the stored token and if valid, restores the session.

---

## 12. Flutter Riverpod (State Management)

Riverpod is the **state management library** used in this project. It solves the problem of sharing and reacting to state changes across many unrelated widgets.

### Why not just setState()?

`setState()` only rebuilds the widget that called it and its subtree. If 5 different screens need to know if the user is logged in, you'd have to pass the auth state down through many widget constructors — "prop drilling". Riverpod makes state globally accessible, reactively.

### Core Concepts

```
Provider         → holds a piece of state
Notifier         → a class that can change that state
ProviderScope    → root container (like a DI container)
ref.watch(p)     → read + subscribe (rebuild when changes)
ref.read(p)      → read once (no subscription)
ref.listen(p, f) → run a callback when provider changes
```

### Modern Pattern — Notifier + NotifierProvider

```dart
// 1. State object (plain immutable class)
class BookingState {
  final bool isLoading;
  final List<dynamic> bookings;
  final String? error;

  BookingState({this.isLoading = false, this.bookings = const [], this.error});

  BookingState copyWith({bool? isLoading, List<dynamic>? bookings, String? error}) {
    return BookingState(
      isLoading: isLoading ?? this.isLoading,
      bookings: bookings ?? this.bookings,
      error: error ?? this.error,
    );
  }
}

// 2. Notifier (manages state + business logic)
class BookingNotifier extends Notifier<BookingState> {
  @override
  BookingState build() {
    // Called once when first watched
    // Use Future.microtask to defer any state changes
    Future.microtask(() => fetchMyBookings());
    return BookingState(isLoading: true);
  }

  Future<void> fetchMyBookings() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await apiClient.get('/bookings');
      state = state.copyWith(isLoading: false, bookings: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

// 3. Provider (global registry entry)
final bookingProvider = NotifierProvider<BookingNotifier, BookingState>(
  BookingNotifier.new,    // factory: creates BookingNotifier when first needed
);

// 4. Widget reads it
class DossierScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingProvider);

    if (bookingState.isLoading) {
      return const CircularProgressIndicator();
    }
    if (bookingState.error != null) {
      return Text('Error: ${bookingState.error}');
    }
    return BookingList(bookings: bookingState.bookings);
  }
}

// 5. Call methods (actions → trigger state changes)
ElevatedButton(
  onPressed: () => ref.read(bookingProvider.notifier).fetchMyBookings(),
  child: const Text('Refresh'),
)
```

### ref.watch vs ref.read

```dart
// ref.watch — subscribe: widget rebuilds when provider changes
final state = ref.watch(estateProvider);           // USE in build()

// ref.read — one-time read, no subscription
ref.read(authProvider.notifier).logout();          // USE in event handlers

// ref.listen — run callback on change (navigation, SnackBars)
ref.listen(authProvider, (prev, next) {            // USE in build()
  if (!next.isAuthenticated) {
    Navigator.of(context).pushReplacement(...);
  }
});
```

### select() — Partial Watching

Watch only a specific field of a provider's state to avoid unnecessary rebuilds:

```dart
// Only rebuilds when isAuthenticated changes, not when user.name changes
final isAuth = ref.watch(authProvider.select((s) => s.isAuthenticated));
```

---

## 13. pubspec.yaml — Dependencies & Assets

`pubspec.yaml` is Flutter's **package manager config file** (like `package.json` in Node.js).

```yaml
name: atithya
description: Royal Hospitality Platform

environment:
  sdk: '>=3.0.0 <4.0.0'   # Dart SDK version constraint

dependencies:
  flutter:
    sdk: flutter             # Flutter itself (always included)

  # State management
  flutter_riverpod: ^2.5.0  # ^ means "compatible with 2.5.x but not 3.x"

  # HTTP
  http: ^1.2.0

  # Local storage
  shared_preferences: ^2.2.3

  # 3D viewer
  model_viewer_plus: ^1.7.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0     # dart linting rules

flutter:
  uses-material-design: true

  assets:                    # list all assets you want to bundle
    - assets/images/
    - assets/lottie/
    - assets/videos/

  fonts:                     # custom fonts
    - family: CormorantGaramond
      fonts:
        - asset: assets/fonts/CormorantGaramond-Regular.ttf
        - asset: assets/fonts/CormorantGaramond-Bold.ttf
          weight: 700
```

Run `flutter pub get` to download all dependencies into `.dart_tool/`.

---

## 14. Imports in Dart

```dart
// Standard library (built into Dart, no install needed)
import 'dart:convert';      // JSON encode/decode
import 'dart:math';         // Math.random, pi, etc.
import 'dart:ui';           // Low-level Flutter APIs (ImageFilter, etc.)
import 'dart:async';        // Future, Stream, Completer

// Flutter framework
import 'package:flutter/material.dart';     // Everything Material: Widget, Scaffold, etc.
import 'package:flutter/services.dart';     // Platform channels, SystemChrome

// External packages (listed in pubspec.yaml)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;    // 'as' gives it an alias
import 'package:shared_preferences/shared_preferences.dart';

// Your own files (relative path)
import '../../core/colors.dart';            // go up 2 dirs, then core/colors.dart
import '../providers/auth_provider.dart';
import 'widgets/estate_card.dart';          // same directory → sub-folder
```

Import rules:
- Use `package:flutter/...` for Flutter framework
- Use `dart:...` for Dart standard library
- Use relative `'../../...'` paths for your own files
- Never import `.dart` files from `build/` or `.dart_tool/` — those are generated

---

# PART B — THIS PROJECT: FILE BY FILE

---

## 15. Project Map

Here is the **call graph** — which file calls which when a user opens the app:

```
main.dart
  └─ ProviderScope
       └─ AtithyaApp
            └─ MaterialApp
                 └─ SplashScreen
                      ├─ checks authProvider on load
                      │    └─ api_client.get('/auth/me')
                      │         └─ SharedPreferences (read token)
                      │
                      ├─ if authenticated → AppShell
                      │    ├─ DiscoverScreen
                      │    │    └─ reads estateProvider / discover API
                      │    ├─ EstatesScreen
                      │    │    └─ reads estateProvider
                      │    ├─ ItinerariesScreen
                      │    └─ SanctumScreen
                      │         ├─ reads authProvider
                      │         ├─ reads bookingProvider
                      │         └─ reads notificationsProvider
                      │
                      └─ if not authenticated → AuthFoyerScreen
                           └─ interacts with authProvider (OTP flow)
```

---

## 16. main.dart

**Location**: `lib/main.dart`  
**Role**: App entry point — the very first Dart code that runs.

```dart
void main() {
```
`main()` is the entry point. Every Dart program starts here. Flutter's `runApp()` must be called from here.

```dart
  WidgetsFlutterBinding.ensureInitialized();
```
This **must** be the very first line when you need to call platform code before `runApp`. It initializes the Flutter engine's connection to the platform (Android/iOS/Web). Without this, calling `SystemChrome` or `SharedPreferences` before `runApp` would crash.

```dart
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
```
`SystemChrome` talks to the native platform to control the status bar (top bar with wifi/battery) and system nav bar (bottom Android buttons). Setting `statusBarColor: Colors.transparent` lets the app draw content behind the status bar — required for the full-bleed hero image look.

```dart
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
```
Lock the app to portrait-up. `setPreferredOrientations` returns a `Future`, so everything after it runs when the lock is confirmed. The `_` parameter in `.then((_) {})` means "I don't need this callback's value".

```dart
    runApp(
      const ProviderScope(
        child: AtithyaApp(),
      ),
    );
```
`runApp()` inflates the root widget and attaches it to the screen. `ProviderScope` is **required by Riverpod** — it is the container/registry for all providers. Without it, any `ref.watch()` call would throw. `AtithyaApp` is our root widget.

```dart
class AtithyaApp extends StatelessWidget {
  const AtithyaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'आतिथ्य | ATITHYA',
      debugShowCheckedModeBanner: false,
      theme: AtithyaTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
```
`MaterialApp` sets up:
- `title` — used by OS task switcher
- `debugShowCheckedModeBanner: false` — hides the "DEBUG" ribbon in top-right
- `theme` — hands our custom `AtithyaTheme.darkTheme` to the entire widget tree (any child can read it via `Theme.of(context)`)
- `home` — the first screen shown, which is `SplashScreen`

---

## 17. core/colors.dart

**Role**: Central palette — every color used in the app is defined here as a `static const`.

```dart
class AtithyaColors {
  // Constructor is never called — all members are static
```
Making all fields `static const` means:
- No instance needed — `AtithyaColors.obsidian` works without `new AtithyaColors()`
- `const` means compile-time constant — the value is baked in at build time, zero runtime cost

```dart
  static const Color obsidian = Color(0xFF080A0E);
```
`Color(0xFF080A0E)` takes a 32-bit ARGB hex value:
- `FF` = alpha (fully opaque)
- `08` = red (very low)
- `0A` = green (very low)
- `0E` = blue (very low)
This makes a near-black with a very subtle cool tint — the luxury "obsidian" effect.

```dart
  static const LinearGradient goldGradient = LinearGradient(
    colors: [shimmerGold, imperialGold, burnishedGold],
    stops: [0.0, 0.5, 1.0],
  );
```
`LinearGradient` can be used as a `decoration` on `Container` or as a `foreground` on `ShaderMask`. `stops` define where each color sits along the gradient (0.0 = start, 1.0 = end, 0.5 = middle).

---

## 18. core/typography.dart

**Role**: All text styles as static constants.

The app uses **Cormorant Garamond** — an editorial serif that prints magazines use. All fonts are declared in `pubspec.yaml` under `flutter.fonts`.

```dart
class AtithyaTypography {
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: 42,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.5,
    color: AtithyaColors.pearl,
  );
```
`fontWeight: FontWeight.w300` is "Light" weight (300 is thin, 400 normal, 700 bold). Luxury typography typically uses light weights for large display text.

`letterSpacing: -0.5` reduces space between letters — negative letter-spacing is another luxury print convention (tight, dense headings).

---

## 19. core/theme.dart

**Role**: Assembles all colors + typography into a Flutter `ThemeData` object.

```dart
class AtithyaTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
```
`useMaterial3: true` enables Material Design 3 (Google's latest design system). Without this Flutter uses Material 2.

```dart
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AtithyaColors.obsidian,
```
`brightness: Brightness.dark` tells Flutter this is a dark theme — affects default icon colors, text colors etc. `scaffoldBackgroundColor` sets the background of every `Scaffold` (screen container).

```dart
      colorScheme: ColorScheme.dark(
        surface: AtithyaColors.obsidian,
        primary: AtithyaColors.imperialGold,
        secondary: AtithyaColors.royalMaroon,
        onSurface: AtithyaColors.pearl,
        onPrimary: AtithyaColors.obsidian,
      ),
```
`ColorScheme` is Material's semantic color system. `primary` is the main brand color (gold), `onPrimary` is what appears on top of it (obsidian — so gold buttons get dark text).

```dart
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          ...
        },
      ),
```
Overrides the default screen transition animation. `CupertinoPageTransitionsBuilder` gives a smooth right-to-left slide (iOS style) on all platforms — more premium-feeling than Android's default bottom-up slide.

---

## 20. core/network/api_client.dart

**Role**: Single HTTP client for the entire app. Every API call goes through this one class.

### Why a singleton?

```dart
// Global singleton — created once, reused everywhere
final apiClient = ApiClient();
```
A **singleton** means there is only one instance of `ApiClient` in the entire app. Every provider imports `apiClient` from this file. Benefits:
- Token management in one place
- Easy to mock for testing
- No duplicate header setup

```dart
class ApiClient {
  static const String baseUrl = 'https://atithya-nzqy.onrender.com/api';
```
All API calls use this base URL. Change it once here, all routes update automatically.

```dart
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
```
`_getHeaders()` (note the underscore — private method) reads the JWT from storage and injects it into headers. The `if (token != null) 'Authorization': ...` is Dart's **collection if** — only adds the Authorization header if token exists. This way unauthenticated requests don't send a header at all.

```dart
  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return _processResponse(response);
  }
```
`endpoint` is like `/estates` or `/auth/me`. The full URL becomes `https://atithya-nzqy.onrender.com/api/estates`.

```dart
  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else {
      String message = 'API Error';
      try {
        final errorBody = jsonDecode(response.body);
        message = errorBody['error'] ?? message;
      } catch (_) {}
      throw Exception(message);
    }
  }
```
`_processResponse` handles both success and error cases:
- Status 200–299 → decode JSON and return
- Status 4xx/5xx → decode error message from body, throw `Exception`

The `throw Exception(message)` propagates to the caller's `catch(e)` block. Notice `catch (_) {}` — the `_` ignores the caught exception (we don't care why JSON parsing of the error body failed; we just use the fallback message).

---

## 21. providers/auth_provider.dart

**Role**: Manages the entire authentication lifecycle: OTP flow, JWT persistence, session restoration.

### AuthState

```dart
enum AuthStep { idle, otp, name, authenticated }

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final Map<String, dynamic>? user;
  final String? error;
  final AuthStep step;
  final String? pendingPhone;
  final String? debugOtp;   // returned by backend in dev mode
  final bool isNewUser;
  ...
}
```

`AuthStep` tracks where in the OTP flow the user is:
- `idle` — not started (no phone entered)
- `otp` — OTP sent, waiting for user to enter it
- `name` — new user, needs to enter their name
- `authenticated` — successfully logged in

### AuthNotifier.build()

```dart
@override
AuthState build() {
  _checkInitialAuth();      // async, runs after build returns
  return const AuthState(); // returns immediately (synchronously)
}
```

`build()` must return synchronously. The async work `_checkInitialAuth()` is called but its `await` points are after the function returns. This is fine — when `_checkInitialAuth` completes it updates `state`, which triggers widget rebuilds.

### _checkInitialAuth()

```dart
Future<void> _checkInitialAuth() async {
  await Future.microtask(() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null) {
      try {
        final user = await apiClient.get('/auth/me') as Map<String, dynamic>;
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          step: AuthStep.authenticated,
          user: user,
        );
      } catch (_) {
        // Token expired or invalid → clear it
        await prefs.remove('auth_token');
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
    } else {
      state = state.copyWith(isLoading: false);
    }
  });
}
```

The `Future.microtask` ensures this runs after `build()` returns (so the initial `const AuthState()` is returned first). Then:
1. Read token from `SharedPreferences`
2. If token exists → call `/auth/me` to verify it's still valid
3. If `/auth/me` succeeds → set `isAuthenticated: true` with the user object
4. If `/auth/me` fails (401 expired) → delete the bad token, stay as guest

### Provider Registration

```dart
final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
```

`AuthNotifier.new` is equivalent to `() => AuthNotifier()` — it's a tear-off (function reference to the constructor).

---

## 22. providers/estate_provider.dart

**Role**: Fetches and caches the list of estates from the backend.

```dart
class EstateNotifier extends Notifier<EstateState> {
  @override
  EstateState build() {
    Future.microtask(() => fetchEstates());
    return EstateState(isLoading: true);
  }

  Future<void> fetchEstates({
    String? city,
    String? category,
    int? maxPrice,
    ...
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Build query string from filters
      final params = <String, String>{};
      if (city != null && city.isNotEmpty) params['city'] = city;
      if (category != null) params['category'] = category;
      ...
      final query = params.isNotEmpty
          ? '?' + params.entries
              .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
              .join('&')
          : '';

      final response = await apiClient.get('/estates$query');
      state = state.copyWith(
        isLoading: false,
        estates: response is List ? response : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
```

`Uri.encodeComponent` URL-encodes filter values (e.g., "Heritage Palace" → "Heritage%20Palace") so they're safe to put in URLs.

`response is List ? response : []` guards against the API returning something unexpected — if it's not a List, use an empty list rather than crashing.

---

## 23. providers/booking_provider.dart

**Role**: Fetches the authenticated user's bookings. Auth-gated.

```dart
@override
BookingState build() {
  final isAuthenticated = ref.watch(
    authProvider.select((s) => s.isAuthenticated)
  );
  if (!isAuthenticated) return BookingState();   // empty state for guests
  Future.microtask(() => fetchMyBookings());
  return BookingState(isLoading: true);
}
```

`ref.watch(authProvider.select((s) => s.isAuthenticated))` — watches only the `isAuthenticated` boolean from `authProvider`. When `isAuthenticated` changes from `false` to `true` (user logs in), `build()` re-runs, and `fetchMyBookings()` is now called. When it changes from `true` to `false` (logout), `build()` returns empty `BookingState()` — bookings disappear instantly without needing to manually clear them.

---

## 24. providers/notifications_provider.dart

**Role**: Fetches notification count/list for the authenticated user. Same auth-gating pattern as bookingProvider.

The notification **badge count** on the Sanctum tab is only shown when authenticated:
```dart
// In sanctum_screen.dart:
badge: ref.watch(authProvider).isAuthenticated
    ? ref.watch(notificationsProvider).unreadCount
    : 0,
```
If not authenticated, badge is 0 (no red dot), and `notificationsProvider` never fires an API request.

---

## 25. features/shell/app_shell.dart

**Role**: The main navigation container. Hosts the 4-tab floating bottom nav and `IndexedStack` of screens.

### shellTabProvider

```dart
class _ShellTabNotifier extends Notifier<int> {
  @override
  int build() => 0;      // start on tab 0 (Discover)
  void switchTo(int tab) => state = tab;
}
final shellTabProvider = NotifierProvider<_ShellTabNotifier, int>(_ShellTabNotifier.new);
```
This provider lets any screen switch the visible tab programmatically. For example, after booking confirmation you can call `ref.read(shellTabProvider.notifier).switchTo(3)` to jump to Sanctum (Dossier).

### IndexedStack

```dart
body: IndexedStack(
  index: _currentIndex,
  children: _screens,   // all 4 screens
),
```
`IndexedStack` is like a stack of cards — only the card at `index` is visible, but **all cards exist in memory**. This means:
- Switching tabs is instant (no rebuild)
- Scroll positions are preserved
- Animations that were running keep running

Alternative would be to `switch` between screens — but that discards and recreates each screen on every tab change.

### The Animated Gold Pill

```dart
late AnimationController _moveCtrl;
late Animation<double> _moveAnim;
double _fromFrac = 0.125;
double _toFrac   = 0.125;

static double _fracFor(int i) => (i + 0.5) / 4;
```

The nav has 4 equal slots. Each slot occupies `1/4 = 0.25` of the width. The center of slot 0 is at `0.5/4 = 0.125`, slot 1 at `1.5/4 = 0.375`, etc.

```dart
void _onTabTap(int index) {
  if (index == _currentIndex) return;    // already on this tab
  _fromFrac = _fracFor(_currentIndex);   // where the pill is now
  _toFrac   = _fracFor(index);           // where it's going
  setState(() => _currentIndex = index);
  _moveCtrl.forward(from: 0);            // restart animation
}
```

The pill is then drawn using `AnimatedBuilder` + `lerp` (linear interpolation) between `_fromFrac` and `_toFrac` as `_moveAnim.value` goes 0→1.

### TickerProviderStateMixin

```dart
class _AppShellState extends ConsumerState<AppShell>
    with TickerProviderStateMixin {
```
`TickerProviderStateMixin` (or `SingleTickerProviderStateMixin` for one controller) provides the `vsync` parameter that `AnimationController` needs. `vsync` connects the animation to the display's frame refresh rate — the animation only runs when the widget is visible, preventing battery waste.

---

## 26. features/splash/splash_screen.dart

**Role**: Animated brand intro. Checks auth and routes accordingly.

```
SplashScreen opens
    → plays brand animation (Lottie / video)
    → waits for authProvider.isLoading to become false
    → if isAuthenticated → Navigator.pushReplacement(AppShell)
    → else              → Navigator.pushReplacement(AuthFoyerScreen)
```

Key pattern: The screen **watches** `authProvider`:
```dart
ref.listen(authProvider, (prev, next) {
  if (!next.isLoading) {
    if (next.isAuthenticated) {
      Navigator.pushReplacement(...AppShell...);
    } else {
      Navigator.pushReplacement(...AuthFoyerScreen...);
    }
  }
});
```

`ref.listen` (not `ref.watch`) is used here because we want to **react** to the change with a navigation side-effect, not rebuild the widget tree.

---

## 27. features/auth/auth_foyer_screen.dart

**Role**: Phone OTP authentication. Single screen, multiple "steps" managed by `authProvider`.

### Flow

```
Step 1: Phone input
    → user types phone → tap Send
    → calls authProvider.notifier.sendOTP(phone)
    → shows CircularProgressIndicator while isLoading
    → on success: authProvider.step == AuthStep.otp

Step 2: OTP pin
    → 6 digit inputs shown
    → calls authProvider.notifier.verifyOTP(phone, otp)
    → on success: if newUser → step == AuthStep.name
                  else → step == AuthStep.authenticated

Step 3 (new users only): Name entry
    → calls authProvider.notifier.setName(name)
    → step → AuthStep.authenticated

Step 4: Navigation
    → ref.listen sees isAuthenticated == true
    → Navigator.pushAndRemoveUntil(AppShell)
```

The key pattern of listening to the provider:
```dart
ref.listen(authProvider, (_, next) {
  if (next.isAuthenticated) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShell()),
      (_) => false,    // remove all previous routes (can't go back to auth)
    );
  }
});
```

Error display:
```dart
if (state.error != null)
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      state.error!,
      style: TextStyle(color: AtithyaColors.errorRed),
    ),
  ),
```
`state.error!` — the `!` is the **null assertion operator**. We're inside `if (state.error != null)` so we know it's not null, and `!` tells Dart's type system that too. Without `!` Dart would give a compile error because `error` is `String?` (nullable).

---

## 28. features/discover/discover_screen.dart

**Role**: Home feed — shows featured cities and estates.

This screen reads from the `/api/discover/feed` endpoint:

```json
{
  "cities": [{ "city": "Mumbai", "heroImage": "...", "estateCount": 3 }],
  "featured": [{ "title": "Taj Mahal Palace", "city": "Mumbai", ... }]
}
```

Typical pattern for loading data inside a screen:
```dart
class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  Map<String, dynamic>? _feed;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();              // fetch on init
  }

  Future<void> _loadFeed() async {
    try {
      final data = await apiClient.get('/discover/feed');
      setState(() {
        _feed = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }
}
```

`initState()` is the right place to trigger one-time data fetches for a screen. `setState()` after the fetch triggers a rebuild to show the loaded data.

---

## 29. features/estates/estates_screen.dart

**Role**: Filterable grid of all estates.

```dart
class EstatesScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estateState = ref.watch(estateProvider);
```

Uses `estateProvider` (already loaded in the background since `initState` → `build()` in the notifier). Shows a loading shimmer while `estateState.isLoading`, the grid when loaded.

Filter chips call:
```dart
ref.read(estateProvider.notifier).fetchEstates(city: 'Jodhpur');
```

This re-fetches with the filter applied.

---

## 30. features/booking/booking_flow_screen.dart

**Role**: Multi-step bottom-sheet booking wizard.

```
Step 1 → Select dates (Calendar)
Step 2 → Select room type
Step 3 → Review & Confirm
```

State is local (`setState`) since it's UI-only (no need to share across screens):

```dart
class _BookingFlowState extends State<BookingFlowScreen> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  String? _selectedRoom;
  int _step = 0;

  // Price calculation
  int get _nights => _checkOut!.difference(_checkIn!).inDays;
  int get _total => _nights * widget.estate.roomPrice;
```

On confirm:
```dart
await ref.read(bookingProvider.notifier).createBooking(
  estateId: widget.estateId,
  checkIn: _checkIn!,
  checkOut: _checkOut!,
  roomType: _selectedRoom!,
  totalAmount: _total,
);
```

---

## 31. features/payment/payment_screen.dart

**Role**: Simulates payment (demo mode — no real payment gateway integrated).

Shows a payment form with:
- Total amount (from booking)
- "Pay Now" button
- On tap → `Navigator.push(BookingConfirmationScreen)`

For a real integration, this would use Razorpay/Stripe Flutter SDKs.

---

## 32. features/dossier/dossier_screen.dart

**Role**: My Reservations — lists the user's bookings.

```dart
final bookings = ref.watch(bookingProvider).bookings;
```

Tapping a booking opens `BookingDetailScreen`, which shows full booking info + a "Download Invoice" button → `InvoiceScreen`.

The `reservation_modal.dart` widget inside `dossier/widgets/` is the overlay/sheet that shows booking details.

---

## 33. features/sanctum/sanctum_screen.dart

**Role**: Profile + account hub.

Shows:
- User avatar + name + phone
- Loyalty points
- Notification bell (badge count)
- Shortcut to Dossier
- Edit Profile button (→ `ProfileSheet`)
- Settings

**Auth-gated badge:**
```dart
badge: ref.watch(authProvider).isAuthenticated
    ? ref.watch(notificationsProvider).unreadCount
    : 0,
```
If the user is a guest (`isAuthenticated == false`), the badge count is 0 — no API request is made.

---

## 34. features/concierge/concierge_modal.dart

**Role**: AI chat assistant, powered by Ollama running locally (or on the server).

```
User types message
  → POST /api/concierge/chat { message }
  → Backend proxies to Ollama (smollm2:1.7b model)
  → Returns AI response
  → Displayed as chat bubble
```

The messages are stored in local state (`List<Map> _messages`) — no persistence between sessions (each modal open starts fresh).

```dart
Future<void> _send(String msg) async {
  setState(() {
    _messages.add({'role': 'user', 'text': msg});
    _loading = true;
  });
  try {
    final res = await apiClient.post('/concierge/chat', {'message': msg});
    setState(() {
      _messages.add({'role': 'assistant', 'text': res['reply']});
      _loading = false;
    });
  } catch (e) {
    setState(() {
      _messages.add({'role': 'error', 'text': 'Sorry, concierge unavailable.'});
      _loading = false;
    });
  }
}
```

---

## 35. features/admin/admin_shell.dart

**Role**: Separate navigation shell for admin users. Shown only when `user.role ∈ {admin, phantom}`.

### KPI Dashboard Tab

```dart
class _DashboardTab extends ConsumerWidget {
  // Reads from GET /api/admin/system:
  // { revenue, cancelledRevenue, refundedAmount, topEstatesMonth, monthlyRevenue }
```

**`_KpiCard` widget:**
```dart
class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  // Uses FittedBox on the value Text to prevent overflow
  // childAspectRatio: 0.95 in the GridView prevents vertical clipping
}
```

**`_RevenueBreakdown` widget** — 4 tiles:
1. BOOKING REVENUE (gold) — confirmed earnings
2. FOOD & DINING (purple) — ancillary
3. REFUNDS PAID (teal) — 80% of cancelled bookings
4. CANCEL FEE 20% (green) — retained from cancellations

**`_TopEstates` widget** — ranked list with gold/silver/bronze rank badges.

### _LogoutButton

```dart
class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.logout),
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Logout?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true),  child: const Text('Logout')),
            ],
          ),
        );
        if (confirm == true) {
          await ref.read(authProvider.notifier).logout();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthFoyerScreen()),
            (_) => false,    // remove entire nav stack — can't go back to admin
          );
        }
      },
    );
  }
}
```

`showDialog<bool>` opens a dialog and returns `true` or `false`. The `await` suspends until the user taps a button. `Navigator.pop(context, true)` passes `true` back as the dialog's return value.

---

## 36. backend/server.js

**Role**: The entire backend — Express routes, MongoDB models, JWT auth, AI proxy. ~1900 lines.

### Startup

```js
require('dotenv').config();         // Load .env into process.env
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');   // for OTP generation
const fetch = require('node-fetch'); // for AI proxy
```

`require()` is Node.js's module import. Unlike ES6 `import`, it's synchronous.

### CORS Configuration

```js
const allowedOrigins = [
    'http://localhost:8080',
    'http://localhost:3000',
    'http://127.0.0.1:8080',
    'https://jeevan-04.github.io',
];

app.use(cors({
    origin: (origin, cb) => {
        if (!origin) return cb(null, true);    // curl/Postman have no origin
        if (allowedOrigins.includes(origin)) return cb(null, true);
        if (/^http:\/\/localhost:\d+$/.test(origin)) return cb(null, true);
        cb(null, true);   // allow all (permissive — remove for production)
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
}));
```

CORS (Cross-Origin Resource Sharing) controls which domains can call your API from a browser. Without this, a Flutter web app on `jeevan-04.github.io` would be blocked from calling `atithya-nzqy.onrender.com`.

### JWT Middleware

```js
function authenticateToken(req, res, next) {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // 'Bearer <token>'

    if (!token) return res.status(401).json({ error: 'No token' });

    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ error: 'Invalid token' });
        req.user = user;    // attach { userId, role } to the request
        next();             // proceed to route handler
    });
}
```

`'Bearer <token>'.split(' ')[1]` splits on space and takes the second part — the actual token. `jwt.verify` checks signature + expiry. If valid, it decodes the payload into `user` (which contains `userId` and `role`).

### OTP Routes

```js
app.post('/api/auth/send-otp', async (req, res) => {
    const { phoneNumber } = req.body;
    const otp = crypto.randomInt(100000, 999999).toString(); // 6-digit OTP
    const otpHash = crypto.createHash('sha256').update(otp).digest('hex');
    const expiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    let user = await User.findOne({ phoneNumber });
    const isNewUser = !user;
    if (!user) user = new User({ phoneNumber, role: 'elite' });

    user.otpHash = otpHash;
    user.otpExpiry = expiry;
    await user.save();

    res.json({ isNewUser, debug_otp: otp }); // return OTP in response (dev mode)
});
```

`crypto.randomInt(100000, 999999)` — Node.js crypto module for cryptographically secure random numbers (better than `Math.random()` for security-sensitive values).

`crypto.createHash('sha256').update(otp).digest('hex')` — one-way hash of the OTP stored in DB. If DB is breached, attacker can't reverse the hash to get the OTP.

### Estate Routes

```js
app.get('/api/estates', async (req, res) => {
    const { city, category, maxPrice, minPrice, sort, facilities } = req.query;
    const filter = {};

    if (city) filter.city = city;
    if (category) filter.category = category;
    if (maxPrice || minPrice) {
        filter.basePrice = {};
        if (maxPrice) filter.basePrice.$lte = parseInt(maxPrice);
        if (minPrice) filter.basePrice.$gte = parseInt(minPrice);
    }
    if (facilities) {
        filter.facilities = { $all: facilities.split(',') };
    }

    let query = Estate.find(filter).select('-roomImages'); // exclude large field
    if (sort === 'price_asc') query = query.sort({ basePrice: 1 });
    else if (sort === 'price_desc') query = query.sort({ basePrice: -1 });
    else query = query.sort({ featured: -1, rating: -1 }); // default: featured first

    const estates = await query;
    res.json(estates);
});
```

`$lte` (less than or equal), `$gte` (greater than or equal), `$all` (array contains all) are MongoDB query operators.

`.select('-roomImages')` tells Mongoose to exclude the `roomImages` field from results — it's large (many URLs) and not needed for the list view.

### Admin KPI Route

```js
app.get('/api/admin/system', authenticateToken, requireAdmin, async (req, res) => {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    // Total confirmed revenue
    const revenueResult = await Booking.aggregate([
        { $match: { status: 'confirmed' } },
        { $group: { _id: null, total: { $sum: '$totalAmount' } } }
    ]);

    // Top 5 estates this month by booking count
    const topEstates = await Booking.aggregate([
        { $match: { createdAt: { $gte: startOfMonth }, status: { $in: ['confirmed','pending'] } } },
        { $group: { _id: '$estate', count: { $sum: 1 }, revenue: { $sum: '$totalAmount' } } },
        { $sort: { count: -1 } },
        { $limit: 5 },
        { $lookup: { from: 'estates', localField: '_id', foreignField: '_id', as: 'estateInfo' } },
        { $unwind: '$estateInfo' },
    ]);

    res.json({ revenue, cancelledRevenue, refundedAmount, topEstatesMonth, monthlyRevenue });
});
```

`Booking.aggregate([...])` — MongoDB Aggregation Pipeline: a series of stages that transform documents:
- `$match` — filter (like WHERE in SQL)
- `$group` — group and compute (like GROUP BY + SUM)
- `$sort` — order results
- `$limit` — take top N
- `$lookup` — JOIN with another collection
- `$unwind` — flatten array field into separate documents

### AI Concierge Proxy

```js
app.post('/api/concierge/chat', authenticateToken, async (req, res) => {
    const { message } = req.body;

    const response = await fetch(`${OLLAMA_URL}/api/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            model: AI_MODEL,       // 'smollm2:1.7b'
            prompt: message,
            stream: false,
        }),
    });

    const data = await response.json();
    res.json({ reply: data.response });
});
```

The backend acts as a **proxy** to Ollama. The Flutter app can't call Ollama directly (it's running on the server's localhost). The API receives the message and forwards it to Ollama.

### _patchBadEstateImages()

```js
async function _patchBadEstateImages() {
    const Estate = mongoose.models.Estate;
    const isBad = (u) => !u ||
        u.includes('google.com/url') ||       // Google redirect URLs break
        u.includes('tripadvisor') ||           // different domain = CORS block
        (!u.startsWith('https://images.unsplash.com') &&
         !u.startsWith('https://plus.unsplash.com') &&
         !u.startsWith('https://lh3.googleusercontent.com') && // ← our curated images
         !u.startsWith('data:'));

    const estates = await Estate.find({});
    for (const estate of estates) {
        let modified = false;
        if (isBad(estate.heroImage)) {
            estate.heroImage = randomSafe();   // replace with Unsplash fallback
            modified = true;
        }
        // ... same for images array, panoramaImage ...
        if (modified) await estate.save();
    }
}
```

This runs **every time the server starts**. It's idempotent (safe to run multiple times) — it only changes estates that have bad URLs. This means even if someone inserts a bad URL directly into MongoDB, the next deploy will fix it.

---

## 37. backend/reset_estates.js

**Role**: Standalone script to wipe all estates and re-insert the curated list. Run with `node reset_estates.js`.

```js
// 1. Load environment (for MONGO_URI)
require('dotenv').config();
const mongoose = require('mongoose');

// 2. Redefine the Estate schema inline
//    (don't import server.js — it would start the whole server)
const EstateSchema = new mongoose.Schema({...});
const Estate = mongoose.model('Estate', EstateSchema);

// 3. Curated estates array
const ESTATES = [
  { title: 'Taj Mahal Palace', ... },
  { title: 'Umaid Bhawan Palace', ... },
  // ...
];

// 4. Run function
async function run() {
    await mongoose.connect(process.env.MONGO_URI);
    const del = await Estate.deleteMany({});    // wipe ALL
    const inserted = await Estate.insertMany(ESTATES);
    await mongoose.disconnect();
}

run().catch(e => { console.error(e); process.exit(1); });
```

Why redefine the schema? Because `require('./server.js')` would start the entire Express server (calling `app.listen()`). The reset script only needs the Mongoose model.

`process.exit(1)` — exit with error code 1 (non-zero = failure). The `.catch` ensures any unhandled rejection (network error, bad MONGO_URI etc.) is reported before exit.

---

## 38. backend/models/

### User.js

```js
const UserSchema = new mongoose.Schema({
    name: { type: String, trim: true },                  // trim removes whitespace
    phoneNumber: { type: String, required: true, unique: true, index: true },
    role: {
        type: String,
        enum: ['guest','elite','manager','gate_staff','desk_staff','admin','phantom'],
        default: 'elite'
    },
    otpHash: String,          // hashed OTP (cleared after verify)
    otpExpiry: Date,          // OTP expiry timestamp
    loyaltyPoints: { type: Number, default: 0 },
    notifications: [{
        title: String,
        body: String,
        type: String,
        read: { type: Boolean, default: false },
        createdAt: { type: Date, default: Date.now }
    }],
}, { timestamps: true });    // adds createdAt, updatedAt automatically
```

`index: true` on `phoneNumber` creates a MongoDB index — makes `User.findOne({ phoneNumber })` instant even with millions of users (without index, it scans every document).

`unique: true` prevents two users having the same phone number at the database level.

### Booking.js

```js
const BookingSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    estate: { type: mongoose.Schema.Types.ObjectId, ref: 'Estate', required: true },
    checkIn: { type: Date, required: true },
    checkOut: { type: Date, required: true },
    guests: { type: Number, default: 1 },
    roomType: String,
    totalAmount: { type: Number, required: true },
    status: {
        type: String,
        enum: ['pending','confirmed','cancelled','refunded'],
        default: 'pending'
    },
    invoiceNumber: String,
    cancelledAt: Date,
    refundAmount: Number,
}, { timestamps: true });
```

`ref: 'User'` enables `Booking.populate('user')` — Mongoose can replace the ObjectId with the actual User document automatically. Similarly `ref: 'Estate'` for the estate field.

`invoiceNumber` is generated by the server when the booking is created: `ATH-YYYYMMDD-XXXXXX` where XXXXXX is a random 6-char hex.

---

## Summary: How it all connects

Here is the complete chronological flow from "user opens the browser" to "user sees estate listings":

```
1. Browser loads GitHub Pages
   → Downloads Flutter web app (main.dart.js)

2. Flutter engine starts
   → main() runs
   → WidgetsFlutterBinding.ensureInitialized()
   → runApp(ProviderScope(child: AtithyaApp()))

3. AtithyaApp widget builds
   → MaterialApp with AtithyaTheme and SplashScreen as home

4. SplashScreen builds
   → Plays brand animation
   → Watches authProvider

5. authProvider.build() runs (triggered by first ref.watch)
   → _checkInitialAuth() deferred via Future.microtask
   → State = AuthState(isLoading: true)

6. _checkInitialAuth() runs
   → SharedPreferences.getString('auth_token') → null (first time)
   → State = AuthState(isLoading: false, isAuthenticated: false)

7. SplashScreen sees isLoading: false, isAuthenticated: false
   → Navigator.pushReplacement(AuthFoyerScreen)

8. User enters phone → taps Send
   → authProvider.notifier.sendOTP('9876543210')
   → ApiClient.post('/auth/send-otp') → Render API
   → API creates user, generates OTP, returns { debug_otp: '491823' }
   → State = AuthState(step: otp, pendingPhone: '9876543210', debugOtp: '491823')

9. User enters OTP
   → authProvider.notifier.verifyOTP('9876543210', '491823')
   → ApiClient.post('/auth/verify-otp') → API
   → API verifies hash, returns JWT + user object
   → SharedPreferences.setString('auth_token', 'eyJ...')
   → State = AuthState(isAuthenticated: true, user: {...})

10. AuthFoyerScreen.ref.listen sees isAuthenticated: true
    → Navigator.pushAndRemoveUntil(AppShell)

11. AppShell builds
    → IndexedStack with 4 screens, current index 0 (DiscoverScreen)
    → shellTabProvider = 0

12. DiscoverScreen builds
    → initState() → _loadFeed() → apiClient.get('/discover/feed')
    → setState when loaded → renders city cards + featured estates

13. Meanwhile bookingProvider.build() runs
    → ref.watch(authProvider.select(s => s.isAuthenticated)) == true
    → Future.microtask(fetchMyBookings)
    → apiClient.get('/bookings') → returns user's past bookings

14. notificationsProvider.build() runs (same pattern)
    → fetchNotifications() → returns unread count
    → SanctumScreen badge shows the count
```

Every step is reactive. When state changes in a provider, every widget that `ref.watch`-es that provider automatically rebuilds — no manual `notifyListeners()`, no `setState` calls across files, no spaghetti event buses.

---

*© 2025–2026 Jeevan Naidu. All rights reserved.*
