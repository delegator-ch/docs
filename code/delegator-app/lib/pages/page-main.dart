import 'package:flutter/material.dart';
import 'page-chat.dart';
import 'page-home.dart';
import 'page-info.dart';

class PageMain extends StatefulWidget {
  const PageMain({super.key});

  @override
  State<PageMain> createState() => _PageMainState();
}

class _PageMainState extends State<PageMain> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const PageChat(),
    const PageHome(),
    const PageInfo(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onAddButtonPressed() {
    // You can implement the action for the add button here
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Add button pressed')));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      floatingActionButton:
          _selectedIndex ==
                  1 // Show FAB only on home page
              ? FloatingActionButton(
                onPressed: _onAddButtonPressed,
                backgroundColor: Colors.blue,
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Band'),
        ],
      ),
    );
  }
}
