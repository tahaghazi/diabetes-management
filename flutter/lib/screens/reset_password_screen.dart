import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isObscure1 = true;
  bool _isObscure2 = true;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إعادة تعيين كلمة المرور بنجاح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إعادة تعيين كلمة المرور"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 30),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _isObscure1,
                decoration: InputDecoration(
                  labelText: "كلمة المرور الجديدة",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscure1 ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isObscure1 = !_isObscure1;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "يرجى إدخال كلمة مرور جديدة";
                  }
                  if (value.length < 6) {
                    return "يجب أن تكون كلمة المرور على الأقل 6 أحرف";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _isObscure2,
                decoration: InputDecoration(
                  labelText: "تأكيد كلمة المرور",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_isObscure2 ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _isObscure2 = !_isObscure2;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return "كلمتا المرور غير متطابقتين";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("إعادة تعيين كلمة المرور"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
