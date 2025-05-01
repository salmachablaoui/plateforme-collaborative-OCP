import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Constantes de style (identiques à register.dart)
  static const _backColor = Color(0xFFF4F6FC);
  static const _mainGreenColor = Color(0xFF2F9D4E);
  static const _greenDarkColor = Color(0xFF1E8449);
  static const _whiteColor = Colors.white;
  static const _textColor = Color(0xFF333333);
  static const _errorColor = Color(0xFFE74C3C);
  static const _borderRadius = 12.0;
  static const _inputFieldHeight = 56.0;
  static const _defaultPadding = 16.0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      if (userCredential.user != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getErrorMessage(e.code));
    } catch (e) {
      setState(() => _errorMessage = 'Une erreur inattendue est survenue');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
        return 'Email ou mot de passe incorrect';
      case 'user-disabled':
        return 'Compte désactivé';
      case 'invalid-email':
        return 'Email invalide';
      default:
        return 'Erreur de connexion';
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLargeScreen = width >= 800;

    return Scaffold(
      backgroundColor: _backColor,
      body: Row(
        children: [
          // Side panel pour les grands écrans
          if (isLargeScreen) _buildSidePanel(),

          // Contenu principal
          Expanded(
            flex: isLargeScreen ? 2 : 1,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                vertical: 40,
                horizontal: width < 600 ? 24 : 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isLargeScreen) _buildMobileHeader(),

                  _buildTitleSection(),
                  const SizedBox(height: _defaultPadding * 2),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel('Email professionnel'),
                        _buildInputField(
                          controller: _emailController,
                          hintText: 'exemple@ocpgroup.ma',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre email';
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Veuillez entrer un email valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: _defaultPadding),

                        _buildInputLabel('Mot de passe'),
                        _buildInputField(
                          controller: _passwordController,
                          hintText: 'Entrez votre mot de passe',
                          icon: Icons.lock_outlined,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: _textColor.withOpacity(0.5),
                            ),
                            onPressed:
                                () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre mot de passe';
                            }
                            if (value.length < 6) {
                              return 'Le mot de passe doit contenir au moins 6 caractères';
                            }
                            return null;
                          },
                        ),

                        if (_errorMessage != null) _buildErrorMessage(),
                        const SizedBox(height: _defaultPadding * 1.5),

                        SizedBox(
                          width: double.infinity,
                          height: _inputFieldHeight,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _mainGreenColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  _borderRadius,
                                ),
                              ),
                              elevation: 2,
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: _whiteColor,
                                      ),
                                    )
                                    : Text(
                                      'Se connecter',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _whiteColor,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: _defaultPadding),

                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: Text(
                              'Pas encore de compte ? Créer un compte',
                              style: TextStyle(
                                color: _mainGreenColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return Expanded(
      child: Container(
        color: _mainGreenColor,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(_defaultPadding * 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'OCP Connect',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _whiteColor,
                  ),
                ),
                const SizedBox(height: _defaultPadding),
                Text(
                  'Connectez-vous à votre espace professionnel',
                  style: TextStyle(
                    fontSize: 16,
                    color: _whiteColor.withOpacity(0.9),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: _defaultPadding * 2),
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: _whiteColor.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        Text(
          'OCP Connect',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _mainGreenColor,
          ),
        ),
        const SizedBox(height: _defaultPadding),
        Divider(color: _mainGreenColor.withOpacity(0.2), thickness: 1),
        const SizedBox(height: _defaultPadding),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connexion',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _greenDarkColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Entrez vos identifiants pour accéder à votre compte',
          style: TextStyle(fontSize: 14, color: _textColor.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: _textColor,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: _textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: _mainGreenColor),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _whiteColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: _mainGreenColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide(color: _mainGreenColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: _mainGreenColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: _errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: _errorColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _defaultPadding),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: _errorColor, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: _errorColor, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
