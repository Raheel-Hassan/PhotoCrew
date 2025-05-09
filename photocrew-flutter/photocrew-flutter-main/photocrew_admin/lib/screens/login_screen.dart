import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

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
  int _currentImageIndex = 0;
  final _pageController = PageController();

  // Replace these with your actual image URLs
  final List<String> _images = [
    'https://images.unsplash.com/photo-1452587925148-ce544e77e70d',
    'https://images.unsplash.com/photo-1493863641943-9b68992a8d07',
    'https://images.unsplash.com/photo-1554048612-b6a482bc67e5',
    'https://images.unsplash.com/photo-1516035069371-29a1b244cc32',
  ];

  @override
  void initState() {
    super.initState();
    // Auto-scroll images every 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _autoScrollImages();
      }
    });
  }

  void _autoScrollImages() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        if (_currentImageIndex < _images.length - 1) {
          _currentImageIndex++;
        } else {
          _currentImageIndex = 0;
        }
        _pageController.animateToPage(
          _currentImageIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
        _autoScrollImages();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (_emailController.text.trim() != 'admin@photocrew.com' ||
          _passwordController.text != 'admin@123') {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid admin credentials';
        });
        return;
      }

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message ?? 'An error occurred';
        });
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Row(
//         children: [
//           // Left section (70%) - Image Slider
//           Expanded(
//             flex: 7,
//             child: Stack(
//               children: [
//                 // Image Slider
//                 PageView.builder(
//                   controller: _pageController,
//                   onPageChanged: (index) {
//                     setState(() => _currentImageIndex = index);
//                   },
//                   itemCount: _images.length,
//                   itemBuilder: (context, index) {
//                     return Image.network(
//                       _images[index],
//                       fit: BoxFit.cover,
//                       height: double.infinity,
//                       width: double.infinity,
//                       loadingBuilder: (context, child, loadingProgress) {
//                         if (loadingProgress == null) return child;
//                         return Container(
//                           color: Colors.black,
//                           child: Center(
//                             child: CircularProgressIndicator(
//                               color: Theme.of(context).brightness ==
//                                       Brightness.light
//                                   ? Colors.black
//                                   : Colors.white,
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//                 // Dark overlay
//                 Container(
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       begin: Alignment.topCenter,
//                       end: Alignment.bottomCenter,
//                       colors: [
//                         Colors.black.withOpacity(0.3),
//                         Colors.black.withOpacity(0.5),
//                       ],
//                     ),
//                   ),
//                 ),
//                 // Slider indicators
//                 Align(
//                   alignment: Alignment.bottomCenter,
//                   child: Padding(
//                     padding: const EdgeInsets.only(bottom: 100),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: List.generate(
//                         _images.length,
//                         (index) => Container(
//                           width: 8,
//                           height: 8,
//                           margin: const EdgeInsets.symmetric(horizontal: 4),
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: _currentImageIndex == index
//                                 ? Colors.white
//                                 : Colors.white.withOpacity(0.5),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 // PhotoCrew text at bottom left
//                 Positioned(
//                   left: 32,
//                   bottom: 32,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'PhotoCrew',
//                         style:
//                             Theme.of(context).textTheme.headlineLarge?.copyWith(
//                                   color: Colors.white,
//                                   fontFamily: 'Effective Way',
//                                   fontSize: 42,
//                                 ),
//                       ),
//                       Text(
//                         'Admin Dashboard',
//                         style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                               color: Colors.white70,
//                               fontFamily: 'Space Mono',
//                             ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Right section (30%) - Login Form
//           Expanded(
//             flex: 3,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 48),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     Text(
//                       'Welcome Back',
//                       style:
//                           Theme.of(context).textTheme.headlineMedium?.copyWith(
//                                 fontFamily: 'Effective Way',
//                               ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Sign in to manage your platform',
//                       style: Theme.of(context).textTheme.bodyLarge?.copyWith(
//                             color: Colors.grey,
//                           ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 48),
//                     TextFormField(
//                       cursorColor:
//                           Theme.of(context).brightness == Brightness.dark
//                               ? Colors.white
//                               : Colors.black,
//                       controller: _emailController,
//                       decoration: InputDecoration(
//                         labelText: 'Email',
//                         labelStyle: Theme.of(context).textTheme.bodyMedium,
//                         prefixIcon: const Icon(Icons.email_outlined),
//                       ),
//                       validator: (value) {
//                         if (value?.isEmpty ?? true) return 'Email is required';
//                         if (value != 'admin@photocrew.com') {
//                           return 'Invalid admin email';
//                         }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       cursorColor:
//                           Theme.of(context).brightness == Brightness.dark
//                               ? Colors.white
//                               : Colors.black,
//                       controller: _passwordController,
//                       decoration: InputDecoration(
//                         labelText: 'Password',
//                         labelStyle: Theme.of(context).textTheme.bodyMedium,
//                         prefixIcon: const Icon(Icons.lock_outline),
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _obscurePassword
//                                 ? Icons.visibility
//                                 : Icons.visibility_off,
//                           ),
//                           onPressed: () => setState(
//                               () => _obscurePassword = !_obscurePassword),
//                         ),
//                       ),
//                       obscureText: _obscurePassword,
//                       validator: (value) {
//                         if (value?.isEmpty ?? true)
//                           return 'Password is required';
//                         if (value != 'admin@123') {
//                           return 'Invalid admin password';
//                         }
//                         return null;
//                       },
//                     ),
//                     if (_errorMessage != null) ...[
//                       const SizedBox(height: 16),
//                       Text(
//                         _errorMessage!,
//                         style: TextStyle(
//                           color: Theme.of(context).colorScheme.error,
//                           fontFamily: 'Space Mono',
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                     const SizedBox(height: 32),
//                     ElevatedButton(
//                       onPressed: _isLoading ? null : _signIn,
//                       style: ElevatedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                       ),
//                       child: _isLoading
//                           ? SizedBox(
//                               height: 20,
//                               width: 20,
//                               child: CircularProgressIndicator(
//                                 color: Theme.of(context).brightness ==
//                                         Brightness.light
//                                     ? Colors.black
//                                     : Colors.white,
//                               ),
//                             )
//                           : const Text('Sign In'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome Back',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Effective Way',
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to manage your platform',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          TextFormField(
            cursorColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: Theme.of(context).textTheme.bodyMedium,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Email is required';
              if (value != 'admin@photocrew.com') {
                return 'Invalid admin email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            cursorColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: Theme.of(context).textTheme.bodyMedium,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Password is required';
              if (value != 'admin@123') {
                return 'Invalid admin password';
              }
              return null;
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontFamily: 'Space Mono',
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _signIn,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black
                          : Colors.white,
                    ),
                  )
                : const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSlider() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentImageIndex = index);
          },
          itemCount: _images.length,
          itemBuilder: (context, index) {
            return Image.network(
              _images[index],
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.black,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                );
              },
            );
          },
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _images.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 32,
          bottom: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PhotoCrew',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontFamily: 'Effective Way',
                      fontSize: 42,
                    ),
              ),
              Text(
                'Admin Dashboard',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white70,
                      fontFamily: 'Space Mono',
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Image slider taking 40% of screen height
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: _buildImageSlider(),
              ),
              // Login form
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildLoginForm(),
              ),
            ],
          ),
        ),
      );
    }

    // Desktop layout
    return Scaffold(
      body: Row(
        children: [
          // Left section (70%) - Image Slider
          Expanded(
            flex: 7,
            child: _buildImageSlider(),
          ),
          // Right section (30%) - Login Form
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: _buildLoginForm(),
            ),
          ),
        ],
      ),
    );
  }
}
