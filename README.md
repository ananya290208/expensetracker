# Expense Tracker App

A full-stack Flutter application featuring real-time expense management, secure **Firebase Email/Password Authentication**, persistent session tracking, and direct deployment to **Firebase Hosting**.

* **Live Web App**: [https://expensetracker-65999.web.app](https://expensetracker-65999.web.app)
* **GitHub Repository**: [https://github.com/ananya290208/expensetracker](https://github.com/ananya290208/expensetracker)
* **Firebase Project ID**: `expensetracker-65999`

---

## Architecture Overview

```
lib/
├── firebase_options.dart         # Generated multiplatform Firebase credentials
├── main.dart                     # App entry point, HomeScreen (Dashboard) & AddExpenseScreen
├── screens/
│   ├── auth_gate.dart            # Root stream listener routing based on auth state
│   └── auth_screen.dart          # Email/Password Login & Registration UI
└── services/
    └── auth_service.dart         # Firebase Authentication wrapper & error resolution
```

---

## Detailed Function-by-Function Explanation

### 1. `lib/main.dart` (Application Entry & Core Feature)

#### App Entry & Setup
* **`void main() async`**:
  * Calls `WidgetsFlutterBinding.ensureInitialized()` to ensure native Flutter engine bindings are established before invoking asynchronous Firebase platform channels.
  * Calls `Firebase.initializeApp(...)` using `DefaultFirebaseOptions.currentPlatform` to initialize the connection to Firebase.
  * Calls `runApp(MyApp())` to launch the Flutter widget tree.
* **`MyApp.build(BuildContext context)`**:
  * Instantiates the root `MaterialApp`.
  * Configures the application title (`Expense Tracker`) and Material 3 theme (`ColorScheme.fromSeed`).
  * Sets the root `home` to `AuthGate(authenticatedHome: HomeScreen())`, delegating screen routing to the auth state listener.

#### Data Models
* **`Expense(this.title, this.amount, this.category)`**:
  * A lightweight Dart data class that holds individual expense attributes: `title` (String), `amount` (double), and `category` (String).

#### `HomeScreen` (Main Expense Dashboard)
* **`initState()`**:
  * A lifecycle method called once when the screen is inserted into the widget tree. Triggers `loadExpenses()` to seed the list.
* **`loadExpenses() async`**:
  * Simulates fetching expense data from a backend with a 2-second delay (`Future.delayed`).
  * Populates initial expenses (`Groceries`, `Uber`, `Electricity Bill`), sets `isLoading = false`, and triggers `updateTotal()`.
* **`updateTotal()`**:
  * Iterates over `expenses`, calculates the sum of all expense amounts, and pushes the new total into `totalController.add(total)`.
* **`addExpense(Expense expense)`**:
  * Receives a new `Expense` object from `AddExpenseScreen`, appends it to `expenses`, calls `setState()`, and calls `updateTotal()` to push the new sum to listeners.
* **`deleteExpense(int index)`**:
  * Removes an expense at the specified index from `expenses`, calls `setState()`, and calls `updateTotal()` to recalculate the running total.
* **`goToAddExpenseScreen() async`**:
  * Navigates to `AddExpenseScreen` via `Navigator.push`.
  * Awaits the newly created `Expense` and, if not null, forwards it to `addExpense()`.
* **`_logout() async`**:
  * Displays a confirmation dialog (`AlertDialog`) asking the user to confirm logging out.
  * If confirmed, executes `FirebaseAuth.instance.signOut()`.
  * Invalidates local session tokens and triggers `AuthGate` to redirect back to `AuthScreen`.
* **`dispose()`**:
  * Closes `totalController` (`totalController.close()`) to avoid memory leaks.
* **`build(BuildContext context)`**:
  * Renders the dashboard UI:
    * **AppBar**: Contains the title, a chip displaying the authenticated user's email, and the Logout icon button.
    * **Total Card**: Listens to `totalController.stream` via `StreamBuilder<double>` to reactively display the total spent in ₹.
    * **ListView**: Builds scrollable `ListTile` items for each expense with delete buttons.
    * **FloatingActionButton**: Floating button that triggers `goToAddExpenseScreen()`.

#### `AddExpenseScreen` (Add Expense Form)
* **`dispose()`**:
  * Cleans up `titleController` and `amountController` when the widget is disposed.
* **`saveExpense()`**:
  * Validates that title and amount inputs are non-empty and that amount is a valid numerical value.
  * Constructs a new `Expense(title, amount, selectedCategory)` and pops the screen (`Navigator.pop(context, newExpense)`).
* **`build(BuildContext context)`**:
  * Displays text fields for `ExpTitle` and `Amount`, a category dropdown menu (`Food`, `Transport`, `Shopping`, `Bills`, `Entertainment`, `Other`), and a Save button.

---

### 2. `lib/screens/auth_gate.dart` (Session Monitor & Root Router)

* **`AuthGate({super.key, required this.authenticatedHome})`**:
  * Constructor that accepts the destination widget to render when the user is logged in.
* **`build(BuildContext context)`**:
  * Uses a `StreamBuilder<User?>` listening to `FirebaseAuth.instance.authStateChanges()`.
  * **Persistent Sessions**: Firebase securely persists tokens on local storage (EncryptedSharedPreferences on Android, IndexedDB on Web).
  * **Seamless Launches**:
    * While checking saved credentials (`ConnectionState.waiting`), displays a loading indicator.
    * If a valid token exists (`snapshot.hasData`), bypasses login and loads `authenticatedHome` (`HomeScreen`).
    * If unauthenticated or after logout, displays `AuthScreen`.

---

### 3. `lib/screens/auth_screen.dart` (Login & Registration UI)

* **`_toggleAuthMode()`**:
  * Swaps the interface state between **Sign In** and **Create Account** (`_isLogin = !_isLogin`), clearing form fields and error banners.
* **`_submit() async`**:
  * Validates form inputs via `_formKey.currentState!.validate()`.
  * Sets `_isLoading = true` to display progress spinners.
  * Calls `_authService.signInWithEmailAndPassword(...)` when in login mode, or `_authService.createUserWithEmailAndPassword(...)` when registering.
  * Catches any errors, saves the error message to state, and displays a floating red `SnackBar`.
  * Does not require manual navigation because `AuthGate` automatically detects the new auth state.
* **`dispose()`**:
  * Disposes `_emailController`, `_passwordController`, and `_confirmPasswordController`.
* **`build(BuildContext context)`**:
  * Renders a responsive, centered login/registration card:
    * App icon and title banner.
    * Email field with regex format validation.
    * Password field with minimum 6-character validation and show/hide visibility toggle.
    * Confirm Password field (rendered only in registration mode) ensuring both passwords match.
    * Submit button (`ElevatedButton`) with an animated `CircularProgressIndicator` during submission.
    * Toggle button switching between "Sign In" and "Sign Up".

---

### 4. `lib/services/auth_service.dart` (Firebase Authentication Service)

* **`AuthService({FirebaseAuth? auth})`**:
  * Constructor accepting an optional `FirebaseAuth` instance for dependency injection and testing. Defaults to `FirebaseAuth.instance`.
* **`Stream<User?> get authStateChanges`**:
  * Exposes the Firebase auth state stream. Emits a `User` object when logged in, or `null` when logged out.
* **`User? get currentUser`**:
  * Returns the currently authenticated `User`, or `null` if unauthenticated.
* **`signInWithEmailAndPassword({required String email, required String password}) async`**:
  * Authenticates an existing user using their email and password.
  * Catches `FirebaseAuthException` and re-throws a clean, user-friendly error string via `_getReadableErrorMessage`.
* **`createUserWithEmailAndPassword({required String email, required String password}) async`**:
  * Creates and registers a new Firebase user account with email and password.
  * Automatically signs the user in upon successful creation.
* **`signOut() async`**:
  * Executes `_auth.signOut()`, invalidating local session tokens and notifying the `authStateChanges` stream.
* **`_getReadableErrorMessage(FirebaseAuthException e)`**:
  * Translates Firebase error codes into readable messages:
    * `user-not-found`: "No user found with this email address."
    * `wrong-password`: "Incorrect password. Please try again."
    * `invalid-credential`: "Invalid email or password credentials."
    * `email-already-in-use`: "An account already exists for this email."
    * `weak-password`: "The password is too weak. Please use at least 6 characters."
    * `invalid-email`: "The email address format is invalid."
    * `network-request-failed`: "Network connection error. Please check your internet connection."

---

### 5. `lib/firebase_options.dart` (Firebase Configuration)

* **`DefaultFirebaseOptions.currentPlatform`**:
  * Evaluates current execution platform (`kIsWeb`, `TargetPlatform.android`, `TargetPlatform.iOS`).
  * Returns the appropriate `FirebaseOptions` object containing API key, App ID, Project ID (`expensetracker-65999`), and storage bucket.

---

## How to Run

### 1. Web Application (Local)
```bash
flutter run -d chrome
```

### 2. Android Device / Emulator
Make sure an Android device is plugged in with USB debugging enabled, or an emulator is running:
```bash
flutter run
```

### 3. Build Standalone Android APK
```bash
flutter build apk --release
```
The output APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## Deploy to Firebase Hosting

To deploy updates to the live web application:
```bash
flutter build web --release
firebase deploy --only hosting
```
Live URL: [https://expensetracker-65999.web.app](https://expensetracker-65999.web.app)


Demo: 

https://github.com/user-attachments/assets/11dc3bc0-54dc-45bc-bdc6-8f4d4afcfa80

