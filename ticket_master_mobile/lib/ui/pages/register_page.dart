import 'package:event_app/app/configs/colors.dart';
import 'package:event_app/bloc/auth_cubit.dart';
import 'package:event_app/ui/widgets/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Identity
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();

  // Step 2: Contact & Security
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isPasswordValid = false;

  // Step 3: Referral & Marketing
  String? _selectedSource;
  final _referralCodeController = TextEditingController();

  // Step 4: Interests
  final List<String> _selectedInterests = [];

  final _formKeys = [
    GlobalKey<FormState>(), // Step 1
    GlobalKey<FormState>(), // Step 2
    GlobalKey<FormState>(), // Step 3
    GlobalKey<FormState>(), // Step 4
  ];

  @override
  void initState() {
    super.initState();
    // Écouter les changements du mot de passe pour validation en temps réel
    _passwordController.addListener(_validatePasswordFields);
    _confirmPasswordController.addListener(_validatePasswordFields);
  }

  void _validatePasswordFields() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _isPasswordValid = password.length >= 6 &&
          password.isNotEmpty &&
          confirmPassword.isNotEmpty &&
          password == confirmPassword;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Validate current step
    if (!_validateCurrentStep()) return;

    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
      });
    } else {
      _completeRegistration();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _formKeys[0].currentState?.validate() ?? false;
      case 1:
        if (!(_formKeys[1].currentState?.validate() ?? false)) return false;
        if (_passwordController.text != _confirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Les mots de passe ne correspondent pas'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;
      case 2:
        if (_selectedSource == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez sélectionner une source'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;
      case 3:
        if (_selectedInterests.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez sélectionner au moins un intérêt'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  Future<void> _completeRegistration() async {
    try {
      await context.read<AuthCubit>().register(
            nom: _nomController.text.trim(),
            prenom: _prenomController.text.trim(),
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            telephone: _telephoneController.text.trim(),
            password: _passwordController.text,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // NAVIGATION: After registration, always go to setup/personalization
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/setup',
              (route) => false,
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1Identity(),
                    _buildStep2ContactSecurity(),
                    _buildStep3ReferralMarketing(),
                    _buildStep4Interests(),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build header with back button and logo
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: _previousStep,
            icon:
                const Icon(Icons.arrow_back, color: AppColors.textPrimaryColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Spacer(),
          const AppLogo(size: 40),
          const Spacer(),
          const SizedBox(width: 40), // Balance for back button
        ],
      ),
    );
  }

  /// Build progress indicator (4 segments)
  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primaryColor
                    : AppColors.greyTextColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// STEP 1: IDENTITY
  Widget _buildStep1Identity() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[0],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Créer un compte',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Commençons par votre nom',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 40),

            // Nom field
            TextFormField(
              controller: _nomController,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Nom',
                hintText: 'Entrez votre nom',
                prefixIcon: const Icon(Icons.person_outline,
                    color: AppColors.primaryColor),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: AppColors.greyTextColor.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: AppColors.greyTextColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      const BorderSide(color: AppColors.primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Prénom field
            TextFormField(
              controller: _prenomController,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Prénom',
                hintText: 'Entrez votre prénom',
                prefixIcon: const Icon(Icons.person_outline,
                    color: AppColors.primaryColor),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: AppColors.greyTextColor.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: AppColors.greyTextColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      const BorderSide(color: AppColors.primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre prénom';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// STEP 2: CONTACT & SECURITY
  Widget _buildStep2ContactSecurity() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[1],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Informations de contact',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complétez votre profil',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 40),

            // Username
            TextFormField(
              controller: _usernameController,
              keyboardType: TextInputType.text,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Nom d\'utilisateur',
                hintText: 'johndoe',
                prefixIcon: const Icon(Icons.person_outline,
                    color: AppColors.primaryColor),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: AppColors.greyTextColor.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: AppColors.greyTextColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      const BorderSide(color: AppColors.primaryColor, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Nom d\'utilisateur requis';
                if (value.length < 3) return 'Minimum 3 caractères';
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                  return 'Lettres, chiffres et _ uniquement';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'votre@email.com',
                prefixIcon: const Icon(Icons.email_outlined,
                    color: AppColors.primaryColor),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: AppColors.greyTextColor.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: AppColors.greyTextColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      const BorderSide(color: AppColors.primaryColor, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Email requis';
                if (!value.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Téléphone
            TextFormField(
              controller: _telephoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Téléphone',
                hintText: '+228 XX XX XX XX',
                prefixIcon: const Icon(Icons.phone_outlined,
                    color: AppColors.primaryColor),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: AppColors.greyTextColor.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: AppColors.greyTextColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      const BorderSide(color: AppColors.primaryColor, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Téléphone requis';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Mot de passe
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                hintText: 'Min. 6 caractères',
                prefixIcon: const Icon(Icons.lock_outlined,
                    color: AppColors.primaryColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.greyTextColor,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: AppColors.greyTextColor.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: AppColors.greyTextColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      const BorderSide(color: AppColors.primaryColor, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Mot de passe requis';
                if (value.length < 6) return 'Min. 6 caractères';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Confirmer mot de passe
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                hintText: 'Retapez votre mot de passe',
                prefixIcon: const Icon(Icons.lock_outlined,
                    color: AppColors.primaryColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.greyTextColor,
                  ),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: AppColors.greyTextColor.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: AppColors.greyTextColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      const BorderSide(color: AppColors.primaryColor, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Confirmation requise';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Messages de validation du mot de passe
            if (_passwordController.text.isNotEmpty ||
                _confirmPasswordController.text.isNotEmpty)
              _buildPasswordValidationMessages(),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordValidationMessages() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final isLengthValid = password.length >= 6;
    final doPasswordsMatch = password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        password == confirmPassword;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isPasswordValid
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isPasswordValid
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildValidationItem(
            'Au moins 6 caractères',
            isLengthValid,
          ),
          const SizedBox(height: 6),
          _buildValidationItem(
            'Les mots de passe correspondent',
            doPasswordsMatch,
          ),
        ],
      ),
    );
  }

  Widget _buildValidationItem(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          size: 18,
          color: isValid ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isValid ? Colors.green.shade700 : Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// STEP 3: REFERRAL & MARKETING
  Widget _buildStep3ReferralMarketing() {
    final sources = [
      {'name': 'Réseaux sociaux', 'icon': Icons.share},
      {'name': 'Ami/Famille', 'icon': Icons.group},
      {'name': 'Publicité', 'icon': Icons.campaign},
      {'name': 'Recherche Google', 'icon': Icons.search},
      {'name': 'Autre', 'icon': Icons.more_horiz},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[2],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Comment nous avez-vous connu ?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Aidez-nous à mieux vous connaître',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 40),

            // Source selection cards
            ...sources.map((source) {
              final isSelected = _selectedSource == source['name'];
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedSource = source['name'] as String),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.greyTextColor.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        source['icon'] as IconData,
                        color:
                            isSelected ? Colors.white : AppColors.primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        source['name'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimaryColor,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Colors.white),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 32),

            // Referral code (optional)
            TextFormField(
              controller: _referralCodeController,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Code de parrainage (optionnel)',
                hintText: 'Entrez le code si vous en avez un',
                prefixIcon: const Icon(Icons.card_giftcard,
                    color: AppColors.primaryColor),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: AppColors.greyTextColor.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                      color: AppColors.greyTextColor.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      const BorderSide(color: AppColors.primaryColor, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// STEP 4: INTERESTS
  Widget _buildStep4Interests() {
    final interests = [
      {'name': 'Musique', 'icon': Icons.music_note},
      {'name': 'Sports', 'icon': Icons.sports_soccer},
      {'name': 'Technologie', 'icon': Icons.computer},
      {'name': 'Art', 'icon': Icons.palette},
      {'name': 'Gastronomie', 'icon': Icons.restaurant},
      {'name': 'Business', 'icon': Icons.business_center},
      {'name': 'Santé', 'icon': Icons.favorite},
      {'name': 'Éducation', 'icon': Icons.school},
      {'name': 'Voyage', 'icon': Icons.flight},
      {'name': 'Mode', 'icon': Icons.checkroom},
      {'name': 'Gaming', 'icon': Icons.sports_esports},
      {'name': 'Photo', 'icon': Icons.camera_alt},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeys[3],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Vos centres d\'intérêt',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sélectionnez au moins un intérêt',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 40),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: interests.length,
              itemBuilder: (context, index) {
                final interest = interests[index];
                final isSelected =
                    _selectedInterests.contains(interest['name']);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedInterests.remove(interest['name']);
                      } else {
                        _selectedInterests.add(interest['name'] as String);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.greyTextColor.withValues(alpha: 0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          interest['icon'] as IconData,
                          size: 32,
                          color: isSelected
                              ? Colors.white
                              : AppColors.primaryColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          interest['name'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build footer with navigation buttons
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              );
            }

            // Désactiver le bouton à l'étape 2 si le mot de passe est invalide
            final isButtonEnabled = _currentStep != 1 || _isPasswordValid;

            return SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isButtonEnabled ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isButtonEnabled
                      ? AppColors.primaryColor
                      : AppColors.greyTextColor.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  disabledBackgroundColor:
                      AppColors.greyTextColor.withValues(alpha: 0.3),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                ),
                child: Text(
                  _currentStep == 3 ? 'S\'inscrire' : 'Continuer',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
