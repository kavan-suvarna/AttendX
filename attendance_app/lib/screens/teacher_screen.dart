import 'package:flutter/material.dart';

class Teacherscreen extends StatelessWidget {
  const Teacherscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const TProfilePage()));
              },
              icon: const Icon(Icons.person))
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TMarkAttendance()));
                },
                child: const Text('Mark Student Attendance')),
            const SizedBox(height: 35),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const TViewEditAttendance()));
                },
                child: const Text('Edit attendance'))
          ],
        ),
      ),
    );
  }
}

class TProfilePage extends StatelessWidget {
  const TProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(child: Text('Profile Details')),
    );
  }
}

class TMarkAttendance extends StatelessWidget {
  const TMarkAttendance({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Student Attendance')),
      body: const Center(child: Text('Mark attendance here')),
    );
  }
}

class TViewEditAttendance extends StatelessWidget {
  const TViewEditAttendance({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Attendance')),
      body: const Center(child: Text('Edit attendance here')),
    );
  }
}
