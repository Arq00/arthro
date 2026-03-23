// Temporary dev widget — drop this anywhere to trigger the seed.
// Remove after seeding is done.
//
// Example usage in ProfileView or any screen:
//   SeedButton(),

/*import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'seed_dummy_data.dart';

class SeedButton extends StatefulWidget {
  const SeedButton({super.key});

  @override
  State<SeedButton> createState() => _SeedButtonState();
}

class _SeedButtonState extends State<SeedButton> {
  bool _loading = false;
  String _status = '';

  Future<void> _run() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _status = '❌ Not logged in');
      return;
    }
    setState(() { _loading = true; _status = 'Seeding...'; });
    try {
      await SeedDummyData.seed(uid);
      setState(() => _status = '✅ Done! Restart the app.');
    } catch (e) {
      setState(() => _status = '❌ Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          icon:    _loading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2,
                      color: Colors.white))
              : const Icon(Icons.storage_rounded),
          label:   Text(_loading ? 'Seeding...' : '🌱 Seed Dummy Data'),
          style:   ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          onPressed: _loading ? null : _run,
        ),
        if (_status.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_status,
              style: TextStyle(
                fontSize: 12,
                color: _status.startsWith('✅')
                    ? Colors.green
                    : Colors.red,
              )),
        ],
      ],
    );
  }
}*/