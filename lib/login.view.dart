import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math';
import 'package:quizds/utlis/global.color.dart';
import 'package:quizds/widgets/button.global.dart';
import 'package:quizds/widgets/custom.clipper.dart';
import 'package:quizds/widgets/text.form.global.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController txtLogin = TextEditingController();
  final TextEditingController txtPassword = TextEditingController();
  late SharedPreferences prefs;

  Future<void> _onAuthentifier(BuildContext context) async {
    prefs = await SharedPreferences.getInstance();
    String? log = prefs.getString("login")??'';
    String? psw = prefs.getString("password")??'';
    if (txtLogin.text == log && txtPassword.text == psw) {
      prefs.setBool("connecte", true);
      Navigator.pushNamed(context, "/home");
    } else {
      const snackBar = SnackBar(
        content: Text("Identifiant ou mot de passe incorrect"),
        backgroundColor: Colors.red,
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
      body: SizedBox(
        height: height,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -MediaQuery
                  .of(context)
                  .size
                  .height * .15,
              right: -MediaQuery
                  .of(context)
                  .size
                  .width * .4,
              child: Container(
                child: Transform.rotate(
                  angle: -pi / 3.5,
                  child: ClipPath(
                    clipper: ClipPainter(),
                    child: Container(
                      height: MediaQuery
                          .of(context)
                          .size
                          .height * .5,
                      width: MediaQuery
                          .of(context)
                          .size
                          .width,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xffE6E6E6),
                            Color.fromARGB(197, 194, 5, 5),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: height * .3),
                    RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                          text: 'Quiz',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Color.fromARGB(197, 194, 5, 5),
                          ),
                          children: [
                            TextSpan(
                              text: 'App',
                              style:
                              TextStyle(color: Colors.black, fontSize: 30),
                            ),
                          ]),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Connectez-vous à votre compte',
                      style: TextStyle(
                        color: GlobalColor.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormGlobal(
                      controller: txtLogin,
                      text: 'Email',
                      obscure: false,
                      textInputType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    TextFormGlobal(
                      controller: txtPassword,
                      text: 'Password',
                      obscure: true,
                      textInputType: TextInputType.text,
                    ),
                    const SizedBox(height: 15),
                    // Vérifier si SharedPreferences est initialisé avant de passer à ButtonGlobal
                    ElevatedButton(
                      onPressed: () => _onAuthentifier(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlobalColor.mainColor,
                        minimumSize: const Size(370, 55), // button size
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Connexion',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 50,
        color: Colors.white,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tu n\'as pas de compte ?'),
            InkWell(
              child: Text(
                ' Inscrivez-vous',
                style: TextStyle(
                  color: GlobalColor.mainColor,
                ),
              ),
              onTap: () {
                // Naviguer vers la page d'inscription
                Navigator.pushNamed(context, '/signup');
              },
            ),
          ],
        ),
      ),
    );
  }
}