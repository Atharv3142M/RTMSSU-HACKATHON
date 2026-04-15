import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller/sign_up_sign_in_controller.dart';
import '../../custom_widgets/auth_widgets/animated_button_widget.dart';
import '../../custom_widgets/auth_widgets/animated_login_link_widget.dart';
import '../../custom_widgets/auth_widgets/animated_text_field_widget.dart';


class SignInPage extends StatelessWidget {
  SignInPage({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();
  final SignUpSignInController controller = Get.put(SignUpSignInController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Enhanced GIF Section
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/gifs/sign_in_gif.gif',
                      fit: BoxFit.cover,
                      width: 220,
                      height: 260,
                    ),
                  ),
                ),
                // Welcome Text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome back! Let\'s continue your journey',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Field
                      AnimatedTextField(
                        controller: controller.emailController,
                        label: 'Email Address',
                        hintText: 'Enter your email',
                        prefixIcon: Icons.email_outlined,
                        validator: controller.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        delay: 0,
                      ),
                      const SizedBox(height: 12),
                      // Password Field
                      Obx(() => AnimatedTextField(
                        controller: controller.passwordController,
                        label: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: Icons.lock_outline,
                        validator: controller.validatePassword,
                        obscureText: !controller.isPasswordVisible.value,
                        textInputAction: TextInputAction.done,
                        delay: 100,
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.isPasswordVisible.value
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                      )),
                      const SizedBox(height: 22),
                      // Sign Up Button
                      Obx(() => AnimatedSignInButton(
                        label: controller.isLoading.value ? 'Signing In...' : 'Sign In',
                        icon: Icons.login,
                        onPressed: controller.isLoading.value
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  controller.loginWithEmail(_formKey);
                                }
                              },
                      )),
                      const SizedBox(height: 12),

                      SignInLoginLink(text: 'New user? ',linkText: 'Sign Up',onTap: () {
                        Get.back();
                      },),
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