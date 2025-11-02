import 'package:flutter/material.dart';
import 'main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();

  String? selectedCountry;
  String? selectedRole;

  void _register() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration Successful!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and title
                Row(
                  children: [
                    Image.asset('assets/cargo.png', width: 50, height: 50),
                    const SizedBox(width: 10),
                    const Text(
                      'CarGo',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                const Text(
                  'Create an Account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Join CarGo and start your journey today.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 30),

                // Registration Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Full Name
                      TextFormField(
                        controller: _fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter your full name' : null,
                      ),
                      const SizedBox(height: 15),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter your email' : null,
                      ),
                      const SizedBox(height: 15),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter your password' : null,
                      ),
                      const SizedBox(height: 15),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return 'Please confirm password';
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),

                      // Country Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedCountry,
                        hint: const Text('Select Country'),
                        items: const [
                          DropdownMenuItem(value: 'Philippines', child: Text('Philippines')),
                          DropdownMenuItem(value: 'USA', child: Text('USA')),
                          DropdownMenuItem(value: 'Canada', child: Text('Canada')),
                          DropdownMenuItem(value: 'Australia', child: Text('Australia')),
                        ],
                        onChanged: (value) {
                          setState(() => selectedCountry = value!);
                        },
                        decoration: InputDecoration(
                          labelText: 'Country',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value == null ? 'Please select your country' : null,
                      ),
                      const SizedBox(height: 15),

                      // Role Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        hint: const Text('Select Role'),
                        items: const [
                          DropdownMenuItem(value: 'Renter', child: Text('Renter')),
                          DropdownMenuItem(value: 'Owner', child: Text('Owner')),
                        ],
                        onChanged: (value) {
                          setState(() => selectedRole = value!);
                        },
                        decoration: InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) =>
                            value == null ? 'Please select your role' : null,
                      ),
                      const SizedBox(height: 25),

                      // Register button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),


                      // OR divider
                       Row( children: const [ Expanded(child: Divider(thickness: 1, color: Colors.grey)), Padding( padding: EdgeInsets.symmetric(horizontal: 10), child: Text('or'), ), Expanded(child: Divider(thickness: 1, color: Colors.grey)), ], ), const SizedBox(height: 20), 

                       // Google Pay button 
                       SizedBox( width: double.infinity, height: 50, child: OutlinedButton.icon( onPressed: () {}, icon: const Icon(Icons.g_mobiledata, color: Colors.black, size: 28), label: const Text( 'Google Pay', style: TextStyle(color: Colors.black, fontSize: 16), ), style: OutlinedButton.styleFrom( side: const BorderSide(color: Colors.black), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(30), ), ), ), ), const SizedBox(height: 10),

                       // Apple Pay button 
                       SizedBox( width: double.infinity, height: 50, child: OutlinedButton.icon( onPressed: () {}, icon: const Icon(Icons.apple, color: Colors.black, size: 28), label: const Text( 'Apple Pay', style: TextStyle(color: Colors.black, fontSize: 16), ), style: OutlinedButton.styleFrom( side: const BorderSide(color: Colors.black), shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(30), ), ), ), ), const SizedBox(height: 25),


                      
                      // Already have account
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? ',
                              style: TextStyle(color: Colors.black54)),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
