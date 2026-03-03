import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';

class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen>
    with SingleTickerProviderStateMixin {
  final _otpController = TextEditingController();
  final _authService = AuthService();

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _successMessage;
  String _email = '';

  // Countdown timer
  Timer? _timer;
  int _remainingSeconds = AppConstants.otpExpiryMinutes * 60;
  bool _canResend = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _email = args?['email'] ?? '';
  }

  void _startTimer() {
    _remainingSeconds = AppConstants.otpExpiryMinutes * 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  String get _timerText {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != AppConstants.otpLength) {
      setState(() => _errorMessage = 'Please enter all 6 digits.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authService.verifyOTP(_email, otp);
      if (!mounted) return;
      setState(() => _successMessage = 'Email verified successfully! 🎉');
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/camera');
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      switch (msg) {
        case 'expired':
          setState(() => _errorMessage = AppStrings.otpExpired);
          break;
        case 'invalid_otp':
          setState(() => _errorMessage = AppStrings.invalidOtp);
          break;
        case 'max_attempts':
          setState(() => _errorMessage = AppStrings.maxOtpAttempts);
          break;
        default:
          setState(() => _errorMessage = msg);
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      await _authService.resendOTP(_email);
      if (!mounted) return;
      _otpController.clear();
      _startTimer();
      setState(() => _successMessage = 'New OTP sent to $_email');
    } catch (e) {
      setState(
          () => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A1628), AppColors.dark],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mark_email_read_outlined,
                        color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    AppStrings.otpVerification,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                      children: [
                        const TextSpan(text: 'Enter the 6-digit OTP sent to\n'),
                        TextSpan(
                          text: _email,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // DEBUG hint
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.info.withOpacity(0.3)),
                    ),
                    child: const Text(
                      '💡 OTP is printed in Flutter debug console',
                      style: TextStyle(
                          color: AppColors.info, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Status banners
                  if (_errorMessage != null) ...[
                    _StatusBanner(
                        message: _errorMessage!,
                        isError: true),
                    const SizedBox(height: 16),
                  ],
                  if (_successMessage != null) ...[
                    _StatusBanner(
                        message: _successMessage!,
                        isError: false),
                    const SizedBox(height: 16),
                  ],

                  // OTP input
                  PinCodeTextField(
                    appContext: context,
                    length: AppConstants.otpLength,
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(12),
                      fieldHeight: 58,
                      fieldWidth: 48,
                      activeFillColor: AppColors.darkCard,
                      inactiveFillColor: AppColors.darkCard,
                      selectedFillColor: AppColors.darkCard,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.darkDivider,
                      selectedColor: AppColors.accent,
                    ),
                    enableActiveFill: true,
                    textStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    onCompleted: (_) => _verifyOtp(),
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() => _errorMessage = null);
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  // Verify button
                  CustomButton(
                    label: AppStrings.verifyOtp,
                    onPressed: _verifyOtp,
                    isLoading: _isVerifying,
                    icon: Icons.verified_outlined,
                  ),
                  const SizedBox(height: 24),

                  // Timer and resend
                  _canResend
                      ? GestureDetector(
                          onTap: _isResending ? null : _resendOtp,
                          child: _isResending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primary),
                                  ),
                                )
                              : const Text(
                                  AppStrings.resendOtp,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                        )
                      : RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary),
                            children: [
                              const TextSpan(text: 'Resend OTP in '),
                              TextSpan(
                                text: _timerText,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
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
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final bool isError;
  const _StatusBanner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: TextStyle(color: color, fontSize: 13))),
        ],
      ),
    );
  }
}
