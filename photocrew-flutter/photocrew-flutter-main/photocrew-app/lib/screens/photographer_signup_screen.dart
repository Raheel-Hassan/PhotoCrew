// lib/screens/photographer_signup_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:photocrew/widgets/custom_back_button.dart';

class PhotographerSignupScreen extends StatefulWidget {
  const PhotographerSignupScreen({super.key});

  @override
  State<PhotographerSignupScreen> createState() =>
      _PhotographerSignupScreenState();
}

class _PhotographerSignupScreenState extends State<PhotographerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _equipmentController = TextEditingController();
  final List<File> _portfolioImages = [];
  final List<String> _specialties = [];
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _availableSpecialties = [
    'Wedding',
    'Portrait',
    'Event',
    'Fashion',
    'Product',
    'Architecture',
    'Nature',
    'Sports'
  ];

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    setState(() {
      _portfolioImages.addAll(images.map((image) => File(image.path)));
    });
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate() && _portfolioImages.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        List<String> portfolioUrls = [];
        for (var image in _portfolioImages) {
          final ref = FirebaseStorage.instance.ref().child(
              'portfolios/${userCredential.user!.uid}/${DateTime.now().millisecondsSinceEpoch}');
          await ref.putFile(image);
          final url = await ref.getDownloadURL();
          portfolioUrls.add(url);
        }

        await FirebaseFirestore.instance
            .collection('photographers')
            .doc(userCredential.user!.uid)
            .set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'bio': _bioController.text.trim(),
          'experience': _experienceController.text.trim(),
          'equipment': _equipmentController.text.trim(),
          'specialties': _specialties,
          'portfolioImages': portfolioUrls,
          'isApproved': false,
          'createdAt': Timestamp.now(),
        });

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/pending-approval');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Align(
          alignment: Alignment.centerLeft,
          child: CustomBackButton(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Photographer Registration',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildBasicInfoSection(),
                const SizedBox(height: 32),
                _buildPhotographyDetailsSection(),
                const SizedBox(height: 32),
                _buildPortfolioSection(),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? CircularProgressIndicator(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.black
                                  : Colors.white,
                        )
                      : const Text('Submit for Review'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Basic Information',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        TextFormField(
          cursorColor: Theme.of(context).brightness == Brightness.light
              ? Colors.black
              : Colors.white,
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name',
            labelStyle: Theme.of(context).textTheme.bodyMedium,
            prefixIcon: const Icon(Icons.person_outline),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Name is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          cursorColor: Theme.of(context).brightness == Brightness.light
              ? Colors.black
              : Colors.white,
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: Theme.of(context).textTheme.bodyMedium,
            prefixIcon: const Icon(Icons.email_outlined),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Email is required';
            if (!value!.contains('@')) return 'Invalid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          cursorColor: Theme.of(context).brightness == Brightness.light
              ? Colors.black
              : Colors.white,
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: Theme.of(context).textTheme.bodyMedium,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          obscureText: _obscurePassword,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Password is required';
            if (value!.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPhotographyDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photography Details',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        TextFormField(
          cursorColor: Theme.of(context).brightness == Brightness.light
              ? Colors.black
              : Colors.white,
          controller: _bioController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Bio',
            labelStyle: Theme.of(context).textTheme.bodyMedium,
            prefixIcon: const Icon(Icons.description_outlined),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Bio is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          cursorColor: Theme.of(context).brightness == Brightness.light
              ? Colors.black
              : Colors.white,
          controller: _experienceController,
          decoration: InputDecoration(
            labelText: 'Years of Experience',
            labelStyle: Theme.of(context).textTheme.bodyMedium,
            prefixIcon: const Icon(Icons.work_outline),
          ),
          keyboardType: TextInputType.number,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Experience is required' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          cursorColor: Theme.of(context).brightness == Brightness.light
              ? Colors.black
              : Colors.white,
          controller: _equipmentController,
          decoration: InputDecoration(
            labelText: 'Equipment Used',
            labelStyle: Theme.of(context).textTheme.bodyMedium,
            prefixIcon: const Icon(Icons.camera_outlined),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Equipment details are required' : null,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: _availableSpecialties.map((specialty) {
            final isSelected = _specialties.contains(specialty);
            return FilterChip(
              color: WidgetStatePropertyAll(
                isSelected
                    ? Theme.of(context).brightness == Brightness.light
                        ? Theme.of(context).primaryColor
                        : Colors.white
                    : Theme.of(context).brightness == Brightness.light
                        ? Colors.grey[200]
                        : Colors.grey[800],
              ),
              checkmarkColor: isSelected
                  ? Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : Colors.black
                  : null,
              label: Text(
                specialty,
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).brightness == Brightness.light
                          ? Colors.white
                          : Colors.black
                      : null,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _specialties.add(specialty);
                  } else {
                    _specialties.remove(specialty);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPortfolioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Portfolio', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (_portfolioImages.isEmpty)
          Center(
            child: TextButton.icon(
              onPressed: _pickImages,
              icon: Icon(
                Icons.add_photo_alternate_outlined,
                color: Theme.of(context).primaryColor,
              ),
              label: Text('Add Portfolio Images',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  )),
            ),
          )
        else
          Column(
            children: [
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _portfolioImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _portfolioImages.length) {
                      return Center(
                        child: IconButton(
                          onPressed: _pickImages,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Image.file(_portfolioImages[index], height: 120),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _portfolioImages.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}
