import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../capture/screens/capture_screen.dart';
import '../../categories/screens/categories_screen.dart';
import '../../search/screens/search_screen.dart';
import '../widgets/thoughts_list.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ThoughtsListScreen(),
    const CategoriesScreen(),
    const SearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thought Recorder'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToCapture(context),
              icon: const Icon(Icons.mic),
              label: const Text('Capture'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),
    );
  }

  void _navigateToCapture(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CaptureScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Thought Recorder',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.mic, size: 48, color: Colors.deepPurple),
      children: [
        const Text(
          'Your voice-first second brain. Capture thoughts instantly, '
          'organize with AI, and never forget important ideas.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Features:\n'
          '• Voice & text capture\n'
          '• AI-powered organization\n'
          '• Smart reminders\n'
          '• Powerful search',
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
