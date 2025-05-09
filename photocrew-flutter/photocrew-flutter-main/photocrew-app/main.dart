// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:photocrew/firebase_options.dart';
import 'package:photocrew/provider/theme_provider.dart';
import 'package:photocrew/screens/forgot_password_screen.dart';
import 'package:photocrew/screens/login_screen.dart';
import 'package:photocrew/screens/pending_approval_screen.dart';
import 'package:photocrew/screens/photographer/photographer_booking_details_screen.dart';
import 'package:photocrew/screens/photographer/photographer_bookings_screen.dart';
import 'package:photocrew/screens/photographer/photographer_dashboard_screen.dart';
import 'package:photocrew/screens/photographer/photographer_home_screen.dart';
import 'package:photocrew/screens/photographer/settings/photographer_change_password_screen.dart';
import 'package:photocrew/screens/photographer/settings/photographer_edit_profile_screen.dart';
import 'package:photocrew/screens/photographer/settings/photographer_help_support_screen.dart';
import 'package:photocrew/screens/photographer/settings/photographer_notifications_screen.dart';
import 'package:photocrew/screens/photographer_signup_screen.dart';
import 'package:photocrew/screens/select_user_type_screen.dart';
import 'package:photocrew/screens/shared/chat_screen.dart';
import 'package:photocrew/screens/splash_screen.dart';
import 'package:photocrew/screens/user/booking_confirmation_screen.dart';
import 'package:photocrew/screens/user/booking_details_screen.dart';
import 'package:photocrew/screens/user/booking_screen.dart';
import 'package:photocrew/screens/user/bookings_screen.dart';
import 'package:photocrew/screens/user/change_password_screen.dart';
import 'package:photocrew/screens/user/edit_name_screen.dart';
import 'package:photocrew/screens/user/find_screen.dart';
import 'package:photocrew/screens/user/help_support_screen.dart';
import 'package:photocrew/screens/user/notifications_screen.dart';
import 'package:photocrew/screens/user/photographer_details_screen.dart';
import 'package:photocrew/screens/user/user_home_screen.dart';
import 'package:photocrew/screens/user_signup_screen.dart';
import 'package:photocrew/theme/app_theme.dart';
import 'package:provider/provider.dart';
//... import 'firebase_options.dart';
// import 'theme/app_theme.dart';
 import 'screens/splash_screen.dart';
// import 'screens/login_screen.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'PhotoCrew',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/select-type': (context) => const SelectUserTypeScreen(),
              '/signup/user': (context) => const UserSignupScreen(),
              '/signup/photographer': (context) =>
                  const PhotographerSignupScreen(),
              '/pending-approval': (context) => const PendingApprovalScreen(),
              '/user/home': (context) => const UserHomeScreen(),
              '/user/change-password': (context) =>
                  const UserChangePasswordScreen(),
              '/user/help-support': (context) => const UserHelpSupportScreen(),
              '/user/notifications': (context) =>
                  const UserNotificationsScreen(),
              '/user/edit-name': (context) => const UserEditNameScreen(),
              '/user/find': (context) => const UserFindScreen(),
              '/photographer/details': (context) => PhotographerDetailsScreen(
                    photographerId:
                        ModalRoute.of(context)!.settings.arguments as String,
                  ),
              '/chat': (context) => SharedChatScreen(
                    chatId:
                        ModalRoute.of(context)!.settings.arguments as String,
                  ),
              '/booking/create': (context) {
                final args = ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>;
                return BookingScreen(photographerData: args);
              },
              '/booking/confirmation': (context) => BookingConfirmationScreen(
                    bookingId:
                        ModalRoute.of(context)!.settings.arguments as String,
                  ),
              '/bookings/all': (context) => const AllBookingsScreen(),
              '/booking/details': (context) => BookingDetailsScreen(
                    bookingId:
                        ModalRoute.of(context)!.settings.arguments as String,
                  ),
              '/photographer/home': (context) => const PhotographerHomeScreen(),
              '/photographer/edit-profile': (context) =>
                  const PhotographerEditProfileScreen(),
              '/photographer/change-password': (context) =>
                  const PhotographerChangePasswordScreen(),
              '/photographer/notifications': (context) =>
                  const PhotographerNotificationsScreen(),
              '/photographer/help-support': (context) =>
                  const PhotographerHelpSupportScreen(),
              '/photographer/bookings': (context) =>
                  const PhotographerBookingsScreen(),
              '/photographer/dashboard': (context) =>
                  const PhotographerDashboardScreen(),
              // Add to routes map in main.dart
              '/photographer/booking/details': (context) =>
                  PhotographerBookingDetailsScreen(
                    bookingId:
                        ModalRoute.of(context)!.settings.arguments as String,
                  ),
            });
      },
    );
  }
}
