// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../../../UI_helper/responsive_layout.dart';
// import '../../../../core/utils/storage/shared_preference.dart';
// import '../../../../injection_container.dart' as di;
// import '../../../home/presentation/screens/home_screen.dart';
// import '../bloc/delete_account_bloc.dart';
// import '../bloc/delete_account_event.dart';
// import '../bloc/delete_account_state.dart';
//
// class DeleteAccountScreen extends StatefulWidget {
//   const DeleteAccountScreen({super.key});
//
//   @override
//   State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
// }
//
// class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
//   late final DeleteAccountBloc _deleteAccountBloc;
//   bool _confirmed = false;
//
//   static const _reasons = [
//     'Your booking history and invoices',
//     'Wallet balance and cashback rewards',
//     'Saved travellers and travel preferences',
//     'Loyalty points and referral rewards',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _deleteAccountBloc = di.sl<DeleteAccountBloc>();
//   }
//
//   @override
//   void dispose() {
//     _deleteAccountBloc.close();
//     super.dispose();
//   }
//
//   Future<void> _onDeleted() async {
//     final prefs = di.sl<PreferencesManager>();
//     await prefs.clearUserData();
//     await prefs.clearAuth();
//
//     if (!mounted) return;
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Account deleted successfully'),
//         backgroundColor: Colors.red,
//       ),
//     );
//
//     Navigator.of(context).pushAndRemoveUntil(
//       MaterialPageRoute(builder: (_) => const HomeScreen()),
//       (route) => false,
//     );
//   }
//
//   String _errorMessage(DeleteAccountFailed state) {
//     final data = state.error.response?.data;
//     if (data is Map) {
//       final message = data['message'] ?? data['error'];
//       if (message != null) return message.toString();
//     }
//     return 'Failed to delete account. Please try again.';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider.value(
//       value: _deleteAccountBloc,
//       child: BlocConsumer<DeleteAccountBloc, DeleteAccountState>(
//         listener: (context, state) {
//           if (state is DeleteAccountSuccess) {
//             _onDeleted();
//           } else if (state is DeleteAccountFailed) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(_errorMessage(state)),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           }
//         },
//         builder: (context, state) {
//           final isLoading = state is DeleteAccountLoading;
//
//           return Scaffold(
//             backgroundColor: Colors.white,
//             appBar: AppBar(
//               backgroundColor: Colors.white,
//               elevation: 0,
//               iconTheme: const IconThemeData(color: Colors.black87),
//               title: Text(
//                 'Delete Account',
//                 style: TextStyle(
//                   color: Colors.black87,
//                   fontSize: context.titleMedium,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//             body: SafeArea(
//               child: SingleChildScrollView(
//                 padding: context.responsivePadding,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Center(
//                       child: Container(
//                         padding: EdgeInsets.all(context.w(18)),
//                         decoration: BoxDecoration(
//                           color: Colors.red.withOpacity(0.1),
//                           shape: BoxShape.circle,
//                         ),
//                         child: Icon(
//                           Icons.warning_amber_rounded,
//                           color: Colors.red,
//                           size: context.iconXLarge,
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: context.gapXLarge),
//                     Text(
//                       "We're sorry to see you go",
//                       style: TextStyle(
//                         fontSize: context.titleLarge,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     SizedBox(height: context.gapSmall),
//                     Text(
//                       'Deleting your account is permanent and cannot be undone. You will immediately lose access to:',
//                       style: TextStyle(
//                         fontSize: context.bodyMedium,
//                         color: Colors.grey.shade700,
//                       ),
//                     ),
//                     SizedBox(height: context.gapLarge),
//                     Container(
//                       padding: EdgeInsets.all(context.w(14)),
//                       decoration: BoxDecoration(
//                         color: Colors.grey.shade50,
//                         borderRadius: BorderRadius.circular(context.borderRadiusMedium),
//                         border: Border.all(color: Colors.grey.shade200),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: _reasons
//                             .map(
//                               (reason) => Padding(
//                                 padding: EdgeInsets.symmetric(vertical: context.h(6)),
//                                 child: Row(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Icon(Icons.close_rounded, color: Colors.red.shade300, size: context.iconSmall),
//                                     SizedBox(width: context.gapSmall),
//                                     Expanded(
//                                       child: Text(
//                                         reason,
//                                         style: TextStyle(
//                                           fontSize: context.bodyMedium,
//                                           color: Colors.black87,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             )
//                             .toList(),
//                       ),
//                     ),
//                     SizedBox(height: context.gapXLarge),
//                     InkWell(
//                       onTap: isLoading ? null : () => setState(() => _confirmed = !_confirmed),
//                       borderRadius: BorderRadius.circular(context.borderRadiusSmall),
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Checkbox(
//                             value: _confirmed,
//                             onChanged: isLoading ? null : (value) => setState(() => _confirmed = value ?? false),
//                             activeColor: Colors.red,
//                           ),
//                           Expanded(
//                             child: Padding(
//                               padding: EdgeInsets.only(top: context.h(14)),
//                               child: Text(
//                                 'I understand this action is permanent and cannot be undone.',
//                                 style: TextStyle(
//                                   fontSize: context.bodyMedium,
//                                   color: Colors.black87,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     SizedBox(height: context.gapXLarge),
//                   ],
//                 ),
//               ),
//             ),
//             bottomNavigationBar: SafeArea(
//               minimum: EdgeInsets.symmetric(horizontal: context.w(16), vertical: context.h(12)),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: isLoading ? null : () => Navigator.pop(context),
//                       style: OutlinedButton.styleFrom(
//                         minimumSize: Size(double.infinity, context.buttonHeight),
//                         side: BorderSide(color: Colors.grey.shade300),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(context.r(14)),
//                         ),
//                       ),
//                       child: Text(
//                         'Cancel',
//                         style: TextStyle(
//                           fontSize: context.bodyLarge,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: context.gapMedium),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: (!_confirmed || isLoading)
//                           ? null
//                           : () => _deleteAccountBloc.add(const DeleteAccountRequested()),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.red,
//                         foregroundColor: Colors.white,
//                         disabledBackgroundColor: Colors.red.withOpacity(0.4),
//                         minimumSize: Size(double.infinity, context.buttonHeight),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(context.r(14)),
//                         ),
//                       ),
//                       child: isLoading
//                           ? SizedBox(
//                               width: context.iconMedium,
//                               height: context.iconMedium,
//                               child: const CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
//                             )
//                           : Text(
//                               'Delete My Account',
//                               style: TextStyle(
//                                 fontSize: context.bodyLarge,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/utils/storage/shared_preference.dart';
import '../../../../injection_container.dart' as di;
import '../../../home/presentation/screens/home_screen.dart';
import '../bloc/delete_account_bloc.dart';
import '../bloc/delete_account_event.dart';
import '../bloc/delete_account_state.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  late final DeleteAccountBloc _deleteAccountBloc;
  bool _confirmed = false;
  String? _selectedReason;

  static const _reasons = [
    'Too many notifications',
    'Found better alternative',
    'Privacy concerns',
    'Account security issues',
    'Not using frequently',
    'Other reasons',
  ];

  @override
  void initState() {
    super.initState();
    _deleteAccountBloc = di.sl<DeleteAccountBloc>();
  }

  @override
  void dispose() {
    _deleteAccountBloc.close();
    super.dispose();
  }

  Future<void> _onDeleted() async {
    final prefs = di.sl<PreferencesManager>();
    await prefs.clearUserData();
    await prefs.clearAuth();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Account deleted successfully',
          style: TextStyle(fontSize: context.bodyMedium),
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.r(8)),
        ),
        margin: EdgeInsets.all(context.w(16)),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
    );
  }

  String _errorMessage(DeleteAccountFailed state) {
    final data = state.error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    return 'Failed to delete account. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _deleteAccountBloc,
      child: BlocConsumer<DeleteAccountBloc, DeleteAccountState>(
        listener: (context, state) {
          if (state is DeleteAccountSuccess) {
            _onDeleted();
          } else if (state is DeleteAccountFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _errorMessage(state),
                  style: TextStyle(fontSize: context.bodyMedium),
                ),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(context.r(8)),
                ),
                margin: EdgeInsets.all(context.w(16)),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is DeleteAccountLoading;

          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: context.iconSmall),
                onPressed: () => Navigator.pop(context),
                color: Colors.black87,
              ),
              title: Text(
                'Delete Account',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: context.titleSmall,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(16),
                  vertical: context.h(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning Card
                    Container(
                      padding: EdgeInsets.all(context.w(14)),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(context.r(12)),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_rounded,
                            color: Colors.red.shade700,
                            size: context.iconSmall,
                          ),
                          SizedBox(width: context.gapSmall),
                          Expanded(
                            child: Text(
                              'Deleting your account is permanent and irreversible',
                              style: TextStyle(
                                fontSize: context.bodySmall,
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.gapLarge),

                    // What you'll lose section
                    Text(
                      'You will lose access to:',
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: context.gapSmall),

                    Container(
                      padding: EdgeInsets.all(context.w(12)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(context.r(10)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade100,
                            blurRadius: context.h(4),
                            offset: Offset(0, context.h(2)),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildLossItem(Icons.history_rounded, 'Your booking history & invoices'),
                          _buildDivider(),
                          _buildLossItem(Icons.wallet_rounded, 'Wallet balance & cashback rewards'),
                          _buildDivider(),
                          _buildLossItem(Icons.people_rounded, 'Saved travellers & preferences'),
                          _buildDivider(),
                          _buildLossItem(Icons.stars_rounded, 'Loyalty points & referral rewards'),
                        ],
                      ),
                    ),
                    SizedBox(height: context.gapXLarge),

                    // Reason for leaving
                    Text(
                      'Tell us why you\'re leaving',
                      style: TextStyle(
                        fontSize: context.bodyMedium,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: context.gapSmall),

                    Container(
                      padding: EdgeInsets.symmetric(horizontal: context.w(12)),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(context.r(10)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade100,
                            blurRadius: context.h(4),
                            offset: Offset(0, context.h(2)),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedReason,
                          hint: Text(
                            'Select a reason (optional)',
                            style: TextStyle(
                              fontSize: context.bodySmall,
                              color: Colors.grey,
                            ),
                          ),
                          isExpanded: true,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey.shade600,
                            size: context.iconSmall,
                          ),
                          items: _reasons.map((reason) {
                            return DropdownMenuItem(
                              value: reason,
                              child: Text(
                                reason,
                                style: TextStyle(fontSize: context.bodySmall),
                              ),
                            );
                          }).toList(),
                          onChanged: isLoading ? null : (value) => setState(() => _selectedReason = value),
                        ),
                      ),
                    ),
                    SizedBox(height: context.gapLarge),

                    // Confirmation checkbox with MMT style
                    InkWell(
                      onTap: isLoading ? null : () => setState(() => _confirmed = !_confirmed),
                      borderRadius: BorderRadius.circular(context.r(8)),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: context.h(8),
                          horizontal: context.w(4),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: context.w(20),
                              height: context.w(20),
                              decoration: BoxDecoration(
                                color: _confirmed ? Colors.red.shade700 : Colors.white,
                                borderRadius: BorderRadius.circular(context.r(4)),
                                border: Border.all(
                                  color: _confirmed ? Colors.red.shade700 : Colors.grey.shade400,
                                  width: context.h(2),
                                ),
                              ),
                              child: _confirmed
                                  ? Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: context.iconXSmall,
                              )
                                  : null,
                            ),
                            SizedBox(width: context.gapSmall),
                            Expanded(
                              child: Text(
                                'I understand this action is permanent',
                                style: TextStyle(
                                  fontSize: context.bodySmall,
                                  color: _confirmed ? Colors.black87 : Colors.grey.shade600,
                                  fontWeight: _confirmed ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: context.gapSmall),

                    // Additional notes
                    Text(
                      '• You can reactive your account within 30 days by contacting support',
                      style: TextStyle(
                        fontSize: context.labelSmall,
                        color: Colors.grey.shade500,
                        height: context.h(1.5),
                      ),
                    ),
                    Text(
                      '• All your data will be permanently removed after 30 days',
                      style: TextStyle(
                        fontSize: context.labelSmall,
                        color: Colors.grey.shade500,
                        height: context.h(1.5),
                      ),
                    ),
                    SizedBox(height: context.gapSmall),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.w(16),
                vertical: context.h(12),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: context.h(8),
                    offset: Offset(0, context.h(-2)),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: context.h(12)),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.r(10)),
                          ),
                          minimumSize: Size(0, context.buttonHeightSmall),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: context.bodyMedium,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: context.gapSmall),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (!_confirmed || isLoading)
                            ? null
                            : () => _deleteAccountBloc.add(const DeleteAccountRequested()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.red.shade200,
                          padding: EdgeInsets.symmetric(vertical: context.h(12)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(context.r(10)),
                          ),
                          minimumSize: Size(0, context.buttonHeightSmall),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? SizedBox(
                          width: context.iconSmall,
                          height: context.iconSmall,
                          child: CircularProgressIndicator(
                            strokeWidth: context.h(2.5),
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          'Delete Account',
                          style: TextStyle(
                            fontSize: context.bodyMedium,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLossItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.h(6)),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: context.iconSmall),
          SizedBox(width: context.gapSmall),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: context.bodySmall,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.grey.shade400,
            size: context.iconXSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: context.h(1),
      thickness: context.h(0.5),
      color: Colors.grey.shade200,
    );
  }
}
