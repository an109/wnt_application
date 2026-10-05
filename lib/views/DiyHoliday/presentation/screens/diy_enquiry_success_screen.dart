import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wander_nova/UI_helper/responsive_layout.dart';

import '../widgets/diy_common.dart';

/// Confirmation for **API 15 — POST /enquiry/**: shows the reference the
/// backend returned and sends the user back to the holiday home.
class DiyEnquirySuccessScreen extends StatelessWidget {
  final String reference;
  final String message;
  final String packageTitle;
  final double quotedTotal;
  final String currency;

  const DiyEnquirySuccessScreen({
    super.key,
    required this.reference,
    required this.packageTitle,
    required this.quotedTotal,
    this.message = '',
    this.currency = 'INR',
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(context.w(24)),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: context.w(84),
                  height: context.w(84),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: context.w(44),
                    color: Colors.green.shade600,
                  ),
                ),
                SizedBox(height: context.h(20)),
                Text(
                  'Enquiry sent',
                  style: TextStyle(
                    fontSize: context.fs(22),
                    fontWeight: FontWeight.w800,
                    color: DiyTokens.navy,
                  ),
                ),
                SizedBox(height: context.h(8)),
                Text(
                  message.isNotEmpty
                      ? message
                      : 'A holiday consultant will call you shortly about '
                            '"$packageTitle".',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.fs(13),
                    color: DiyTokens.subGrey,
                  ),
                ),
                SizedBox(height: context.h(22)),
                if (reference.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: reference));
                      diySnack(context, 'Reference copied');
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.w(16),
                        vertical: context.h(12),
                      ),
                      decoration: BoxDecoration(
                        color: DiyTokens.pageBg,
                        borderRadius: BorderRadius.circular(context.r(10)),
                        border: Border.all(color: DiyTokens.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reference',
                                style: TextStyle(
                                  fontSize: context.fs(10),
                                  color: DiyTokens.labelGrey,
                                ),
                              ),
                              Text(
                                reference,
                                style: TextStyle(
                                  fontSize: context.fs(14),
                                  fontWeight: FontWeight.w700,
                                  color: DiyTokens.navy,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: context.w(12)),
                          Icon(
                            Icons.copy_rounded,
                            size: context.w(16),
                            color: DiyTokens.blue,
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: context.h(14)),
                Text(
                  'Quoted total ${diyMoney(quotedTotal, currency: currency)}',
                  style: TextStyle(
                    fontSize: context.fs(12.5),
                    color: DiyTokens.subGrey,
                  ),
                ),
                const Spacer(),
                DiyPrimaryButton(
                  label: 'BACK TO HOLIDAYS',
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
