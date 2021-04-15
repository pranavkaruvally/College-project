import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

class RegisterView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Foo Register"),
      ),
      body: RegisterForm(),
    );
  }
}

class RegisterForm extends StatefulWidget {
  @override
  _RegisterFormState createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> registerData = {
    'f_name': null,
    'l_name': null,
    'username': null,
    'email': null,
    'uprn': null,
    'password': null,
    'token': null,
  };

  //Firebase messaging initialization
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  //Here we'll store our device token
  Future<void> saveToken() async {
    registerData['token'] = await messaging.getToken();
  }

  String userJson; //JSON file to be POSTed

  //Initialising the FocusNodes
  FocusNode focusLastName;
  FocusNode focusUsername;
  FocusNode focusEmail;
  FocusNode focusUprn;
  FocusNode focusPassword;
  FocusNode focusConfirmPassword;
  FocusNode focusSubmit;

  @override
  void initState() {
    super.initState();
    // We need some focus nodes to move to the next textfield when hitting enter on the keyboard
    focusLastName = FocusNode();
    focusUsername = FocusNode();
    focusEmail = FocusNode();
    focusUprn = FocusNode();
    focusPassword = FocusNode();
    focusConfirmPassword = FocusNode();
    focusSubmit = FocusNode();
    //State.initState() must be a void method without an 'async' keyword
    //So we'll call the messaging.getToken() by nesting an async function call
    saveToken();
  }

  @override
  void dispose() {
    focusLastName.dispose();
    focusUsername.dispose();
    focusEmail.dispose();
    focusPassword.dispose();
    focusConfirmPassword.dispose();
    focusSubmit.dispose();
    super.dispose();
  }

  final TextEditingController passwordController =
      TextEditingController(); // This can be used for conforming the password

  //Now we create two variables to toggle the obscureText property
  //One for `password` and the other for `Confirm password`
  bool _passwordHidden = true;
  bool _confirmPasswordHidden = true;

  //Now we write functions to toggle obscureText property of the above given variables
  void _isTogglePassword() {
    setState(() {
      _passwordHidden = !_passwordHidden;
    });
  }

  void _isToggleConfirmPassword() {
    setState(() {
      _confirmPasswordHidden = !_confirmPasswordHidden;
    });
  }

  //This function handles the http post request to the server
  Future<void> httpPostRegisterData() async {
    var url = Uri.http("192.168.1.38:8000", "/api/register");
    var response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: userJson,
    );

    if (response.statusCode == 400) {
      //var jsonResponse = convert.jsonDecode(response.body);
      print("Error in some field. Check again!");
    }
    print(response);
  }

  //OnSubmit
  void _submitHandle() {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      //To encode the Map object to JSON file
      userJson = convert.jsonEncode(registerData);

      //To submit the http POST
      httpPostRegisterData();

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => FormCheck(
                  userJson: userJson,
                )),
      );
    }
  }

  Widget _buildFirstNameField() {
    return TextFormField(
      onSaved: (String value) {
        registerData['f_name'] = value;
      },
      onFieldSubmitted: (v) {
        FocusScope.of(context).requestFocus(
            focusLastName); // To focus on LastName field when hit enter on the keyboard
      },
      decoration: InputDecoration(
        //icon: ,
        labelText: "First name",
      ),
    );
  }

  Widget _buildLastNameField() {
    return TextFormField(
      focusNode: focusLastName,
      onSaved: (String value) {
        registerData['l_name'] = value;
      },
      onFieldSubmitted: (v) {
        focusLastName.unfocus();
        FocusScope.of(context).requestFocus(focusUsername);
      },
      decoration: InputDecoration(
        //icon: ,
        labelText: "Last name",
      ),
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      focusNode: focusUsername,
      onSaved: (String value) {
        registerData['username'] = value;
      },
      onFieldSubmitted: (v) {
        focusUsername.unfocus();
        FocusScope.of(context).requestFocus(focusEmail);
      },
      decoration: InputDecoration(
        icon: Icon(Icons.person),
        labelText: "Username",
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      focusNode: focusEmail,
      onSaved: (String value) {
        registerData['email'] = value;
      },
      onFieldSubmitted: (v) {
        focusEmail.unfocus();
        FocusScope.of(context).requestFocus(focusUprn);
      },
      decoration: InputDecoration(
        icon: Icon(Icons.mail),
        labelText: "Email ID",
      ),
    );
  }

  Widget _buildUprnField() {
    return TextFormField(
      focusNode: focusUprn,
      onSaved: (String value) {
        registerData['uprn'] = value;
      },
      onFieldSubmitted: (v) {
        focusUprn.unfocus();
        FocusScope.of(context).requestFocus(focusPassword);
      },
      // validator
      validator: (value) {
        if (value == null || value.isEmpty)
          return "Enter your UPRN";
        else if (num.tryParse(value) == null)
          return "Your UPRN should only contain numbers";
        return null;
      },
      decoration: InputDecoration(
        icon: Icon(Icons.book),
        labelText: "UPRN",
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      focusNode: focusPassword,
      onSaved: (String value) {
        registerData["password"] = value;
      },
      onFieldSubmitted: (value) {
        focusPassword.unfocus();
        FocusScope.of(context).requestFocus(focusConfirmPassword);
      },
      // validator
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Enter a password";
        }
        return null;
      },
      obscureText: _passwordHidden,
      decoration: InputDecoration(
        icon: Icon(Icons.lock),
        labelText: "Password",
        suffix: InkWell(
          onTap: _isTogglePassword,
          child: Icon(
            _passwordHidden ? Icons.visibility : Icons.visibility_off,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordConfirmField() {
    return TextFormField(
      focusNode: focusConfirmPassword,
      // validator
      onFieldSubmitted: (v) {
        focusConfirmPassword.unfocus();
        FocusScope.of(context).requestFocus(focusSubmit);
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Enter a password";
        }
        if (value != passwordController.text) {
          return "These passwords don't match! Try again";
        }
        return null;
      },
      obscureText: _confirmPasswordHidden,
      decoration: InputDecoration(
        icon: Icon(Icons.lock),
        labelText: "Confirm Password",
        suffix: InkWell(
            onTap: _isToggleConfirmPassword,
            child: Icon(
              _confirmPasswordHidden ? Icons.visibility : Icons.visibility_off,
            )),
      ),
    );
  }

  Widget _buildSubmitField() {
    return ElevatedButton(
        focusNode: focusSubmit,
        onPressed: _submitHandle,
        child: Text("Submit"));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    //First Name
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildFirstNameField(),
                    ),
                  ),
                  Expanded(
                    //Second Name
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildLastNameField(),
                    ),
                  ),
                ],
              ),
              Padding(
                //Username
                padding: const EdgeInsets.all(8.0),
                child: _buildUsernameField(),
              ),
              Padding(
                //Email
                padding: const EdgeInsets.all(8.0),
                child: _buildEmailField(),
              ),
              Padding(
                  //UPRN
                  padding: const EdgeInsets.all(8.0),
                  child: _buildUprnField()),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildPasswordField(),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildPasswordConfirmField(),
              ),
              _buildSubmitField(),
            ]),
      ),
    );
  }
}

class FormCheck extends StatelessWidget {
  final String userJson;
  FormCheck({Key key, @required this.userJson}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Foo Register'),
      ),
      body: Column(
        children: [
          Text("$userJson"),
        ],
      ),
    );
  }
}
