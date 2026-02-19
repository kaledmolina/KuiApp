import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Added form key
  late final AnimationController _controller;
  late final Animation<double> _animation;

  // Colors from the design
  static const Color _primary = Color(0xFF7C3AED); // Violet-600
  static const Color _primaryDark = Color(0xFF6D28D9); // Violet-700
  static const Color _bgLight = Color(0xFFF5F3FF); // Very light purple
  static const Color _inputBorder = Color(0xFFE5E7EB); // Gray-200

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) { // Validate form
      await context.read<AuthProvider>().login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      
      if (mounted && context.read<AuthProvider>().isAuthenticated) {
         context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('DEBUG: LoginScreen build');
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _primary, // Background color
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Header Section
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _animation.value),
                    child: child,
                  );
                },
                child: const RepaintBoundary(child: _Mascot()),
              ),
              const SizedBox(height: 32),
              Text(
                '¡Hola de nuevo!',
                style: GoogleFonts.nunito(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Entrena tu oído musical hoy',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple.shade100,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Card Section
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border(
                    bottom: BorderSide(color: Colors.purple.shade200, width: 8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Form( // Wrapped in Form for validation
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (authProvider.error != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            authProvider.error!.replaceAll('Exception: ', ''),
                            style: TextStyle(color: Colors.red[900]),
                          ),
                        ),
                      _CustomTextField(
                        controller: _emailController,
                        label: 'Correo Electrónico',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _CustomTextField(
                        controller: _passwordController,
                        label: 'Contraseña',
                        icon: Icons.lock,
                        obscureText: true,
                      ),
                      const SizedBox(height: 8),
                      
                      // Forgot Password
                      Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () {}, 
                            child: Text(
                              '¿OLVIDASTE TU CONTRASEÑA?',
                              style: GoogleFonts.nunito(
                                color: _primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),

                            )
                          )
                      ),

                      const SizedBox(height: 16),

                      // Login Button
                      _BubblyButton(
                        onPressed: authProvider.isLoading ? null : _submit,
                        text: 'INICIAR SESIÓN',
                        isLoading: authProvider.isLoading,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Social Login Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   _SocialButton(
                     icon: Icons.g_mobiledata, // Placeholder for Google
                     onPressed: (){},
                   ),
                   const SizedBox(width: 16),
                   _SocialButton(
                     icon: Icons.apple, // Placeholder for Apple
                     onPressed: (){},
                   ),
                   const SizedBox(width: 16),
                   const _GuestButton(),
                ],
              ),
              
              const SizedBox(height: 24),
              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¿No tienes cuenta? ',
                    style: GoogleFonts.nunito(
                       color: Colors.purple.shade200,
                       fontWeight: FontWeight.w600,
                       fontSize: 14
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'REGÍSTRATE',
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.purple.shade300,
                      )
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _Mascot extends StatelessWidget {
  const _Mascot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main Body Circle
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.purple.shade200, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.music_note_rounded, size: 64, color: Color(0xFF7C3AED)),
            ),
          ),
          // Eyes (Static for now, could be animated)
          Positioned(
            top: 32,
            left: 32 + 24, // Adjusted position
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                const SizedBox(width: 24), // Wide spacing
                 Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
              ],
            ),
          ),
          // Waving Hand
          Positioned(
             top: 40,
             right: -4,
             child: Transform.rotate(
               angle: 0.2, // ~12 degrees
               child: Container(
                 padding: const EdgeInsets.all(4),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   shape: BoxShape.circle,
                   border: Border.all(color: Colors.purple.shade200, width: 3),
                 ),
                 child: const Icon(Icons.waving_hand_rounded, size: 20, color: Color(0xFF7C3AED)),
               ),
             ),
          ),
          // Star
          const Positioned(
            top: 0,
            right: 10,
            child: Icon(Icons.star_rounded, size: 36, color: Colors.amber),
          ),
          // Bottom Music Note
          Positioned(
            bottom: 10,
            left: 10,
             child: Icon(Icons.music_note_rounded, size: 28, color: Colors.purple.shade300),
          ),
        ],
      ),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;

  const _CustomTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label (Hidden visually as per design, but good for accessibility/floating label)
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50], // bg-gray-50
            borderRadius: BorderRadius.circular(16),
             border: Border.all(color: const Color(0xFFE5E7EB), width: 2), // border-input-border
             boxShadow: [
               BoxShadow(
                 color: Colors.black.withOpacity(0.05),
                 blurRadius: 4,
                 offset: const Offset(0, 2),
               )
             ]
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
            ),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: GoogleFonts.nunito(color: Colors.grey[400], fontWeight: FontWeight.normal),
              prefixIcon: Icon(icon, color: Colors.grey[400]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
             validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo requerido';
                }
                return null;
              },
          ),
        ),
      ],
    );
  }
}

class _BubblyButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;

  const _BubblyButton({
    required this.onPressed,
    required this.text,
    this.isLoading = false,
  });

  @override
  State<_BubblyButton> createState() => _BubblyButtonState();
}

class _BubblyButtonState extends State<_BubblyButton> {
  bool _isPressed = false;
  static const Color _primary = Color(0xFF7C3AED);
  static const Color _primaryDark = Color(0xFF6D28D9);

  @override
  Widget build(BuildContext context) {
    // Handling disabled state (loading or null onPressed)
    final bool isDisabled = widget.onPressed == null;
    
    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
      onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 56,
        margin: EdgeInsets.only(top: _isPressed ? 4 : 0, bottom: _isPressed ? 0 : 4),
        decoration: BoxDecoration(
          color: isDisabled ? _primary.withOpacity(0.5) : _primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isPressed || isDisabled
              ? []
              : [
                  BoxShadow(
                    color: _primaryDark,
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading 
          ? const SizedBox(
              width: 24, 
              height: 24, 
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
            )
          : Text(
              widget.text,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SocialButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
       width: 56,
       height: 56,
       decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
             bottom: BorderSide(color: Colors.grey.shade200, width: 4),
          ),
          boxShadow: [
             BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 2),
             )
          ]
       ),
       child: Center(
          child: Icon(icon, size: 28, color: Colors.black87),
       ),
    );
  }
}

class _GuestButton extends StatelessWidget {
  const _GuestButton();

  @override
  Widget build(BuildContext context) {
    return Container(
       width: 56,
       height: 56,
       decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
             bottom: BorderSide(color: Colors.grey.shade200, width: 4),
          ),
          boxShadow: [
             BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 2),
             )
          ]
       ),
       child: Center(
          child: Text(
             'GUEST',
             style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
             ),
          )
       ),
    );
  }
}
