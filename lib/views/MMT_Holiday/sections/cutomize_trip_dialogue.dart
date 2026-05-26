import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

class CustomTripDialog extends StatelessWidget {
  const CustomTripDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.55),
      child: Stack(
        children: [
          /// Bottom Dialog
          Positioned(
            bottom: context.hp(12),
            left: context.wp(4),
            right: context.wp(4),
            child: Container(
              constraints: BoxConstraints(
                maxWidth:
                context.isDesktop ? context.wp(50) : context.wp(92),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogItem(
                    context: context,
                    icon: Icons.email_outlined,
                    title: 'Get a quote',
                    subtitle: 'Customise your holiday to your liking',
                    onTap: () {
                      Navigator.pop(context);
                      _handleGetQuote(context);
                    },
                    showDivider: true,
                    isTop: true,
                  ),
                  _buildDialogItem(
                    context: context,
                    icon: Icons.phone_outlined,
                    title: 'Call Us',
                    subtitle: 'Call our experts to customise your holiday',
                    onTap: () {
                      Navigator.pop(context);
                      _handleCall(context);
                    },
                    showDivider: true,
                  ),
                  _buildDialogItem(
                    context: context,
                    icon: Icons.chat_bubble_outline,
                    title: 'Chat with an Expert',
                    subtitle:
                    'Get instant assistance at your fingertips',
                    onTap: () {
                      Navigator.pop(context);
                      _handleChat(context);
                    },
                    showDivider: false,
                    isBottom: true,
                  ),
                ],
              ),
            ),
          ),

          /// Floating Close Button
          Positioned(
            bottom: context.hp(2),
            right: context.wp(6),
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 57,
                height: 57,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFB44CFF),
                      Color(0xFF5B2EFF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool showDivider,
    bool isTop = false,
    bool isBottom = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isTop ? 28 : 0),
            topRight: Radius.circular(isTop ? 28 : 0),
            bottomLeft: Radius.circular(isBottom ? 28 : 0),
            bottomRight: Radius.circular(isBottom ? 28 : 0),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.wp(4),
              vertical: context.hp(2.2),
            ),
            child: Row(
              children: [
                /// Icon Circle
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFA855F7),
                        Color(0xFF7C3AED),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                        Colors.purple.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),

                SizedBox(width: context.wp(4)),

                /// Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: context.titleSmall,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: context.hp(0.4)),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: context.bodySmall,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                /// Arrow
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.blue[400],
                  size: 34,
                ),
              ],
            ),
          ),
        ),

        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey[200],
            indent: 90,
            endIndent: 0,
          ),
      ],
    );
  }

  void _handleGetQuote(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Get Quote - Coming Soon'),
      ),
    );
  }

  void _handleCall(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Call Us - Coming Soon'),
      ),
    );
  }

  void _handleChat(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chat with Expert - Coming Soon'),
      ),
    );
  }
}

/// Show Dialog Function
void showCustomTripDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "CustomTripDialog",
    barrierColor: Colors.black.withOpacity(0.55),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) {
      return const CustomTripDialog();
    },
    transitionBuilder:
        (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
        ),
        child: child,
      );
    },
  );
}