import 'package:flutter/material.dart';
import 'package:virtual_keyboard_multi_language/virtual_keyboard_multi_language.dart';
import '../constants/app_constants.dart';
import '../navRailscreen/navRailMainCashier.dart';
import '../navRailscreen/navRailMainWaiter.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true; // Add this to toggle PIN visibility

  // Virtual keyboard state
  bool _showKeyboard = false;
  FocusNode _pinFocus = FocusNode();
  TextEditingController? _activeController;

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 900;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top logo section - always at the top
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              width: double.infinity,
              child: Column(
                children: [
                  // Logo with shadow
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          "assets/logo1.png",
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // KOZO text logo
                  Image.asset(
                    "assets/first.png",
                    width: 180,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            // Main content - split into left form and right keyboard
            Expanded(
              child:
                  isSmallScreen ? _buildMobileLayout() : _buildDesktopLayout(),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'Designed & Developed by TITAN TECH HUB Ltd',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Layout for mobile/smaller screens - stacked layout
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Login form takes most of the space
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: _buildLoginForm(),
          ),
        ),

        // Keyboard at the bottom if shown
        if (_showKeyboard) _buildKeyboard(),
      ],
    );
  }

  // Layout for desktop/larger screens - side by side layout
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Login form on the left
        Expanded(
          flex: _showKeyboard ? 1 : 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: _buildLoginForm(),
          ),
        ),

        // Keyboard on the right if shown
        if (_showKeyboard)
          Expanded(
            flex: 1,
            child: _buildKeyboard(),
          ),
      ],
    );
  }

  // Extracted login form widget
  Widget _buildLoginForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Enter your PIN to continue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // PIN Field with toggle visibility
            TextFormField(
              controller: _pinController,
              focusNode: _pinFocus,
              keyboardType: TextInputType.none,
              obscureText: _obscureText,
              style: const TextStyle(
                fontSize: 20,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                labelText: 'PIN',
                hintText: '••••',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onTap: () {
                setState(() {
                  _showKeyboard = true;
                  _activeController = _pinController;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your PIN';
                }
                if (value.length != 4) {
                  return 'PIN must be exactly 4 digits';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),

            // Login Button with improved styling
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 55,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: _isLoading
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isLoading ? 0 : 4,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Show/Hide keyboard button - only on larger screens
            MediaQuery.of(context).size.width >= 900
                ? TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showKeyboard = !_showKeyboard;
                      });
                    },
                    icon: Icon(
                        _showKeyboard ? Icons.keyboard_hide : Icons.keyboard),
                    label:
                        Text(_showKeyboard ? 'Hide Keyboard' : 'Show Keyboard'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  // Extracted keyboard widget
  Widget _buildKeyboard() {
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width >= 900;

    return Container(
      height: isLargeScreen ? double.infinity : 280,
      width: isLargeScreen ? screenSize.width * 0.4 : double.infinity,
      constraints: BoxConstraints(
        maxHeight: isLargeScreen ? double.infinity : 280,
        maxWidth: isLargeScreen ? 450 : double.infinity,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF162334),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
            offset: isLargeScreen ? const Offset(-2, 0) : const Offset(0, -2),
          ),
        ],
        borderRadius: isLargeScreen
            ? const BorderRadius.only(
                topLeft: Radius.circular(20), bottomLeft: Radius.circular(20))
            : null,
      ),
      margin: isLargeScreen ? const EdgeInsets.all(16) : EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Keyboard header with close button
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0E1825),
              borderRadius: isLargeScreen
                  ? const BorderRadius.only(topLeft: Radius.circular(20))
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PIN Entry',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () {
                    setState(() {
                      _showKeyboard = false;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Keyboard itself with dynamic sizing
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              return VirtualKeyboard(
                // Dynamic height that fits available space
                height: constraints.maxHeight,
                textColor: Colors.white,
                fontSize: 22,
                type: VirtualKeyboardType.Numeric,
                postKeyPress: _onKeyPress,
                alwaysCaps: true,
              );
            }),
          ),
        ],
      ),
    );
  } // Handle virtual keyboard key press

  void _onKeyPress(VirtualKeyboardKey key) {
    if (_activeController == null) return;

    if (key.keyType == VirtualKeyboardKeyType.String) {
      // Only allow up to 4 digits for PIN
      if (_activeController!.text.length >= 4 &&
          _activeController!.selection.start ==
              _activeController!.selection.end) {
        return;
      }

      final text = _activeController!.text;
      final textSelection = _activeController!.selection;
      final newText = text.replaceRange(
        textSelection.start,
        textSelection.end,
        key.text ?? '',
      );
      final newSelection =
          TextSelection.collapsed(offset: textSelection.start + 1);

      _activeController!.value = TextEditingValue(
        text: newText,
        selection: newSelection,
      );

      // Auto-submit when PIN length reaches 4
      if (newText.length == 4 && _activeController == _pinController) {
        // Add a small delay to show the last digit
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!_isLoading && mounted) {
            _handleLogin();
          }
        });
      }
    } else if (key.keyType == VirtualKeyboardKeyType.Action) {
      switch (key.action) {
        case VirtualKeyboardKeyAction.Backspace:
          final text = _activeController!.text;
          final textSelection = _activeController!.selection;
          final selectionLength = textSelection.end - textSelection.start;

          // There is a selection
          if (selectionLength > 0) {
            final newText = text.replaceRange(
              textSelection.start,
              textSelection.end,
              '',
            );
            _activeController!.text = newText;
            _activeController!.selection = TextSelection.collapsed(
              offset: textSelection.start,
            );
            return;
          }

          // The cursor is at the beginning
          if (textSelection.start == 0) return;

          // Delete the previous character
          final previousCodeUnit = text.codeUnitAt(textSelection.start - 1);
          final offset = _isUtf16Surrogate(previousCodeUnit) ? 2 : 1;
          final newStart = textSelection.start - offset;
          final newText = text.replaceRange(
            newStart,
            textSelection.start,
            '',
          );
          _activeController!.text = newText;
          _activeController!.selection = TextSelection.collapsed(
            offset: newStart,
          );
          break;
        case VirtualKeyboardKeyAction.Space:
          // Don't allow spaces in PIN
          if (_activeController == _pinController) return;

          final text = _activeController!.text;
          final textSelection = _activeController!.selection;
          final newText = text.replaceRange(
            textSelection.start,
            textSelection.end,
            ' ',
          );
          _activeController!.text = newText;
          _activeController!.selection = TextSelection.collapsed(
            offset: textSelection.start + 1,
          );
          break;
        case VirtualKeyboardKeyAction.Return:
          // For login screens, we can use Return to submit the form
          if (!_isLoading) {
            _handleLogin();
          }
          break;
        default:
      }
    }
  }

  // Helper method for UTF-16 surrogate pair detection
  bool _isUtf16Surrogate(int value) {
    return value & 0xF800 == 0xD800;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _showKeyboard = false; // Hide keyboard during login
    });

    final pin = _pinController.text.trim();

    try {
      final result = await AuthService.login(pin);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Show success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );

          final user = result['user'] as User;
          final userRole = user.role.toLowerCase();

          // Debug / optional UI usage of new fields
          debugPrint('Company: ${user.companyName}');
          debugPrint('Location: ${user.location}');
          debugPrint('Telephone: ${user.telephone}');
          debugPrint('TIN: ${user.tinNumber}');
          debugPrint('Payment codes: ${user.paymentCodes.map((p) => '${p.name}:${p.code}').join(', ')}');

          // Optional second snackbar with company name
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome ${user.fullName} - ${user.companyName ?? ''}'),
              backgroundColor: Colors.blueGrey,
              duration: const Duration(seconds: 2),
            ),
          );

          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            if (userRole == 'waiter') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const NavRailMainWaiter()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const NavRailMainCashier()),
              );
            }
          });
        } else {
          // Show login error with shake animation
          _pinController.clear(); // Clear PIN on error

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Login failed'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(10),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _pinController.clear(); // Clear PIN on error

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    }
  }
}
