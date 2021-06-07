import 'package:flutter/material.dart';
import 'registerinputdecoration.dart';
import 'dart:core';

//ignore: must_be_immutable
class FormTextField extends StatelessWidget {
  final FocusNode focusField;
  final FocusNode nextFocusField;
  final String fieldName;
  final String labeltext;
  bool passwordHidden;
  Function whenSaved;
  Function isToggledView = () => null;

  FormTextField(
      {this.focusField,
      this.nextFocusField,
      this.fieldName,
      this.labeltext,
      this.passwordHidden,
      this.whenSaved,
      this.isToggledView});

  String validate(value, fieldName, labelText) {
    RegExp myExp = RegExp(r"^[a-zA-Z0-9_@]*$");
    if (value.indexOf(' ') >= 0) return "Spaces are now allowed";
    if (value == null || value.isEmpty) return "Enter your $labelText";
    switch (fieldName) {
      case 'username':
        {
          if (!myExp.hasMatch(value)) {
            return "Only _ @ and alphanumerics are allowed";
          }
          return null;
        }
        break;
      case 'uprn':
        {
          if (num.tryParse(value) == null)
            return "Your UPRN should only contain numbers";
          return null;
        }
        break;

      case 'password':
        {
          return null;
        }
        break;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
      focusNode: focusField,
      onSaved: (String value) {
        whenSaved(value, fieldName);
      },
      onFieldSubmitted: (value) {
        focusField.unfocus();
        FocusScope.of(context).requestFocus(nextFocusField);
      },
      // validator
      validator: (value) {
        return validate(value, fieldName, labeltext);
      },
      obscureText: passwordHidden,
      decoration: (fieldName == "password")
          ? decorationField("Password", isToggledView,
              hidePassword: passwordHidden)
          : decorationField(labeltext, () {}),
    );
  }
}
