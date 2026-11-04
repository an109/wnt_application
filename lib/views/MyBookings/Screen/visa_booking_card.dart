import 'package:flutter/material.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';
import 'package:wander_nova/core/resources/app_colours.dart';

import '../../UpcomingTrips/data/models/tripModel.dart';
import '../../UpcomingTrips/domain/entity/upcomingTrip_entity.dart';
import 'trip_card.dart' show TripDashedLine, TripIconTile, TripStatus, TripStatusKind;

// Visa booking card from the Figma "My Bookings" frames: destination, status
// badge, the six-step tracker the CRM team moves the application along, then
// the booking id and "View details".

const Color _kInk = Color(0xFF111527);
const Color _kMuted = Color(0xFF6B7280);
const Color _kLine = Color(0xFFE5E7EB);
const Color _kStepOff = Color(0xFFDCEFFA);

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _stepDate(String? iso) {
  final d = DateTime.tryParse(iso ?? '')?.toLocal();
  return d == null ? '' : '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';
}

class VisaBookingCard extends StatelessWidget {
  final TripItem visa;
  final VoidCallback onDetails;

  const VisaBookingCard({super.key, required this.visa, required this.onDetails});

  /// Badge: where the application is. Before payment there is no tracker yet,
  /// so it shows what the customer still has to do.
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
      if (visa.destination.isNotEmpty) visa.destination else 'Visa',
      if (visa.type.isNotEmpty) visa.type,
    ].join(' – ');
    final badge = _badge;

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
              Align(alignment: Alignment.centerRight, child: _badgeChip(context, badge)),
              Padding(
                padding: EdgeInsets.fromLTRB(context.fx(14), context.fx(2), context.fx(14), context.fx(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: context.fx(48), height: context.fx(48), child: const TripIconTile(icon: Icons.assignment_rounded)),
                        SizedBox(width: context.fx(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: context.ffs(15), fontWeight: FontWeight.w600, color: _kInk),
                              ),
                              if (applicants > 0)
                                Text(
                                  'Travellers: $applicants Applicant${applicants == 1 ? '' : 's'}',
                                  style: TextStyle(fontSize: context.ffs(11.5), color: _kMuted),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (visa.tracker.rejected && visa.tracker.rejectionReason.isNotEmpty) ...[
                      SizedBox(height: context.fx(10)),
                      Container(
                        padding: EdgeInsets.all(context.fx(10)),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE8E8),
                          borderRadius: BorderRadius.circular(context.fx(10)),
                        ),
                        child: Text(
                          'Reason: ${visa.tracker.rejectionReason}',
                          style: TextStyle(fontSize: context.ffs(11.5), color: const Color(0xFFB42318)),
                        ),
                      ),
                    ],
                    if (visa.tracker.started) ...[
                      SizedBox(height: context.fx(16)),
                      _Stepper(steps: visa.tracker.steps),
                    ],
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: context.fx(12)),
                      child: const TripDashedLine(color: Color(0xFFD5D9E0)),
                    ),
                    Row(
                      children: [
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

  Widget _badgeChip(BuildContext context, TripStatus s) {
    return Container(
      margin: EdgeInsets.only(top: context.fx(10), right: context.fx(10), bottom: context.fx(6)),
      padding: EdgeInsets.symmetric(horizontal: context.fx(12), vertical: context.fx(4)),
      decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(context.fx(20))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: context.fx(6), height: context.fx(6), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          SizedBox(width: context.fx(5)),
          Text(s.label, style: TextStyle(fontSize: context.ffs(11.5), fontWeight: FontWeight.w500, color: Colors.white)),
        ],
      ),
    );
  }
}

/// Six circles joined by a line; reached steps are filled and ticked, with
/// the date they were reached under the label.
class _Stepper extends StatelessWidget {
  final List<VisaTrackerStep> steps;

  const _Stepper({required this.steps});

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();
    final circle = context.fx(18);
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
                      decoration: BoxDecoration(color: steps[i].done ? AppColors.AppBlue : _kStepOff, shape: BoxShape.circle),
                      child: steps[i].done ? Icon(Icons.check_rounded, size: circle * 0.7, color: Colors.white) : null,
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
                SizedBox(height: context.fx(6)),
                Text(
                  steps[i].label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: context.ffs(9.5),
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: steps[i].done ? _kInk : const Color(0xFF9CA3AF),
                  ),
                ),
                SizedBox(height: context.fx(2)),
                Text(
                  steps[i].done ? _stepDate(steps[i].date) : '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(fontSize: context.ffs(8.5), color: _kMuted),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
