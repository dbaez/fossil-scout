import 'package:flutter/material.dart';
import 'timeline_screen.dart';
import 'map_screen.dart';
import 'add_post_screen.dart';
import 'profile_screen.dart';
import '../theme/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<MapScreenState> _mapScreenKey = GlobalKey<MapScreenState>();
  final GlobalKey<TimelineScreenState> _timelineScreenKey = GlobalKey<TimelineScreenState>();

  List<Widget> _buildScreens() {
    return [
      TimelineScreen(
        key: _timelineScreenKey,
        onNavigateToMap: (lat, lng, post) {
          setState(() => _currentIndex = 1);
          // Esperar un frame para que el mapa se construya
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapScreenKey.currentState?.centerOnLocation(lat, lng, post: post);
          });
        },
      ),
      MapScreen(key: _mapScreenKey),
      AddPostScreen(
        onPostCreated: () {
          // Navegar al feed y cambiar a ordenamiento por fecha
          setState(() => _currentIndex = 0);
          // Esperar un frame para que el timeline se construya
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _timelineScreenKey.currentState?.switchToDateSortAndRefresh();
          });
        },
      ),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildScreens()[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _currentIndex == 0
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: Icon(
                  Icons.explore,
                  color: _currentIndex == 0
                      ? AppTheme.primaryColor
                      : Colors.grey[600],
                ),
              ),
              label: 'Explorar',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _currentIndex == 1
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: Icon(
                  Icons.map_outlined,
                  color: _currentIndex == 1
                      ? AppTheme.primaryColor
                      : Colors.grey[600],
                ),
              ),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _currentIndex == 2
                      ? AppTheme.accentColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: _currentIndex == 2
                      ? AppTheme.accentColor
                      : Colors.grey[600],
                ),
              ),
              label: 'Descubrir',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _currentIndex == 3
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: _currentIndex == 3
                      ? AppTheme.primaryColor
                      : Colors.grey[600],
                ),
              ),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
