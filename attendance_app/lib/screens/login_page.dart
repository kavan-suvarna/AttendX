import 'package:attendance_app/screens/admin_screen.dart';
import 'package:attendance_app/screens/student_screen.dart';
import 'package:attendance_app/screens/teacher_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formkey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String selectedRole = 'Admin'; // Default role
  final List<String> roles = [
    'Admin',
    'Teacher',
    'Student'
  ]; //a list stored in variable 'roles' for the dropdownlist

  //this code snippet will check the email format or whether it is null
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  //this code snipped will check if the password field is empty or not
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'please enter your password';
    }
    return null;
  }

  // Function to handle sign-in and role validation
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      // Authenticate user
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Fetch user role from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        String role = userDoc['role'];

        // Check if the selected role matches the Firestore role
        if (role != selectedRole) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('This is a $role account')));
          return;
        }

        // Navigate based on role
        if (role == 'Student') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const Studentscreen()));
        } else if (role == 'Teacher') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const Teacherscreen()));
        } else if (role == 'Admin') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const AdminScreen()));
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Unknown role')));
        }
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User role not found')));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user found for that email.')));
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wrong password provided.')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            //wrapped all fields in form widget
            key: _formkey, //attached form key
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                const Text(
                  'ATTENDANCE MARKING AND TRACKING',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
// Sign In Text
                Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 20),
// Email Field
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: validateEmail,
                ),
                const SizedBox(height: 20),
// Password Field
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: validatePassword,
                ),
                const SizedBox(height: 20),
// Dropdown for selecting role
                DropdownButtonFormField(
                  value: selectedRole,
                  items: roles.map((String role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRole = newValue!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Login As',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
// Forgot Password Text Button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ForgotPassword()));
                  },
                  child: const Text(
                    'Forgot Password',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ),
                const SizedBox(height: 20),
// Sign In Button
                ElevatedButton(
                  onPressed: () async {
                    //if this if-statement is true then only it will navigate&authenticate, this line validates email and password.
                    if (_formkey.currentState!.validate()) {
                      String email = emailController.text;
                      String password = passwordController.text;

                      // Sign in and role-based redirection
                      await signInWithEmailAndPassword(email, password);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 100, vertical: 15),
                    backgroundColor: Colors.lightBlue[900], // Background color
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 255, 253, 253)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//Forgot Password Screen Implementation
class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final _formkey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

//email format validation
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formkey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter your email to reset your password',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: validateEmail,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    if (_formkey.currentState!.validate()) {
                      String email = emailController.text;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Password reset link sent to $email')));
                    }
                  },
                  child: Text('Submit'))
            ],
          ),
        ),
      ),
    );
  }
}
