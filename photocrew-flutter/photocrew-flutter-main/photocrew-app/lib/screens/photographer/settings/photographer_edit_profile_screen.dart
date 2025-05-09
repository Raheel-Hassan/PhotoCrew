// lib/screens/photographer/settings/photographer_edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photocrew/widgets/custom_back_button.dart';
import 'dart:io';

class PhotographerEditProfileScreen extends StatefulWidget {
  const PhotographerEditProfileScreen({super.key});

  @override
  State<PhotographerEditProfileScreen> createState() =>
      _PhotographerEditProfileScreenState();
}

class _PhotographerEditProfileScreenState
    extends State<PhotographerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final _equipmentController = TextEditingController();
  List<String> _specialties = [];
  List<String> _portfolioImages = [];
  bool _isLoading = false;

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

  @override
  void initState() {
    super.initState();
    _loadPhotographerData();
  }

  Future<void> _loadPhotographerData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('photographers')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _nameController.text = data['name'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _experienceController.text = data['experience']?.toString() ?? '';
          _equipmentController.text = data['equipment'] ?? '';
          _specialties = List<String>.from(data['specialties'] ?? []);
          _portfolioImages = List<String>.from(data['portfolioImages'] ?? []);
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        final ref = FirebaseStorage.instance.ref().child(
            'portfolios/${user!.uid}/${DateTime.now().millisecondsSinceEpoch}');

        await ref.putFile(File(image.path));
        final url = await ref.getDownloadURL();

        setState(() {
          _portfolioImages.add(url);
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        await FirebaseFirestore.instance
            .collection('photographers')
            .doc(user?.uid)
            .update({
          'name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
          'experience': _experienceController.text.trim(),
          'equipment': _equipmentController.text.trim(),
          'specialties': _specialties,
          'portfolioImages': _portfolioImages,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profile',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 32),
              Text(
                'Portfolio Images',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _portfolioImages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _portfolioImages.length) {
                      return Center(
                        child: IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Image.network(_portfolioImages[index], height: 120),
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
              const SizedBox(height: 24),
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
                validator: (value) => value?.isEmpty ?? true
                    ? 'Equipment details are required'
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Specialties',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.black
                                    : Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }
}
