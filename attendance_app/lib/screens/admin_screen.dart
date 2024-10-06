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

//Adding student and teacher screen
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
        //firebase authentication: creating new user
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
                email: emailController.text, password: passwordController.text);

        //check student or teacher and add to firestore
        if (selectedRole == 'Student') {
          await firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'name': name,
            'email': email,
            'password': password,
            'rollno': rollno,
            'class': class_name,
            'role': 'Student',
          });
        } else {
          await firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
            'name': name,
            'email': email,
            'password': password,
            'role': 'Teacher',
          });
        }

        //success message
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User added successfully')));

        //after adding clearing the screen
        nameController.clear();
        emailController.clear();
        passwordController.clear();
        rollnoController.clear();
        classController.clear();
      } catch (e) {
        //incase of error
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
//select role
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
//name
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
//email
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
//password
              TextField(
                controller: passwordController,
                obscureText: false,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 10),
              if (selectedRole == 'Student') ...[
//roll no
                TextFormField(
                  controller: rollnoController,
                  decoration: const InputDecoration(labelText: 'Roll Number'),
                ),
                const SizedBox(height: 10),
//class
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
        ));
  }
}
