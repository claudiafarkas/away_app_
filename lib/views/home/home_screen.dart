import 'package:flutter/material.dart';
import 'imported_tab_screen.dart';
import 'feed_tab_screen.dart';

class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});

  @override
  State<MyHomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<MyHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Make the bar shorter:
        toolbarHeight: 48,
        // Remove any default title; we're focusing on tabs only
        centerTitle: true,
        automaticallyImplyLeading: false,
        // Bottom TabBar:
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.normal,
              ),
              indicatorColor: Colors.black,
              indicatorWeight: 3,
              tabs: const [Tab(text: 'Feed'), Tab(text: 'My Imports')],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [MyFeedTab(), MyImportsTabScreen()],
      ),
    );
  }
}
