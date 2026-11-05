import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../UpcomingTrips/data/models/tripModel.dart';
import '../../UpcomingTrips/domain/entity/upcomingTrip_entity.dart';
import 'trip_card.dart' show TripDashedLine, TripStatus, TripStatusKind;

const Color _kInk = Color(0xFF111527);
const Color _kMuted = Color(0xFF6B7280);
const Color _kLine = Color(0xFFE5E7EB);
const Color _kStepOff = Color(0xFFDCEFFA);

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _stepDate(String? iso) {
  final d = DateTime.tryParse(iso ?? '')?.toLocal();
  return d == null ? '' : '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';
}

/// Maps destination country names to representative asset-free network images.
String _destinationImage(String destination) {
  final key = destination.toLowerCase().trim();
  const images = {
    'united arab emirates': 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=400&h=300&fit=crop',
    'uae': 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=400&h=300&fit=crop',
    'dubai': 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=400&h=300&fit=crop',
    'india': 'https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=400&h=300&fit=crop',
    'usa': 'https://images.unsplash.com/photo-1485738422979-f5c462d49f04?w=400&h=300&fit=crop',
    'united states': 'https://images.unsplash.com/photo-1485738422979-f5c462d49f04?w=400&h=300&fit=crop',
    'uk': 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=400&h=300&fit=crop',
    'united kingdom': 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=400&h=300&fit=crop',
    'singapore': 'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=400&h=300&fit=crop',
    'thailand': 'https://images.unsplash.com/photo-1528181304800-259b08848526?w=400&h=300&fit=crop',
    'australia': 'https://images.unsplash.com/photo-1523482580672-f109ba8cb9be?w=400&h=300&fit=crop',
    'canada': 'https://images.unsplash.com/photo-1517935706615-2717063c2225?w=400&h=300&fit=crop',
    'france': 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=400&h=300&fit=crop',
    'japan': 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400&h=300&fit=crop',
    'germany': 'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?w=400&h=300&fit=crop',
    'italy': 'https://images.unsplash.com/photo-1515542622106-78bda8ba0e5b?w=400&h=300&fit=crop',
    'malaysia': 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=400&h=300&fit=crop',
    'turkey': 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=400&h=300&fit=crop',
    'egypt': 'https://images.unsplash.com/photo-1539768942893-daf53e736b68?w=400&h=300&fit=crop',
    'south korea': 'https://images.unsplash.com/photo-1538485399081-7191377e8241?w=400&h=300&fit=crop',
    'sri lanka': 'https://images.unsplash.com/photo-1586523969039-0e054791d8f1?w=400&h=300&fit=crop',
  };
  for (final entry in images.entries) {
    if (key.contains(entry.key) || entry.key.contains(key)) return entry.value;
  }
  return '';
}

class VisaBookingCard extends StatelessWidget {
  final TripItem visa;
  final VoidCallback onDetails;

  const VisaBookingCard({super.key, required this.visa, required this.onDetails});

  TripStatus get _badge {
    final t = visa.tracker;
    if (t.rejected) return const TripStatus(TripStatusKind.cancelled, 'Rejected');
    if (t.approved) return const TripStatus(TripStatusKind.completed, 'Approved');
    if (t.started) return const TripStatus(TripStatusKind.confirmed, 'In Progress');
    final raw = visa.status.isNotEmpty ? visa.status : 'Pending';
    return TripStatus(
      raw.toLowerCase().contains('cancel') ? TripStatusKind.cancelled : TripStatusKind.processing,
      raw,
    );
  }

  @override
  Widget build(BuildContext context) {
    final applicants = int.tryParse(visa.applicantCount) ?? 0;
    final title = [
      if (visa.destination.isNotEmpty) visa.destination,
      if (visa.type.isNotEmpty) '– ${visa.type}',
    ].join(' ');
    final badge = _badge;
    final imageUrl = _destinationImage(visa.destination);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(context.fx(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(context.fx(16)),
        onTap: onDetails,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(context.fx(16)),
            border: Border.all(color: _kLine),
            boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 3))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status badge top-right
              Align(alignment: Alignment.centerRight, child: _badgeChip(context, badge)),

              Padding(
                padding: EdgeInsets.fromLTRB(context.fx(14), context.fx(2), context.fx(14), context.fx(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Destination image + title row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Destination image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(context.fx(10)),
                          child: SizedBox(
                            width: context.fx(56),
                            height: context.fx(56),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _fallbackIcon(context),
                                  )
                                : _fallbackIcon(context),
                          ),
                        ),
                        SizedBox(width: context.fx(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title.isNotEmpty ? title : 'Visa Application',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: context.ffs(15),
                                  fontWeight: FontWeight.w600,
                                  color: _kInk,
                                ),
                              ),
                              SizedBox(height: context.fx(3)),
                              if (applicants > 0)
                                Row(
                                  children: [
                                    Icon(Icons.person_outline_rounded, size: context.fx(14), color: _kMuted),
                                    SizedBox(width: context.fx(4)),
                                    Text(
                                      'Travellers: $applicants Applicant${applicants == 1 ? '' : 's'}',
                                      style: TextStyle(fontSize: context.ffs(11.5), color: _kMuted),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Rejection reason
                    if (visa.tracker.rejected && visa.tracker.rejectionReason.isNotEmpty) ...[
                      SizedBox(height: context.fx(12)),
                      Container(
                        padding: EdgeInsets.all(context.fx(10)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE8E8),
                          borderRadius: BorderRadius.circular(context.fx(10)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, size: context.fx(14), color: const Color(0xFFB42318)),
                            SizedBox(width: context.fx(6)),
                            Expanded(
                              child: Text(
                                'Reason: ${visa.tracker.rejectionReason}',
                                style: TextStyle(fontSize: context.ffs(11.5), color: const Color(0xFFB42318)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Stepper
                    if (visa.tracker.started) ...[
                      SizedBox(height: context.fx(16)),
                      _Stepper(steps: visa.tracker.steps),
                    ],

                    // Divider
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: context.fx(12)),
                      child: const TripDashedLine(color: Color(0xFFD5D9E0)),
                    ),

                    // Footer: booking ID + view details
                    Row(
                      children: [
                        Icon(Icons.confirmation_number_outlined, size: context.fx(14), color: _kMuted),
                        SizedBox(width: context.fx(5)),
                        Expanded(
                          child: Text(
                            'Booking ID: ${visa.bookingId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: context.ffs(11.5), color: const Color(0xFF4B5563)),
                          ),
                        ),
                        SizedBox(width: context.fx(6)),
                        Text(
                          'View details',
                          style: TextStyle(
                            fontSize: context.ffs(11.5),
                            fontWeight: FontWeight.w500,
                            color: AppColors.AppBlue,
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: context.fx(16), color: AppColors.AppBlue),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackIcon(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE9F6FD),
        borderRadius: BorderRadius.circular(context.fx(10)),
      ),
      child: Icon(Icons.public_rounded, size: context.fx(28), color: AppColors.AppBlue),
    );
  }

  Widget _badgeChip(BuildContext context, TripStatus s) {
    final isRejected = s.kind == TripStatusKind.cancelled;
    return Container(
      margin: EdgeInsets.only(top: context.fx(10), right: context.fx(10), bottom: context.fx(6)),
      padding: EdgeInsets.symmetric(horizontal: context.fx(12), vertical: context.fx(5)),
      decoration: BoxDecoration(
        color: s.color,
        borderRadius: BorderRadius.circular(context.fx(20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isRejected)
            Icon(Icons.close_rounded, size: context.fx(12), color: Colors.white)
          else ...[
            Container(
              width: context.fx(6),
              height: context.fx(6),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ],
          SizedBox(width: context.fx(5)),
          Text(
            s.label,
            style: TextStyle(fontSize: context.ffs(11.5), fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final List<VisaTrackerStep> steps;

  const _Stepper({required this.steps});

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    final circle = context.fx(20);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i == 0 ? Colors.transparent : (steps[i].done ? AppColors.AppBlue : _kStepOff),
                      ),
                    ),
                    Container(
                      width: circle,
                      height: circle,
                      decoration: BoxDecoration(
                        color: steps[i].done ? AppColors.AppBlue : _kStepOff,
                        shape: BoxShape.circle,
                      ),
                      child: steps[i].done
                          ? Icon(Icons.check_rounded, size: circle * 0.65, color: Colors.white)
                          : null,
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i == steps.length - 1
                            ? Colors.transparent
                            : (steps[i + 1].done ? AppColors.AppBlue : _kStepOff),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.fx(5)),
                Text(
                  steps[i].label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: context.ffs(9),
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: steps[i].done ? _kInk : const Color(0xFF9CA3AF),
                  ),
                ),
                SizedBox(height: context.fx(2)),
                Text(
                  steps[i].done ? _stepDate(steps[i].date) : '',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: TextStyle(fontSize: context.ffs(8), color: _kMuted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
