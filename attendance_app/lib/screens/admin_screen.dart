import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => AddUserScreen()));
                },
                child: const Text('Add User')),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(onPressed: () {}, child: const Text('Remove User')),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () {}, child: const Text('View Users'))
          ],
        ),
      ),
    );
  }
}

// Adding student and teacher screen
class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});
  @override
  AddUserScreenState createState() => AddUserScreenState();
}

class AddUserScreenState extends State<AddUserScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController rollnoController = TextEditingController();
  final TextEditingController classController = TextEditingController();
  String selectedRole = 'Student';
  final List<String> roles = ['Student', 'Teacher'];

  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addUser() async {
    String name = nameController.text;
    String email = emailController.text;
    String password = passwordController.text;
    int? rollno; // roll number as int
    // ignore: non_constant_identifier_names
    String class_name = classController.text;

    // Validate roll number input
    if (rollnoController.text.isNotEmpty) {
      try {
        rollno = int.parse(rollnoController.text); // Convert to int
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid roll number')));
        return;
      }
    }

    if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
      try {
        // Firebase authentication: creating new user
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
                email: emailController.text, password: passwordController.text);

        // Check student or teacher and add to Firestore
        if (selectedRole == 'Student') {
          // Define subjects based on the class
          Map<String, List<String>> classSubjects = {
            'TyBscCS': [
              "Artificial Intelligence",
              "Cyber Forensics",
              "Information & Network Security",
              "Project Management",
              "Software Testing & Quality Assurance",
              "AI_Practical",
              "CF_Practical",
              "INS_Practical",
              "STQA_Practical"
            ],
            'SyBscCS': ['OS', 'LA', 'DS', 'ADBMS', 'JAVA', 'WEB', 'GT']
            // Add more classes and their subjects as needed
          };

          // Get subjects for the entered class
          List<String> subjects = classSubjects[class_name] ?? [];

          // Adding student data to Firestore
          await firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'name': name,
            'email': email,
            'rollno': rollno,
            'class': class_name,
            'role': 'Student',
          });

          // Add attendance as a subcollection
          for (var subject in subjects) {
            await firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .collection('attendance')
                .doc(
                    subject) // Each subject becomes a document in the attendance subcollection
                .set({
              'attendancePercentage': 0.0,
              'presentHours': 0.0,
              'totalHours': 0.0,
              'subjectName': subject,
              'detailedAttendance': {},
            });
          }
        } else {
          // Adding teacher data to Firestore
          await firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'name': name,
            'email': email,
            'role': 'Teacher',
          });
        }

        // Success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User added successfully')));
        }

        // After adding, clear the screen
        nameController.clear();
        emailController.clear();
        passwordController.clear();
        rollnoController.clear();
        classController.clear();
      } catch (e) {
        // In case of error
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required fields')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add User'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Select role
            DropdownButtonFormField(
              value: selectedRole,
              items: roles.map((String role) {
                return DropdownMenuItem(value: role, child: Text(role));
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedRole = newValue!;
                });
              },
              decoration: const InputDecoration(labelText: 'Select Role'),
            ),
            const SizedBox(height: 20),
            // Name
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            // Email
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            // Password
            TextField(
              controller: passwordController,
              obscureText: false,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 10),
            if (selectedRole == 'Student') ...[
              // Roll No
              TextFormField(
                controller: rollnoController,
                decoration: const InputDecoration(labelText: 'Roll Number'),
              ),
              const SizedBox(height: 10),
              // Class
              TextFormField(
                controller: classController,
                decoration: const InputDecoration(labelText: 'Class'),
              ),
              const SizedBox(height: 10),
            ],
            ElevatedButton(
              onPressed: addUser,
              child: const Text('Add User'),
            )
          ],
        ),
      ),
    );
  }
}
