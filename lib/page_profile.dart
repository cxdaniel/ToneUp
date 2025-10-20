import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile Page')),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      // bottomNavigationBar: const BottomTabBar(selectedIndex: 2),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Profile Page'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // 点击退出
                await Supabase.instance.client.auth.signOut();
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
