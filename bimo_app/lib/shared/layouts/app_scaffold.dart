import 'package:flutter/material.dart';
import 'app_sidebar.dart';
import 'app_header.dart';

class AppScaffold extends StatefulWidget {
  final Widget body;
  final String title;

  const AppScaffold({
    Key? key,
    required this.body,
    this.title = 'Build Intelligence & Materials Organizer',
  }) : super(key: key);

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  bool _isSidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          if (isDesktop)
            AppSidebar(
              isExpanded: _isSidebarExpanded,
              onToggle: () {
                setState(() {
                  _isSidebarExpanded = !_isSidebarExpanded;
                });
              },
            ),

          // Main View Content
          Expanded(
            child: Column(
              children: [
                AppHeader(title: widget.title),
                Expanded(
                  child: SelectionArea(
                    child: widget.body,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: AppSidebar(
                isExpanded: true,
                onToggle: () => Navigator.of(context).pop(),
              ),
            ),
    );
  }
}
