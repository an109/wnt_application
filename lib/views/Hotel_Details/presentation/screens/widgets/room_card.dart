import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import '../../../../../UI_helper/navigation_queue.dart';
import '../../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../auth/presentation/bloc/auth_state.dart';
import '../../../../login/login.dart';
import '../../../domain/entities/rooms_entity.dart';

class RoomCard extends StatefulWidget {
  final RoomEntity room;
  final int adults;
  final int children;
  final VoidCallback onSelect;

  const RoomCard({
    super.key,
    required this.room,
    required this.adults,
    required this.children,
    required this.onSelect,
  });

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  bool _isSelected = false;

  void _handleBooking(BuildContext context) {
    final authState = context.read<AuthBloc>().state;

    if (authState is AuthAuthenticated) {
      // User is logged in, proceed with booking
      widget.onSelect();
    } else {
      // User not logged in, set pending navigation and show login
      NavigationQueueService().setPendingNavigation(() {
        if (context.mounted) {
          widget.onSelect();
        }
      });

      _showLoginPopup(context);
    }
  }

  void _showLoginPopup(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Login",
      barrierColor: Colors.black.withOpacity(0.15),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) {
        return const LoginSignupScreen();
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print('RoomCard: Building - ${widget.room.roomDisplayName}, Fare: ${widget.room.totalFare}');

    return Container(
      decoration: BoxDecoration(
        color: _isSelected ? Colors.green[50] : Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveExtension(context).borderRadius),
        border: Border.all(
          color: _isSelected ? Colors.green : Colors.grey[200]!,
          width: _isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoomHeader(context),
          Padding(
            padding: ResponsiveExtension(context).responsivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoomDetails(context),
                const SizedBox(height: 6),
                _buildInclusions(context),
                if (widget.room.roomPromotion.isNotEmpty) ...[
                  // const SizedBox(height: 12),
                  // _buildPromotions(context),
                ],
                // const SizedBox(height: 16),
                _buildPriceAndButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isSelected ? Colors.green[50] : Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.meeting_room,
            color: _isSelected ? Colors.green : Colors.blue,
            size: ResponsiveExtension(context).sp(20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.room.roomDisplayName,
                  style: TextStyle(
                    fontSize: ResponsiveExtension(context).sp(16),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  widget.room.bedInfo,
                  style: TextStyle(
                    fontSize: ResponsiveExtension(context).sp(12),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (!widget.room.isRefundable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                'Non-Refundable',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: ResponsiveExtension(context).sp(10),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (_isSelected) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSelected = false;
                });
              },
              child: const Icon(
                Icons.close,
                color: Colors.red,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, size: ResponsiveExtension(context).sp(16), color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '${widget.adults} Guest${widget.adults > 1 ? 's' : ''}${widget.children > 0 ? ', ${widget.children} Child${widget.children > 1 ? 'ren' : ''}' : ''}',
              style: TextStyle(
                fontSize: ResponsiveExtension(context).sp(14),
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        if (widget.room.withTransfers) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.airport_shuttle, size: ResponsiveExtension(context).sp(16), color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Free beach transfer included',
                style: TextStyle(
                  fontSize: ResponsiveExtension(context).sp(14),
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInclusions(BuildContext context) {
    final inclusions = widget.room.inclusion.split(',').map((i) => i.trim()).where((i) => i.isNotEmpty).toList();

    if (inclusions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: inclusions.map((inclusion) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check,
                size: ResponsiveExtension(context).sp(12),
                color: Colors.green[700],
              ),
              const SizedBox(width: 4),
              Text(
                inclusion,
                style: TextStyle(
                  fontSize: ResponsiveExtension(context).sp(12),
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceAndButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  widget.room.totalFare.toLocaleString(),
                  style: TextStyle(
                    fontSize: ResponsiveExtension(context).sp(24),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  ' / night',
                  style: TextStyle(
                    fontSize: ResponsiveExtension(context).sp(14),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            Text(
              '+ ${widget.room.totalTax.toLocaleString()} taxes',
              style: TextStyle(
                fontSize: ResponsiveExtension(context).sp(12),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () {
            if (!_isSelected) {
              // First tap: Just change the button to "Book" mode
              setState(() {
                _isSelected = true;
              });
            } else {
              // Second tap: Already in "Book" mode, now handle booking/login
              _handleBooking(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isSelected ? Colors.green : Colors.red[700],
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            _isSelected ? "Book Room" : "Select Room",
            style: TextStyle(
              fontSize: ResponsiveExtension(context).sp(14),
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// Extension for number formatting
extension NumberFormatting on num {
  String toLocaleString() {
    return toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }
}