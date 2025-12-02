import 'package:flutter/material.dart';

class PodcastPage extends StatelessWidget {
  const PodcastPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: Text('Podcasts Page')),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      // bottomNavigationBar: const BottomTabBar(selectedIndex: 1),
      body: Center(child: Text('Podcasts Page')),
    );
  }
}
