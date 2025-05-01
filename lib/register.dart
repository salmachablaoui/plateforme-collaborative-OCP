import 'package:app_stage/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  DateTime? _selectedDate;
  String _selectedSex = 'Homme';
  String _selectedDepartment = 'Informatique';

  // Couleurs et styles
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
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _validatePassword(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]'));
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (value.length < 8) {
      return '8 caractères minimum';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Doit contenir une majuscule';
    }
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Doit contenir une minuscule';
    }
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_validatePassword(_passwordController.text)) {
      setState(
        () => _errorMessage = 'Le mot de passe ne respecte pas les critères',
      );
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'email': _emailController.text.trim(),
            'fullName': _fullNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'birthDate':
                _selectedDate != null
                    ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                    : null,
            'gender': _selectedSex,
            'department': _selectedDepartment,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'role': 'employee',
            'isActive': true,
            'emailVerified': false,
          });

      await userCredential.user!.sendEmailVerification();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getErrorMessage(e.code));
    } catch (e) {
      setState(() => _errorMessage = 'Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 8 caractères';
      case 'invalid-email':
        return 'Email invalide (ex: nom@ocp.com)';
      default:
        return 'Erreur technique (Code: $code)';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _mainGreenColor,
              onPrimary: _whiteColor,
              onSurface: _textColor,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: _mainGreenColor),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
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
          if (isLargeScreen) _buildSidePanel(),
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
                      children: [
                        _buildFullNameField(),
                        const SizedBox(height: _defaultPadding),
                        _buildEmailAndPhoneRow(),
                        const SizedBox(height: _defaultPadding),
                        _buildPasswordFields(),
                        if (_errorMessage != null) _buildErrorMessage(),
                        const SizedBox(height: _defaultPadding),
                        _buildDateAndGenderRow(),
                        const SizedBox(height: _defaultPadding),
                        _buildDepartmentDropdown(),
                        const SizedBox(height: _defaultPadding * 1.5),
                        _buildRegisterButton(),
                        const SizedBox(height: _defaultPadding),
                        _buildLoginLink(),
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
                  'Rejoignez notre plateforme professionnelle',
                  style: TextStyle(
                    fontSize: 16,
                    color: _whiteColor.withOpacity(0.9),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: _defaultPadding * 2),
                Icon(
                  Icons.verified_user_outlined,
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
        Divider(color: _mainGreenColor.withOpacity(0.2)),
        const SizedBox(height: _defaultPadding),
      ],
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Créer un compte',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _greenDarkColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Remplissez les informations requises pour votre compte professionnel',
          style: TextStyle(fontSize: 14, color: _textColor.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildFullNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel('Nom complet'),
        _buildInputField(
          controller: _fullNameController,
          hintText: 'ex: Jean Dupont',
          icon: Icons.person_outline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer votre nom complet';
            }
            if (value.length < 3) {
              return 'Le nom doit contenir au moins 3 caractères';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailAndPhoneRow() {
    return Row(
      children: [
        Expanded(
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
            ],
          ),
        ),
        const SizedBox(width: _defaultPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel('Téléphone'),
              _buildInputField(
                controller: _phoneController,
                hintText: 'ex: +212612345678',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre numéro';
                  }
                  if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(value)) {
                    return 'Numéro invalide';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordFields() {
    final password = _passwordController.text;
    final hasMinLength = password.length >= 8;
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Mot de passe'),
                  _buildInputField(
                    controller: _passwordController,
                    hintText: 'Minimum 8 caractères',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    validator: _passwordValidator,
                    onChanged: (value) => setState(() {}),
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
                  ),
                ],
              ),
            ),
            const SizedBox(width: _defaultPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel('Confirmer mot de passe'),
                  _buildInputField(
                    controller: _confirmPasswordController,
                    hintText: 'Retapez votre mot de passe',
                    icon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: _textColor.withOpacity(0.5),
                      ),
                      onPressed:
                          () => setState(
                            () =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                          ),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_passwordController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Critères du mot de passe:',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textColor.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                _buildPasswordCriterion('8 caractères minimum', hasMinLength),
                _buildPasswordCriterion('Au moins une majuscule', hasUpperCase),
                _buildPasswordCriterion('Au moins une minuscule', hasLowerCase),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordCriterion(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.circle,
            size: 16,
            color: isValid ? _mainGreenColor : _textColor.withOpacity(0.3),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isValid ? _textColor : _textColor.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndGenderRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel('Date de naissance'),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  height: _inputFieldHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: _defaultPadding,
                  ),
                  decoration: BoxDecoration(
                    color: _whiteColor,
                    borderRadius: BorderRadius.circular(_borderRadius),
                    border: Border.all(color: _mainGreenColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: _mainGreenColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                            : 'Sélectionner une date',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: _defaultPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel('Genre'),
              Container(
                height: _inputFieldHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: _defaultPadding,
                ),
                decoration: BoxDecoration(
                  color: _whiteColor,
                  borderRadius: BorderRadius.circular(_borderRadius),
                  border: Border.all(color: _mainGreenColor.withOpacity(0.3)),
                ),
                child: DropdownButton<String>(
                  value: _selectedSex,
                  onChanged: (value) => setState(() => _selectedSex = value!),
                  underline: const SizedBox(),
                  isExpanded: true,
                  icon: Icon(Icons.arrow_drop_down, color: _mainGreenColor),
                  items:
                      ['Homme', 'Femme']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel('Département'),
        Container(
          height: _inputFieldHeight,
          padding: const EdgeInsets.symmetric(horizontal: _defaultPadding),
          decoration: BoxDecoration(
            color: _whiteColor,
            borderRadius: BorderRadius.circular(_borderRadius),
            border: Border.all(color: _mainGreenColor.withOpacity(0.3)),
          ),
          child: DropdownButton<String>(
            value: _selectedDepartment,
            onChanged: (value) => setState(() => _selectedDepartment = value!),
            underline: const SizedBox(),
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down, color: _mainGreenColor),
            items:
                [
                      'Informatique',
                      'Industrie',
                      'Extraction',
                      'Logistique',
                      'Finance',
                      'RH',
                      'Commercial',
                      'Direction Générale',
                    ]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
          ),
        ),
      ],
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

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: _inputFieldHeight,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: _mainGreenColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
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
                  'S\'inscrire',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _whiteColor,
                  ),
                ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
        child: Text(
          'Déjà un compte ? Se connecter',
          style: TextStyle(
            color: _mainGreenColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
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
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
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
}
