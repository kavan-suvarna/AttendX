import 'package:flutter/material.dart';
import 'student_attendance_screen.dart';

class Studentscreen extends StatelessWidget {
  const Studentscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Dashboard'), actions: [
        IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()));
            },
            icon: const Icon(Icons.person))
      ]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MarkAttendance()));
                },
                child: const Text('Mark Attendance')),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ViewAttendance()));
                },
                child: const Text('View Attendance'))
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: Kavan Suvarna', style: TextStyle(fontSize: 16)),
            SizedBox(height: 15),
            Text('Roll Number:CS-7146', style: TextStyle(fontSize: 16)),
            SizedBox(height: 15),
            Text('Email:kavansuvarna56@gmail.com',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 15),
            Text('Class:TyBscCS', style: TextStyle(fontSize: 16))
          ],
        ),
      ),
    );
  }
}

class MarkAttendance extends StatelessWidget {
  const MarkAttendance({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mark Attendance')),
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Mark your attendance here'),
          const SizedBox(height: 30),
          ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    (const SnackBar(content: Text('Attendance Marked'))));
              },
              child: const Text('Mark Attendance!'))
        ],
      )),
    );
  }
}
