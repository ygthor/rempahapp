// ignore_for_file: prefer_const_constructors, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:get/get.dart';
import 'package:rempahapp/features/auth/auth_controller.dart';
import 'package:rempahapp/shared/shared.dart';


import 'package:flutter/services.dart';
import 'package:rempahapp/shared/ui.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  AuthController authController = AuthController();

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      authController.setDefaultFormValue();
      await showVersionUpdateAlert(context: context);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    //bool isSwitched = false;
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PreferredSize(
              preferredSize: Size.fromHeight(130.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Container(
                      width: 100.0,
                      height: 100.0,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/app_logo.png'),
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ),
                  TabBar(
                    indicatorColor: AppColors.blueDress,
                    tabs: [
                      Tab(
                        child: Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          child: Text(
                            'LOGIN',
                            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.0, color: Colors.black),
                          ),
                        ),
                      ),
                      Tab(
                        child: Container(
                          alignment: Alignment.center,
                          width: double.infinity,
                          child: Text(
                            'REGISTER',
                            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.0, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 400,
              child: TabBarView(
                children: [
                  LoginForm(),
                  RegistrationForm(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget LoginForm() {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SingleChildScrollView(
        child: FormBuilder(
          key: authController.formKeyLogin,
          //autovalidate: true,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                children: [
                  
                  inputTextField(
                    label_name: 'Username',
                    name: 'username',
                    icons: Align(
                      widthFactor: 1.0,
                      heightFactor: 0.5,
                      child: Icon(
                        Icons.person,
                        color: Color.fromARGB(255, 156, 156, 156),
                      ),
                    ),
                  ),
                  inputTextField(
                    label_name: 'Password',
                    name: 'password',
                    password_field: true,
                    icons: Align(
                      widthFactor: 1.0,
                      heightFactor: 0.5,
                      child: Icon(
                        Icons.lock,
                        color: Color.fromARGB(255, 156, 156, 156),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: submitButton(
                            text: 'Login',
                            onPressed: () async {
                              await authController.login(context: context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
               
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget RegistrationForm() {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: SingleChildScrollView(
        child: FormBuilder(
          key: authController.formKeyRegister,
          //autovalidate: true,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 80.0),
              child: Column(
                children: [
                  inputTextField(
                    label_name: 'Email',
                    name: 'email',
                    email: true,
                    icons: Align(
                      widthFactor: 1.0,
                      heightFactor: 0.5,
                      child: Icon(
                        Icons.email,
                        color: Color.fromARGB(255, 156, 156, 156),
                      ),
                    ),
                  ),
                  inputTextField(
                    label_name: 'Username',
                    name: 'username',
                    icons: Align(
                      widthFactor: 1.0,
                      heightFactor: 0.5,
                      child: Icon(
                        Icons.lock,
                        color: Color.fromARGB(255, 156, 156, 156),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: submitButton(
                            text: 'Register',
                            onPressed: () async {
                              await authController.register();
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget inputTextField({label_name, name, password_field, email = false, icons}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: SizedBox(
        // height: 40,
        child: FormBuilderTextField(
      
          obscureText: password_field == true,
          style: TextStyle(color: Colors.black),
          onChanged: (v) => v!.toUpperCase(),
          decoration: InputDecoration(
            prefixIcon: icons,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 10,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.never,
            fillColor: Color.fromARGB(255, 240, 240, 244),
            filled: true,
            labelStyle: TextStyle(fontSize: 15, color: Color.fromARGB(255, 156, 156, 156)),
            //labelText: 'Company Code',
            labelText: label_name,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.0),
              borderSide: BorderSide(color: Color.fromARGB(255, 210, 210, 210)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.0),
              borderSide: BorderSide(color: Colors.blue),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.0),
              borderSide: BorderSide(color: Color.fromARGB(255, 242, 11, 11)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5.0),
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
          //name: 'company_code',
          name: name,
          // valueTransformer: (text) => num.tryParse(text),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(),
            // FormBuilderValidators.max(context, 70),
            // if (email) FormBuilderValidators.email(context)
          ]),
          keyboardType: TextInputType.text,
        ),
      ),
    );
  }
}

