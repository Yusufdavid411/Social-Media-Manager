import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const SocialMediaManagerApp());
}

class SocialMediaManagerApp extends StatefulWidget {
  const SocialMediaManagerApp({super.key});

  @override
  State<SocialMediaManagerApp> createState() => _SocialMediaManagerAppState();
}

class _SocialMediaManagerAppState extends State<SocialMediaManagerApp> {
  AppSession? _session;

  void _startSession(AppSession session) {
    setState(() => _session = session);
  }

  void _endSession() {
    setState(() => _session = null);
  }

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
      home: _session == null
          ? LoginScreen(onAuthenticated: _startSession)
          : AppShell(session: _session!, onLogout: _endSession),
    );
  }
}

class AppSession {
  const AppSession({
    required this.userId,
    required this.email,
    required this.workspaceId,
    required this.workspaceName,
  });

  final String userId;
  final String email;
  final String workspaceId;
  final String workspaceName;
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onAuthenticated});

  final ValueChanged<AppSession> onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _previewLogin() {
    widget.onAuthenticated(
      AppSession(
        userId: 'api-preview-user',
        email: _email.text.trim().isEmpty
            ? 'preview@socialmanager.local'
            : _email.text.trim(),
        workspaceId: 'api-preview-workspace',
        workspaceName: 'Personal Workspace',
      ),
    );
    AppMessenger.show(
      'Preview session started. API auth wiring is next.',
      kind: SnackBarKind.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      title: 'Welcome back',
      subtitle: 'The mobile app is ready for the NestJS API auth connection.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BackendNotice(),
          const SizedBox(height: 16),
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
          FilledButton(onPressed: _previewLogin, child: const Text('Log in')),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    RegisterScreen(onAuthenticated: widget.onAuthenticated),
              ),
            ),
            child: const Text('Create account'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ForgotPasswordScreen(),
              ),
            ),
            child: const Text('Forgot password?'),
          ),
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onAuthenticated});

  final ValueChanged<AppSession> onAuthenticated;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _previewRegister() {
    widget.onAuthenticated(
      AppSession(
        userId: 'api-preview-user',
        email: _email.text.trim().isEmpty
            ? 'preview@socialmanager.local'
            : _email.text.trim(),
        workspaceId: 'api-preview-workspace',
        workspaceName: 'Personal Workspace',
      ),
    );
    Navigator.of(context).pop();
    AppMessenger.show(
      'Preview account opened. Real registration will call the NestJS API.',
      kind: SnackBarKind.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      title: 'Create account',
      subtitle: 'Next we will connect this form to PostgreSQL-backed auth.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BackendNotice(),
          const SizedBox(height: 16),
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
            onPressed: _previewRegister,
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      title: 'Reset password',
      subtitle: 'Password reset will be added to the NestJS auth module.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BackendNotice(),
          const SizedBox(height: 16),
          const TextField(
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => AppMessenger.show(
              'Password reset API is coming after auth tokens.',
              kind: SnackBarKind.info,
            ),
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
  });

  final String title;
  final String subtitle;
  final Widget child;

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

class BackendNotice extends StatelessWidget {
  const BackendNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFB2CCFF)),
      ),
      child: Text(
        'Firebase has been removed from the mobile app. These screens are ready to connect to the NestJS/PostgreSQL API.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: const Color(0xFF1849A9)),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.session, required this.onLogout});

  final AppSession session;
  final VoidCallback onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  final List<PostPreview> _posts = [];
  bool _connectPromptDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showConnectPrompt());
  }

  void _showConnectPrompt() {
    if (_connectPromptDismissed || !mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Connect social accounts'),
          content: const Text(
            'Connect Facebook or Instagram to start publishing real posts. You can also skip this for now.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                _connectPromptDismissed = true;
                Navigator.of(context).pop();
              },
              child: const Text('Skip'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _index = 4);
              },
              child: const Text('Connect'),
            ),
          ],
        );
      },
    );
  }

  void _addPost(PostPreview post) {
    setState(() => _posts.insert(0, post));
    AppMessenger.show(
      'Post saved locally for preview.',
      kind: SnackBarKind.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        session: widget.session,
        posts: _posts,
        onCompose: () => setState(() => _index = 1),
      ),
      ComposeScreen(onSave: _addPost),
      CalendarScreen(posts: _posts),
      AnalyticsScreen(posts: _posts),
      SettingsScreen(session: widget.session, onLogout: widget.onLogout),
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

class PostPreview {
  const PostPreview({
    required this.caption,
    required this.platforms,
    required this.status,
    this.imagePath,
    this.scheduledAt,
  });

  final String caption;
  final List<String> platforms;
  final String status;
  final String? imagePath;
  final DateTime? scheduledAt;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.session,
    required this.posts,
    required this.onCompose,
  });

  final AppSession session;
  final List<PostPreview> posts;
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
          WelcomeHeader(session: session, onCompose: onCompose),
          const SizedBox(height: 16),
          const EmptyState(
            message:
                'No connected accounts yet. Connect Facebook or Instagram to start publishing.',
          ),
          const SizedBox(height: 16),
          CountGrid(
            counts: {
              'Posts': posts.length,
              'Drafts': posts.where((post) => post.status == 'draft').length,
              'Scheduled': posts
                  .where((post) => post.status == 'scheduled')
                  .length,
              'Failed': posts.where((post) => post.status == 'failed').length,
            },
          ),
          const SizedBox(height: 16),
          SectionHeader(title: 'Upcoming'),
          const SizedBox(height: 8),
          PostList(
            posts: posts.where((post) => post.status == 'scheduled').toList(),
            emptyMessage: 'No scheduled posts yet.',
          ),
          const SizedBox(height: 16),
          SectionHeader(title: 'Recent posts'),
          const SizedBox(height: 8),
          PostList(
            posts: posts,
            emptyMessage: 'No posts yet. Create your first post.',
          ),
        ],
      ),
    );
  }
}

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({
    super.key,
    required this.session,
    required this.onCompose,
  });

  final AppSession session;
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
            Text(
              session.workspaceName,
              style: const TextStyle(color: Color(0xFF667085)),
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

class ComposeScreen extends StatefulWidget {
  const ComposeScreen({super.key, required this.onSave});

  final ValueChanged<PostPreview> onSave;

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  final _caption = TextEditingController();
  final Set<String> _platforms = {'facebook'};
  XFile? _image;
  DateTime? _scheduledAt;

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
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _save(String status) {
    if (_caption.text.trim().isEmpty && _image == null) {
      AppMessenger.show(
        'Add a caption or image first.',
        kind: SnackBarKind.info,
      );
      return;
    }

    widget.onSave(
      PostPreview(
        caption: _caption.text.trim(),
        platforms: _platforms.toList(),
        status: status,
        imagePath: _image?.path,
        scheduledAt: _scheduledAt,
      ),
    );
    _caption.clear();
    setState(() {
      _image = null;
      _scheduledAt = null;
    });
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
          const BackendNotice(),
          const SizedBox(height: 16),
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
            onChanged: (next) => setState(() {
              _platforms
                ..clear()
                ..addAll(next);
            }),
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
            onPressed: () => _save('scheduled'),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Schedule post'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _save('draft'),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save draft'),
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
  const CalendarScreen({super.key, required this.posts});

  final List<PostPreview> posts;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Calendar',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: 'Scheduled posts'),
          const SizedBox(height: 8),
          PostList(
            posts: posts.where((post) => post.status == 'scheduled').toList(),
            emptyMessage: 'No scheduled posts yet.',
          ),
        ],
      ),
    );
  }
}

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key, required this.posts});

  final List<PostPreview> posts;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Analytics',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CountGrid(
            counts: {
              'Posts': posts.length,
              'Drafts': posts.where((post) => post.status == 'draft').length,
              'Scheduled': posts
                  .where((post) => post.status == 'scheduled')
                  .length,
              'Failed': posts.where((post) => post.status == 'failed').length,
            },
          ),
          const SizedBox(height: 16),
          const EmptyState(
            message:
                'Analytics will use backend publishing history after API integration.',
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.session,
    required this.onLogout,
  });

  final AppSession session;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: 'Connected accounts'),
          const SizedBox(height: 8),
          const ConnectAccountActionCard(
            platform: 'facebook',
            title: 'Facebook',
            subtitle: 'Meta OAuth will be handled by the NestJS backend.',
            active: true,
          ),
          const SizedBox(height: 8),
          const ConnectAccountActionCard(
            platform: 'instagram',
            title: 'Instagram',
            subtitle: 'Instagram Business publishing comes after Meta OAuth.',
            active: true,
          ),
          const SizedBox(height: 16),
          if (kDebugMode) DevStatusCard(session: session),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class ConnectAccountActionCard extends StatelessWidget {
  const ConnectAccountActionCard({
    super.key,
    required this.platform,
    required this.title,
    required this.subtitle,
    required this.active,
  });

  final String platform;
  final String title;
  final String subtitle;
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
        subtitle: Text(subtitle),
        trailing: IconButton(
          tooltip: active ? 'Connect' : 'Coming soon',
          onPressed: active
              ? () => AppMessenger.show(
                  'Social account connection API is next.',
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
  const DevStatusCard({super.key, required this.session});

  final AppSession session;

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
            StatusRow(label: 'Auth provider', value: 'NestJS API pending'),
            StatusRow(label: 'User ID', value: session.userId),
            StatusRow(label: 'Workspace', value: session.workspaceName),
            const StatusRow(label: 'PostgreSQL', value: 'Backend setup next'),
            const StatusRow(label: 'Storage', value: 'MinIO/local backend'),
            const StatusRow(label: 'Firebase', value: 'Removed from mobile'),
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

class PostList extends StatelessWidget {
  const PostList({super.key, required this.posts, required this.emptyMessage});

  final List<PostPreview> posts;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return EmptyState(message: emptyMessage);
    return Column(
      children: posts
          .map(
            (post) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PostTile(post: post),
            ),
          )
          .toList(),
    );
  }
}

class PostTile extends StatelessWidget {
  const PostTile({super.key, required this.post});

  final PostPreview post;

  @override
  Widget build(BuildContext context) {
    final date = post.scheduledAt == null
        ? null
        : DateFormat('MMM d, h:mm a').format(post.scheduledAt!);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFEAF2FF),
          child: Icon(
            post.platforms.isEmpty
                ? Icons.public
                : platformIcon(post.platforms.first),
            color: const Color(0xFF1877F2),
          ),
        ),
        title: Text(
          post.caption.isEmpty ? 'Media post' : post.caption,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [post.status, ?date].join(' • '),
          overflow: TextOverflow.ellipsis,
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
