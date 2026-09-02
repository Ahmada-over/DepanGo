import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';
import '../core/theme.dart';
import '../core/app_toast.dart';
import '../providers/pro_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  
  bool _loading = false;
  bool _codeSent = false;
  String _verificationId = '';
  
  final _phoneController = TextEditingController();
  String _completePhoneNumber = '';
  
  final _otpController = TextEditingController();

  Future<void> _verifyPhone() async {
    final phone = _completePhoneNumber.isNotEmpty ? _completePhoneNumber : _phoneController.text.trim();
    if (phone.isEmpty) {
      AppToast.show(context, title: 'Erreur', message: 'Veuillez entrer votre numéro.', type: AppToastType.error);
      return;
    }
    
    setState(() => _loading = true);

    // Format phone if needed (Firebase requires country code, e.g. +221)
    String formattedPhone = phone;
    if (!formattedPhone.startsWith('+')) {
      // Default to Senegal if no plus sign
      if (formattedPhone.startsWith('221')) {
        formattedPhone = '+$formattedPhone';
      } else {
        formattedPhone = '+221$formattedPhone';
      }
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution on Android
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _loading = false);
          AppToast.show(context, title: 'Échec', message: 'Erreur: ${e.message}', type: AppToastType.error);
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _loading = false;
            _codeSent = true;
            _verificationId = verificationId;
          });
          AppToast.show(context, title: 'Code envoyé', message: 'Vérifiez vos SMS.', type: AppToastType.success);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _loading = false);
      AppToast.show(context, title: 'Erreur', message: 'Impossible d\'envoyer le code.', type: AppToastType.error);
    }
  }

  Future<void> _verifyOTP() async {
    final code = _otpController.text.trim();
    if (code.length != 6) return;
    
    setState(() => _loading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: code,
      );
      await _signInWithCredential(credential);
    } catch (e) {
      setState(() => _loading = false);
      AppToast.show(context, title: 'Code invalide', message: 'Le code saisi est incorrect.', type: AppToastType.error);
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      
      if (idToken != null) {
        final success = await ref.read(authProvider.notifier).firebaseLogin(idToken, name: null);
        if (!success && mounted) {
          AppToast.show(context, title: 'Erreur', message: 'Connexion échouée.', type: AppToastType.error);
        }
      }
    } catch (e) {
      AppToast.show(context, title: 'Erreur', message: 'Authentification Firebase échouée.', type: AppToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        border: Border.all(color: ProTheme.textMuted),
        borderRadius: BorderRadius.circular(12),
        color: ProTheme.darkSurface,
      ),
    );

    return Scaffold(
      backgroundColor: ProTheme.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Hero(
                  tag: 'pro_logo',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(LucideIcons.wrench, size: 80, color: ProTheme.primaryEmerald),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(_codeSent ? 'Vérification SMS' : 'Espace Artisan', textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ProTheme.textWhite)),
              const SizedBox(height: 8),
              Text(
                _codeSent 
                  ? 'Entrez le code à 6 chiffres envoyé au ${_phoneController.text}'
                  : 'Connectez-vous pour recevoir des missions.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: ProTheme.textMuted),
              ),
              const SizedBox(height: 40),

              if (!_codeSent) ...[
                const Text('Numéro de Téléphone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ProTheme.textWhite)),
                const SizedBox(height: 6),
                InternationalPhoneNumberInput(
                  onInputChanged: (PhoneNumber number) {
                    _completePhoneNumber = number.phoneNumber ?? '';
                  },
                  searchBoxDecoration: InputDecoration(
                    hintText: 'Rechercher un pays',
                    prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  selectorConfig: const SelectorConfig(
                    selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                    useBottomSheetSafeArea: true,
                    leadingPadding: 16,
                  ),
                  ignoreBlank: false,
                  autoValidateMode: AutovalidateMode.disabled,
                  selectorTextStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                  initialValue: PhoneNumber(isoCode: 'SN'),
                  textFieldController: _phoneController,
                  formatInput: true,
                  keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                  textStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.5),
                  inputDecoration: InputDecoration(
                    hintText: '77 000 00 00',
                    hintStyle: const TextStyle(color: ProTheme.textMuted, fontSize: 16, fontWeight: FontWeight.normal, letterSpacing: 1.5),
                    filled: true,
                    fillColor: ProTheme.darkSurface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: ProTheme.darkBorder, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: ProTheme.primaryEmerald, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verifyPhone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProTheme.primaryEmerald,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Continuer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                const SizedBox(height: 10),
                Pinput(
                  controller: _otpController,
                  length: 6,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyDecorationWith(
                    border: Border.all(color: ProTheme.primaryEmerald, width: 2),
                  ),
                  onCompleted: (pin) {
                    if (!_loading) _verifyOTP();
                  },
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProTheme.primaryEmerald,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Valider le code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => setState(() {
                    _codeSent = false;
                    _otpController.clear();
                  }),
                  child: const Text('Modifier le numéro', style: TextStyle(color: ProTheme.textMuted)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
