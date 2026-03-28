import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cloud_app/services/auth_service.dart';

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({super.key});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final _auth = AuthService();
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _keyboardListenerNodes = List.generate(
    6,
    (_) => FocusNode(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String _email = '';

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args == null || args is! String || args.isEmpty) {
      // Arguments lost on reload — send back to forgot password
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/forgot-password');
      });
      _email = '';
    } else {
      _email = args;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    for (final f in _keyboardListenerNodes) {
      f.dispose(); // <-- add this
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text.trim()).join();

  Future<void> _handleVerify() async {
    if (_otp.length < 6) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Please enter the full 6-digit code'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      await _auth.verifyOtp(_email, _otp);
      if (!mounted) return;
      Get.toNamed('/reset-password');
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('message: ')
          ? e.toString().split('message: ')[1].split(',')[0]
          : 'Invalid or expired code';
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildOtpBox(int index) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return KeyboardListener(
      focusNode: _keyboardListenerNodes[index],
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            _controllers[index].text.isEmpty &&
            index > 0) {
          _focusNodes[index - 1].requestFocus();
          _controllers[index - 1].clear();
          setState(() {});
        }
      },
      child: SizedBox(
        width: isSmallScreen ? 44 : 52,
        height: isSmallScreen ? 52 : 60,
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 22,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
            ),
            counterText: '',
          ),
          onChanged: (val) {
            if (val.length == 1 && index < 5) {
              _focusNodes[index + 1].requestFocus();
            }
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isSmallScreen
                ? MediaQuery.of(context).size.width * 0.9
                : 420,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20 : 32,
            vertical: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/splash_screen/cloud_icon.png',
                  width: isSmallScreen ? 56 : 64,
                  height: isSmallScreen ? 56 : 64,
                ),

                SizedBox(height: isSmallScreen ? 16 : 24),

                Text(
                  "Check your email",
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(height: isSmallScreen ? 8 : 10),

                Text(
                  "We sent a 6-digit code to\n$_email",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    color: Colors.grey[600],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 32 : 40),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, _buildOtpBox),
                ),

                SizedBox(height: isSmallScreen ? 28 : 32),

                SizedBox(
                  width: double.infinity,
                  height: isSmallScreen ? 48 : 52,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _otp.length < 6)
                        ? null
                        : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 1,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            "Verify Code",
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: isSmallScreen ? 12 : 16),

                TextButton(
                  onPressed: _isLoading ? null : () => Get.back(),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[700],
                  ),
                  child: Text(
                    "Resend Code",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 13 : 14,
                      fontWeight: FontWeight.w500,
                    ),
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
