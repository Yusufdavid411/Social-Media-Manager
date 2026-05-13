import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseStatus = await FirebaseBootstrap.initialize();
  runApp(SocialMediaManagerApp(firebaseStatus: firebaseStatus));
}

class FirebaseBootstrap {
  const FirebaseBootstrap({required this.isReady, this.error});

  final bool isReady;
  final Object? error;

  static Future<FirebaseBootstrap> initialize() async {
    try {
      await Firebase.initializeApp();
      return const FirebaseBootstrap(isReady: true);
    } catch (error) {
      return FirebaseBootstrap(isReady: false, error: error);
    }
  }
}

class SocialMediaManagerApp extends StatelessWidget {
  const SocialMediaManagerApp({super.key, required this.firebaseStatus});

  final FirebaseBootstrap firebaseStatus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1778F2),
      primary: const Color(0xFF1877F2),
      secondary: const Color(0xFFE1306C),
      surface: const Color(0xFFF7F8FA),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Social Media Manager',
      scaffoldMessengerKey: AppMessenger.key,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          backgroundColor: Color(0xFFF7F8FA),
          foregroundColor: Color(0xFF101828),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE4E7EC)),
          ),
          margin: EdgeInsets.zero,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1877F2), width: 1.5),
          ),
        ),
      ),
      home: AuthGate(firebaseStatus: firebaseStatus),
    );
  }
}

class AppMessenger {
  static final key = GlobalKey<ScaffoldMessengerState>();

  static void show(String message, {SnackBarKind kind = SnackBarKind.info}) {
    final messenger = key.currentState;
    if (messenger == null) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: switch (kind) {
            SnackBarKind.success => const Color(0xFF047857),
            SnackBarKind.error => const Color(0xFFB42318),
            SnackBarKind.info => const Color(0xFF344054),
          },
        ),
      );
  }
}

enum SnackBarKind { success, error, info }

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.firebaseStatus});

  final FirebaseBootstrap firebaseStatus;

  @override
  Widget build(BuildContext context) {
    if (!firebaseStatus.isReady) {
      return LoginScreen(
        firebaseReady: false,
        firebaseError: firebaseStatus.error,
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen(firebaseReady: true);
        }
        return AppShell(uid: user.uid, firebaseReady: true);
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hub_rounded, size: 48, color: Color(0xFF1877F2)),
              SizedBox(height: 16),
              Text(
                'Social Media Manager',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.firebaseReady,
    this.firebaseError,
  });

  final bool firebaseReady;
  final Object? firebaseError;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!widget.firebaseReady) {
      AppMessenger.show(
        'Add Firebase Android config to enable login.',
        kind: SnackBarKind.info,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
    } on FirebaseAuthException catch (error) {
      AppMessenger.show(
        error.message ?? 'Unable to log in.',
        kind: SnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      title: 'Welcome back',
      subtitle: 'Manage real posts, schedules, and account connections.',
      firebaseReady: widget.firebaseReady,
      firebaseError: widget.firebaseError,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Log in'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    RegisterScreen(firebaseReady: widget.firebaseReady),
              ),
            ),
            child: const Text('Create account'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    ForgotPasswordScreen(firebaseReady: widget.firebaseReady),
              ),
            ),
            child: const Text('Forgot password?'),
          ),
          if (!widget.firebaseReady && kDebugMode) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => const AppShell(
                    uid: 'debug-preview',
                    firebaseReady: false,
                  ),
                ),
              ),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Preview empty app shell'),
            ),
          ],
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!widget.firebaseReady) {
      AppMessenger.show(
        'Firebase config is required before registration.',
        kind: SnackBarKind.info,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _email.text.trim(),
            password: _password.text,
          );
      final user = credential.user;
      if (user != null) {
        await user.updateDisplayName(_name.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'displayName': _name.text.trim(),
          'email': _email.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'onboardingCompleted': false,
        });
      }
    } on FirebaseAuthException catch (error) {
      AppMessenger.show(
        error.message ?? 'Unable to create account.',
        kind: SnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      title: 'Create account',
      subtitle: 'Start by setting up a real Firebase-backed profile.',
      firebaseReady: widget.firebaseReady,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _isLoading ? null : _register,
            child: _isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Register'),
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!widget.firebaseReady) {
      AppMessenger.show(
        'Firebase config is required before password reset.',
        kind: SnackBarKind.info,
      );
      return;
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: _email.text.trim(),
    );
    AppMessenger.show('Password reset email sent.', kind: SnackBarKind.success);
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      title: 'Reset password',
      subtitle: 'Enter your email to receive a reset link.',
      firebaseReady: widget.firebaseReady,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _sendReset,
            child: const Text('Send reset link'),
          ),
        ],
      ),
    );
  }
}

class AuthFrame extends StatelessWidget {
  const AuthFrame({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.firebaseReady,
    this.firebaseError,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool firebaseReady;
  final Object? firebaseError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.hub_rounded,
                      size: 48,
                      color: Color(0xFF1877F2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Social Media Manager',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF101828),
                          ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF101828),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF667085)),
                    ),
                    if (!firebaseReady) ...[
                      const SizedBox(height: 16),
                      SetupNotice(error: firebaseError),
                    ],
                    const SizedBox(height: 24),
                    child,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SetupNotice extends StatelessWidget {
  const SetupNotice({super.key, this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFEC84B)),
      ),
      child: Text(
        'Firebase Android config is not active yet. Add google-services.json and run FlutterFire configuration to enable auth and Firestore.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7A4E00)),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.uid, required this.firebaseReady});

  final String uid;
  final bool firebaseReady;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        uid: widget.uid,
        firebaseReady: widget.firebaseReady,
        onCompose: () => setState(() => _index = 1),
      ),
      ComposeScreen(uid: widget.uid, firebaseReady: widget.firebaseReady),
      CalendarScreen(uid: widget.uid, firebaseReady: widget.firebaseReady),
      AnalyticsScreen(uid: widget.uid, firebaseReady: widget.firebaseReady),
      SettingsScreen(uid: widget.uid, firebaseReady: widget.firebaseReady),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Compose',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.uid,
    required this.firebaseReady,
    required this.onCompose,
  });

  final String uid;
  final bool firebaseReady;
  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Home',
      actions: [
        IconButton(
          tooltip: 'New post',
          onPressed: onCompose,
          icon: const Icon(Icons.add_box_outlined),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WelcomeHeader(onCompose: onCompose),
          const SizedBox(height: 16),
          ConnectedAccountsSummary(uid: uid, firebaseReady: firebaseReady),
          const SizedBox(height: 16),
          PostCounts(uid: uid, firebaseReady: firebaseReady),
          const SizedBox(height: 16),
          SectionHeader(title: 'Upcoming'),
          const SizedBox(height: 8),
          ScheduledPostsList(uid: uid, firebaseReady: firebaseReady),
          const SizedBox(height: 16),
          SectionHeader(title: 'Recent posts'),
          const SizedBox(height: 8),
          RecentPostsList(uid: uid, firebaseReady: firebaseReady),
        ],
      ),
    );
  }
}

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key, required this.onCompose});

  final VoidCallback onCompose;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ready to publish?',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'Connect Facebook and Instagram, then create your first real post.',
              style: TextStyle(color: Color(0xFF667085)),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onCompose,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('New post'),
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectedAccountsSummary extends StatelessWidget {
  const ConnectedAccountsSummary({
    super.key,
    required this.uid,
    required this.firebaseReady,
  });

  final String uid;
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return const EmptyState(
        message: 'Connect Facebook or Instagram to start publishing.',
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('socialAccounts')
          .snapshots(),
      builder: (context, snapshot) {
        final accounts = snapshot.data?.docs ?? [];
        if (accounts.isEmpty) {
          return const EmptyState(message: 'No connected accounts yet.');
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: accounts.map((doc) {
                final data = doc.data();
                return Chip(
                  avatar: Icon(
                    platformIcon(data['platform'] as String? ?? ''),
                    size: 18,
                  ),
                  label: Text(
                    data['displayName'] as String? ?? doc.id,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

class PostCounts extends StatelessWidget {
  const PostCounts({super.key, required this.uid, required this.firebaseReady});

  final String uid;
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return const CountGrid(
        counts: {'Posts': 0, 'Drafts': 0, 'Scheduled': 0, 'Failed': 0},
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('posts')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final counts = {
          'Posts': docs.length,
          'Drafts': docs.where((doc) => doc.data()['status'] == 'draft').length,
          'Scheduled': docs
              .where((doc) => doc.data()['status'] == 'scheduled')
              .length,
          'Failed': docs
              .where((doc) => doc.data()['status'] == 'failed')
              .length,
        };
        return CountGrid(counts: counts);
      },
    );
  }
}

class CountGrid extends StatelessWidget {
  const CountGrid({super.key, required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 2.3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: counts.entries.map((entry) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.value.toString(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  entry.key,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF667085)),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ScheduledPostsList extends StatelessWidget {
  const ScheduledPostsList({
    super.key,
    required this.uid,
    required this.firebaseReady,
  });

  final String uid;
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return const EmptyState(message: 'No scheduled posts yet.');
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('posts')
          .where('status', isEqualTo: 'scheduled')
          .orderBy('scheduledAt')
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const EmptyState(message: 'No scheduled posts yet.');
        }
        return Column(
          children: docs.map((doc) => PostTile(data: doc.data())).toList(),
        );
      },
    );
  }
}

class RecentPostsList extends StatelessWidget {
  const RecentPostsList({
    super.key,
    required this.uid,
    required this.firebaseReady,
  });

  final String uid;
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) {
      return const EmptyState(message: 'No posts yet. Create your first post.');
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const EmptyState(
            message: 'No posts yet. Create your first post.',
          );
        }
        return Column(
          children: docs.map((doc) => PostTile(data: doc.data())).toList(),
        );
      },
    );
  }
}

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({
    super.key,
    required this.uid,
    required this.firebaseReady,
  });

  final String uid;
  final bool firebaseReady;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _caption = TextEditingController();
  final Set<String> _platforms = {'facebook'};
  XFile? _image;
  DateTime? _scheduledAt;
  bool _isSaving = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _image = picked);
  }

  Future<void> _chooseSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now,
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null) return;
    setState(
      () => _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save(String status) async {
    if (_caption.text.trim().isEmpty && _image == null) {
      AppMessenger.show(
        'Add a caption or image first.',
        kind: SnackBarKind.info,
      );
      return;
    }
    if (!widget.firebaseReady) {
      AppMessenger.show(
        'Firebase config is required before saving posts.',
        kind: SnackBarKind.info,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .collection('posts')
          .add({
            'userId': widget.uid,
            'caption': _caption.text.trim(),
            'platforms': _platforms.toList(),
            'imageUrl': null,
            'imagePublicId': null,
            'mediaProvider': _image == null ? null : 'pending_cloudinary',
            'mediaStatus': _image == null ? 'none' : 'local_selected',
            'status': status,
            'approvalStatus': 'not_required',
            'publishStatus': status == 'published' ? 'pending' : 'not_started',
            'scheduledAt': _scheduledAt == null
                ? null
                : Timestamp.fromDate(_scheduledAt!),
            'publishedAt': null,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'errorMessage': null,
            'facebookPostId': null,
            'instagramMediaId': null,
            'instagramPublishId': null,
          });
      _caption.clear();
      setState(() {
        _image = null;
        _scheduledAt = null;
      });
      AppMessenger.show('Post saved.', kind: SnackBarKind.success);
    } catch (error) {
      AppMessenger.show('Unable to save post.', kind: SnackBarKind.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleLabel = _scheduledAt == null
        ? 'Schedule date/time'
        : DateFormat('MMM d, h:mm a').format(_scheduledAt!);
    return AppPage(
      title: 'Compose',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _caption,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Caption',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(title: 'Platforms'),
          const SizedBox(height: 8),
          PlatformSelector(
            selected: _platforms,
            onChanged: (next) => setState(
              () => _platforms
                ..clear()
                ..addAll(next),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image_outlined),
            label: Text(_image == null ? 'Pick image' : 'Change image'),
          ),
          if (_image != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_image!.path),
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _chooseSchedule,
            icon: const Icon(Icons.schedule_outlined),
            label: Text(scheduleLabel),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _isSaving ? null : () => _save('scheduled'),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Schedule post'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isSaving ? null : () => _save('draft'),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save draft'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isSaving ? null : () => _save('queued'),
            icon: const Icon(Icons.publish_outlined),
            label: const Text('Publish now'),
          ),
        ],
      ),
    );
  }
}

class PlatformSelector extends StatelessWidget {
  const PlatformSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  static const platforms = [
    ('facebook', 'Facebook', true),
    ('instagram', 'Instagram', true),
    ('linkedin', 'LinkedIn', false),
    ('x', 'X', false),
    ('tiktok', 'TikTok', false),
    ('youtube', 'YouTube', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: platforms.map((platform) {
        final (id, label, active) = platform;
        return FilterChip(
          avatar: Icon(platformIcon(id), size: 18),
          label: Text(active ? label : '$label soon'),
          selected: selected.contains(id),
          onSelected: active
              ? (value) {
                  final next = {...selected};
                  value ? next.add(id) : next.remove(id);
                  onChanged(next);
                }
              : null,
        );
      }).toList(),
    );
  }
}

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({
    super.key,
    required this.uid,
    required this.firebaseReady,
  });

  final String uid;
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Calendar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: 'Scheduled posts'),
          const SizedBox(height: 8),
          ScheduledPostsList(uid: uid, firebaseReady: firebaseReady),
        ],
      ),
    );
  }
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({
    super.key,
    required this.uid,
    required this.firebaseReady,
  });

  final String uid;
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Analytics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PostCounts(uid: uid, firebaseReady: firebaseReady),
          const SizedBox(height: 16),
          const EmptyState(
            message:
                'No published post analytics yet. Real Meta insights will appear after publishing is connected.',
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.uid,
    required this.firebaseReady,
  });

  final String uid;
  final bool firebaseReady;

  Future<void> _logout() async {
    if (firebaseReady) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: 'Connected accounts'),
          const SizedBox(height: 8),
          const AccountConnectionCard(
            platform: 'facebook',
            title: 'Facebook',
            active: true,
          ),
          const SizedBox(height: 8),
          const AccountConnectionCard(
            platform: 'instagram',
            title: 'Instagram',
            active: true,
          ),
          const SizedBox(height: 8),
          const AccountConnectionCard(
            platform: 'linkedin',
            title: 'LinkedIn',
            active: false,
          ),
          const SizedBox(height: 16),
          if (kDebugMode) DevStatusCard(uid: uid, firebaseReady: firebaseReady),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class AccountConnectionCard extends StatelessWidget {
  const AccountConnectionCard({
    super.key,
    required this.platform,
    required this.title,
    required this.active,
  });

  final String platform;
  final String title;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          platformIcon(platform),
          color: active
              ? Theme.of(context).colorScheme.primary
              : const Color(0xFF98A2B3),
        ),
        title: Text(title, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          active ? 'Connection flow pending Meta OAuth setup' : 'Coming soon',
        ),
        trailing: IconButton(
          tooltip: active ? 'Connect' : 'Coming soon',
          onPressed: active
              ? () => AppMessenger.show(
                  'Meta OAuth backend is next.',
                  kind: SnackBarKind.info,
                )
              : null,
          icon: const Icon(Icons.link_outlined),
        ),
      ),
    );
  }
}

class DevStatusCard extends StatelessWidget {
  const DevStatusCard({
    super.key,
    required this.uid,
    required this.firebaseReady,
  });

  final String uid;
  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dev status',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            StatusRow(
              label: 'Firebase',
              value: firebaseReady ? 'Connected' : 'Needs config',
            ),
            StatusRow(label: 'Auth user ID', value: uid),
            const StatusRow(
              label: 'Firestore',
              value: 'Ready after Firebase config',
            ),
            const StatusRow(label: 'Cloudinary', value: 'Pending'),
            const StatusRow(label: 'Meta config', value: 'Pending'),
            const StatusRow(label: 'Facebook', value: 'Pending'),
            const StatusRow(label: 'Instagram', value: 'Pending'),
          ],
        ),
      ),
    );
  }
}

class StatusRow extends StatelessWidget {
  const StatusRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF667085)),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: child,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.inbox_outlined, color: Color(0xFF667085)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFF667085)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostTile extends StatelessWidget {
  const PostTile({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final platforms = (data['platforms'] as List<dynamic>? ?? [])
        .cast<String>();
    final scheduledAt = data['scheduledAt'];
    final date = scheduledAt is Timestamp
        ? DateFormat('MMM d, h:mm a').format(scheduledAt.toDate())
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFEAF2FF),
            child: Icon(
              platforms.isEmpty ? Icons.public : platformIcon(platforms.first),
              color: const Color(0xFF1877F2),
            ),
          ),
          title: Text(
            data['caption'] as String? ?? 'Untitled post',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [data['status'] as String? ?? 'draft', ?date].join(' • '),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

IconData platformIcon(String platform) {
  return switch (platform.toLowerCase()) {
    'facebook' => Icons.facebook,
    'instagram' => Icons.camera_alt_outlined,
    'linkedin' => Icons.business_center_outlined,
    'x' || 'twitter' => Icons.alternate_email,
    'tiktok' => Icons.music_note_outlined,
    'youtube' => Icons.play_circle_outline,
    _ => Icons.public,
  };
}
