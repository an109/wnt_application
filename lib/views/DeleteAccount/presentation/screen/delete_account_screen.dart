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
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../UI_helper/responsive_layout.dart';
import '../../../../core/resources/app_colours.dart';
import '../../../Dashboard/profile/widgets/account_kit.dart';
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
                content: Text(_errorMessage(state)),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is DeleteAccountLoading;
          final gutter = EdgeInsets.symmetric(horizontal: context.fx(16));

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.dark,
            child: Scaffold(
              backgroundColor: Colors.white,
              bottomNavigationBar: AccountBottomActions(
                left: AccountSecondaryButton(
                  label: 'CANCEL',
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                ),
                right: AccountPrimaryButton(
                  label: 'DELETE ACCOUNT',
                  loading: isLoading,
                  // Only armed once the user ticks the confirmation.
                  onPressed: _confirmed
                      ? () => _deleteAccountBloc.add(const DeleteAccountRequested())
                      : null,
                ),
              ),
              body: SafeArea(
                bottom: false,
                child: ListView(
                  padding: gutter.copyWith(top: context.fx(8), bottom: context.fx(24)),
                  children: [
                    const AccountTopBar(title: 'Delete Account'),
                    SizedBox(height: context.fx(16)),
                    _warningCard(),
                    SizedBox(height: context.fx(20)),
                    _heading('You will lose access to:'),
                    SizedBox(height: context.fx(10)),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(context.fx(12)),
                        border: Border.all(color: kAccountLine),
                      ),
                      child: Column(
                        children: [
                          _lossItem(
                            Icons.history_rounded,
                            const Color(0xFF00A1E4),
                            const Color(0xFFE6F6FD),
                            'Your booking history & invoices',
                            'All past and upcoming bookings will be removed.',
                          ),
                          _lossItem(
                            Icons.account_balance_wallet_rounded,
                            const Color(0xFFEE7330),
                            const Color(0xFFFDEDE3),
                            'Wallet balance & cashback rewards',
                            'Your wallet balance and cashback will be lost.',
                          ),
                          _lossItem(
                            Icons.groups_rounded,
                            const Color(0xFF6E62E5),
                            const Color(0xFFEEECFC),
                            'Saved travellers & preferences',
                            'All saved traveller details and preferences will be deleted.',
                          ),
                          _lossItem(
                            Icons.star_rounded,
                            const Color(0xFFF5B91E),
                            const Color(0xFFFEF6DE),
                            'Loyalty points & referral rewards',
                            'Your earned points and referral rewards will be lost.',
                            last: true,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: context.fx(20)),
                    _heading('Tell us why you’re leaving'),
                    SizedBox(height: context.fx(10)),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedReason,
                      isExpanded: true,
                      style: accountValueStyle(context),
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500),
                      hint: Text(
                        'Select a reason',
                        style: TextStyle(fontSize: context.ffs(13), color: kAccountMuted),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: context.fx(12),
                          vertical: context.fx(13),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.fx(12)),
                          borderSide: const BorderSide(color: kAccountLine),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.fx(12)),
                          borderSide: const BorderSide(color: kAccountLine),
                        ),
                      ),
                      items: [
                        for (final r in _reasons) DropdownMenuItem(value: r, child: Text(r)),
                      ],
                      onChanged: isLoading ? null : (v) => setState(() => _selectedReason = v),
                    ),
                    SizedBox(height: context.fx(14)),
                    InkWell(
                      onTap: isLoading ? null : () => setState(() => _confirmed = !_confirmed),
                      borderRadius: BorderRadius.circular(context.fx(6)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: context.fx(6)),
                        child: Row(
                          children: [
                            SizedBox(
                              width: context.fx(20),
                              height: context.fx(20),
                              child: Checkbox(
                                value: _confirmed,
                                activeColor: kAccountOrange,
                                side: const BorderSide(color: Color(0xFFBFC4CC)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                onChanged: isLoading
                                    ? null
                                    : (v) => setState(() => _confirmed = v ?? false),
                              ),
                            ),
                            SizedBox(width: context.fx(10)),
                            Expanded(
                              child: Text(
                                'I understand this action is permanent',
                                style: TextStyle(fontSize: context.ffs(13), color: kAccountInk),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: context.fx(14)),
                    _infoBox(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _heading(String text) => Text(
    text,
    style: TextStyle(
      fontSize: context.ffs(15),
      fontWeight: FontWeight.w500,
      color: kAccountInk,
    ),
  );

  Widget _warningCard() {
    return Container(
      padding: EdgeInsets.all(context.fx(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(context.fx(12)),
        border: Border.all(color: const Color(0xFFFBD5D5)),
        boxShadow: const [
          BoxShadow(color: Color(0x14E5484D), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_rounded, size: context.fx(24), color: const Color(0xFFE5484D)),
          SizedBox(width: context.fx(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deleting your account is permanent and irreversible.',
                  style: TextStyle(
                    fontSize: context.ffs(13),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE5484D),
                  ),
                ),
                SizedBox(height: context.fx(4)),
                Text(
                  'All your data, bookings and rewards will be permanently removed.',
                  style: TextStyle(
                    fontSize: context.ffs(10.5),
                    color: const Color(0xFFE5484D),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: context.fx(8)),
          Container(
            width: context.fx(48),
            height: context.fx(48),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE1E1),
              borderRadius: BorderRadius.circular(context.fx(12)),
            ),
            child: Icon(Icons.delete_forever_rounded,
                size: context.fx(32), color: const Color(0xFFE5484D)),
          ),
        ],
      ),
    );
  }

  Widget _lossItem(
    IconData icon,
    Color color,
    Color tint,
    String title,
    String subtitle, {
    bool last = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.fx(12),
        vertical: context.fx(12),
      ),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: kAccountLine)),
      ),
      child: Row(
        children: [
          Container(
            width: context.fx(34),
            height: context.fx(34),
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(context.fx(8)),
            ),
            child: Icon(icon, size: context.fx(20), color: color),
          ),
          SizedBox(width: context.fx(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.ffs(13),
                    fontWeight: FontWeight.w600,
                    color: kAccountInk,
                  ),
                ),
                SizedBox(height: context.fx(2)),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: context.ffs(10.5), color: kAccountMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox() {
    Widget bullet(String text) => Padding(
      padding: EdgeInsets.only(bottom: context.fx(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: context.fx(5)),
            child: Container(
              width: context.fx(5),
              height: context.fx(5),
              decoration: const BoxDecoration(color: Color(0xFF6B7280), shape: BoxShape.circle),
            ),
          ),
          SizedBox(width: context.fx(8)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: context.ffs(11), color: const Color(0xFF4B5563)),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: EdgeInsets.all(context.fx(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8FE),
        borderRadius: BorderRadius.circular(context.fx(12)),
        border: Border.all(color: const Color(0xFFDDEFFB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_rounded, size: context.fx(20), color: AppColors.AppBlue),
          SizedBox(width: context.fx(12)),
          Expanded(
            child: Column(
              children: [
                bullet('You can reactivate your account within 30 days by contacting support.'),
                bullet('All your data will be permanently removed after 30 days.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
