import 'package:flutter/material.dart';
import 'dart:math';
import 'package:quizds/utlis/global.color.dart';
import 'package:quizds/widgets/custom.clipper.dart';
import 'package:quizds/widgets/text.form.global.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  _SignupViewState createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  late SharedPreferences prefs;
  Future<void> _onInscription(BuildContext context) async {
    prefs = await SharedPreferences.getInstance();

    if (emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        confirmPasswordController.text.isNotEmpty) {
      if (passwordController.text == confirmPasswordController.text) {
        prefs.setString('prenom', firstNameController.text);
        prefs.setString('nom', lastNameController.text);

        prefs.setString('login', emailController.text);
        prefs.setString('password', passwordController.text);
        prefs.setBool("connecte", true);

        Navigator.pushNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Les mots de passe ne correspondent pas')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tous les champs doivent être remplis')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SizedBox(
        height: height,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -MediaQuery.of(context).size.height * .15,
              right: -MediaQuery.of(context).size.width * .4,
              child: Transform.rotate(
                angle: -pi / 3.5,
                child: ClipPath(
                  clipper: ClipPainter(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * .5,
                    width: MediaQuery.of(context).size.width,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: height * .2),
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
                            style: TextStyle(color: Colors.black, fontSize: 30),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Créez un nouveau compte',
                      style: TextStyle(
                        color: GlobalColor.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormGlobal(
                      controller: firstNameController,
                      text: 'Prénom',
                      obscure: false,
                      textInputType: TextInputType.text,
                    ),
                    const SizedBox(height: 20),
                    TextFormGlobal(
                      controller: lastNameController,
                      text: 'Nom',
                      obscure: false,
                      textInputType: TextInputType.text,
                    ),
                    const SizedBox(height: 20),
                    TextFormGlobal(
                      controller: emailController,
                      text: 'Email',
                      obscure: false,
                      textInputType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    TextFormGlobal(
                      controller: passwordController,
                      text: 'Mot de passe',
                      obscure: true,
                      textInputType: TextInputType.text,
                    ),
                    const SizedBox(height: 20),
                    TextFormGlobal(
                      controller: confirmPasswordController,
                      text: 'Confirmez le mot de passe',
                      obscure: true,
                      textInputType: TextInputType.text,
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () => _onInscription(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GlobalColor.mainColor,
                        minimumSize: const Size(370, 55), // button size
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Inscrire',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
            const Text('Vous avez déjà un compte ?'),
            InkWell(
              child: Text(
                ' Connectez-vous',
                style: TextStyle(
                  color: GlobalColor.mainColor,
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
