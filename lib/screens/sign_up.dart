import 'package:expense_tracker_new/screens/login_screen.dart';
import 'package:expense_tracker_new/services/auth_service.dart';
import 'package:expense_tracker_new/utils/appvalidator.dart';
import 'package:flutter/material.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _userNameController = TextEditingController();

  final _emailController = TextEditingController();

  final _phoneController = TextEditingController();

  final _passwordController = TextEditingController();
  bool _isObscured = true;

  var authService = AuthService();
  var isLoader = false;

  Future<void> _submitform() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoader = true;
      });
      var data = {
        "username":
            _userNameController.text.isNotEmpty ? _userNameController.text : "",
        "email": _emailController.text.isNotEmpty ? _emailController.text : "",
        "phone": _phoneController.text.isNotEmpty ? _phoneController.text : "",
        "password":
            _passwordController.text.isNotEmpty ? _passwordController.text : "",
        'remainingAmount': 0,
        'totalCredit': 0,
        'totalDebit': 0,
      };

      print("Debugging Data: $data"); // Print data before calling createUser
      await authService.createUser(data, context);

      setState(() {
        isLoader = false;
      });
      // ScaffoldMessenger.of(_formKey.currentContext!).showSnackBar(
      //   const SnackBar(content: Text('Form submitted successfully')),
      // );
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
              const SizedBox(height: 20.0),

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
                height: 20.0,
              ),
              const SizedBox(
                width: 250,
                child: Text(
                  "Create new Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(
                height: 50.0,
              ),
              TextFormField(
                  controller: _userNameController,
                  style: const TextStyle(color: Colors.white),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: _buildInputDecoration("UserName", Icons.person),
                  validator: appValidator.validateUsername),
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
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: _buildInputDecoration("Phone number", Icons.call),
                  validator: appValidator.validatePhoneNumber),
              const SizedBox(
                height: 16.0,
              ),
              TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: buildPasswordInputDecoration(
                    label: "Password",
                    isObscured: _isObscured,
                    onToggleVisibility: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                  ),
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
                              'Create Account',
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
                    MaterialPageRoute(builder: (context) => const LoginView()),
                  );
                },
                child: Text(
                  "Login",
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

  InputDecoration buildPasswordInputDecoration({
    required String label,
    required bool isObscured,
    required VoidCallback onToggleVisibility,
  }) {
    return InputDecoration(
      fillColor: const Color(0xAA494A59),
      enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0x35949494))),
      focusedBorder:
          const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      filled: true,
      labelStyle: const TextStyle(color: Color(0xFF949494)),
      labelText: label,
      suffixIcon: IconButton(
        icon: Icon(
          isObscured ? Icons.visibility_off : Icons.visibility,
          color: const Color(0xFF949494),
        ),
        onPressed: onToggleVisibility,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
    );
  }
}
