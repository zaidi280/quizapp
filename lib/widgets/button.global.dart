import 'package:flutter/material.dart';
import 'package:quizds/utlis/global.color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ButtonGlobal extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const ButtonGlobal({
    super.key,
    required this.emailController,
    required this.passwordController,
  });

 Future<void> _onAuthentification(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  String savedEmail = prefs.getString('login') ?? '';
  String savedPassword = prefs.getString('password') ?? '';

  if (emailController.text == savedEmail && passwordController.text == savedPassword) {
    prefs.setBool("connecte", true); // ✅ Maintenant c'est ici qu'on met "connecte" à true

    Navigator.pushNamed(context, '/home');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email ou mot de passe incorrect')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _onAuthentification(context),
      child: Container(
        alignment: Alignment.center,
        height: 55,
        width: 370,
        decoration: BoxDecoration(
          color: GlobalColor.mainColor,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
            )
          ],
        ),
        child: const Text(
          'Connecter',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
