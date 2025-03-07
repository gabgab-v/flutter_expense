import 'package:expense_tracker_new/screens/dashboard.dart';
import 'package:expense_tracker_new/screens/sign_up.dart';
import 'package:expense_tracker_new/services/auth_service.dart';
import 'package:expense_tracker_new/utils/appvalidator.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var isLoader = false;
  var authService = AuthService();

  Future<void> _submitform() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoader = true;
      });
      var data = {
        "email": _emailController.text.isNotEmpty ? _emailController.text : "",
        "password":
            _passwordController.text.isNotEmpty ? _passwordController.text : ""
      };

      print("Debugging Data: $data"); // Print data before calling createUser
      await authService.login(data, context);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
      setState(() {
        isLoader = false;
      });
    }
  }

  var appValidator = Appvalidator();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF252634),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 80.0),

              // Logo and Title
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle, // Ensures the text fits well
                      color: Colors.white, // Background color
                      borderRadius:
                          BorderRadius.circular(30), // Soft rounded edges
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8), // Padding for better spacing
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/logo2.png',
                          height: 40, // Adjust size for better fit
                          width: 40,
                        ),
                        // Space between logo and text
                        const Text(
                          "xpensify",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color:
                                Colors.black, // Contrast with white background
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 80.0,
              ),
              const SizedBox(
                width: 250,
                child: Text(
                  "Login Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
              TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: _buildInputDecoration("Email", Icons.email),
                  validator: appValidator.validateEmail),
              const SizedBox(
                height: 16.0,
              ),
              TextFormField(
                  controller: _passwordController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: _buildInputDecoration("Password", Icons.lock),
                  validator: appValidator.validatePassword),
              const SizedBox(
                height: 40.0,
              ),
              SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow.shade700),
                      onPressed: () {
                        isLoader ? print("Loading") : _submitform();
                      },
                      child: isLoader
                          ? const Center(child: CircularProgressIndicator())
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 20,
                              ),
                            ))),
              const SizedBox(
                height: 30.0,
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpView()),
                  );
                },
                child: Text(
                  "Create new account",
                  style: TextStyle(
                    color: Colors.yellow.shade700,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData suffixIcon) {
    return InputDecoration(
        fillColor: const Color(0xAA494A59),
        enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0x35949494))),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white)),
        filled: true,
        labelStyle: const TextStyle(color: Color(0xFF949494)),
        labelText: label,
        suffixIcon: Icon(suffixIcon, color: const Color(0xFF949494)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)));
  }
}
