import 'package:flutter/material.dart';
import '../../../../../core/utils/utils.dart';

/// The scrollable terms and conditions text container with a purple accent line.
class TermsScrollableContent extends StatelessWidget {
  const TermsScrollableContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Scrollable Text Content
          Padding(
            padding: EdgeInsets.only(
              left: ResponsiveUtils.spacing(context, 16),
              top: ResponsiveUtils.spacing(context, 16),
              right: ResponsiveUtils.spacing(context, 24),
              bottom: ResponsiveUtils.spacing(context, 16),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Terms and Conditions (Rider)'),
                  SizedBox(height: ResponsiveUtils.spacing(context, 8)),
                  _buildSectionText(
                    context,
                    'These terms and conditions ("Terms") govern the relationship between LeSgo Courier Services ("Company") and the individual (referred to as "Rider") engaged to provide delivery services through the Company\'s platform. By accepting to become a Rider, you acknowledge and agree to adhere to the following terms:\n\n'
                    '1. ENGAGEMENT\n\n'
                    'The Rider agrees to provide delivery services to customers on behalf of the Company using the designated platform or application. The Rider acknowledges that they are an independent contractor and not an employee of the Company.\n\n'
                    '2. ELIGIBILITY\n\n'
                    'The Rider must meet all eligibility criteria set forth by the Company, including but not limited to age, vehicle ownership, valid license, insurance, and ability to legally work in the operating region.\n\n'
                    '3. CONDUCT\n\n'
                    'The Rider shall conduct themselves in a professional and courteous manner at all times when representing the Company. This includes adhering to traffic laws, respecting customers\' property, and following any specific instructions provided by the Company.\n\n'
                    '4. SAFETY\n\n'
                    'The Rider shall prioritize safety during all deliveries. This includes ensuring that the vehicle is roadworthy, using appropriate safety gear, and taking necessary precautions to secure the delivery items.\n\n'
                    '5. DELIVERY STANDARDS\n\n'
                    'The Rider agrees to meet the delivery standards set by the Company, including but not limited to delivery times, order accuracy, and customer satisfaction.\n\n'
                    '6. PAYMENT\n\n'
                    'The Rider shall be compensated according to the payment structure agreed upon with the Company. Payment may be based on factors such as distance, time, and order volume.\n\n'
                    '7. CONFIDENTIALITY\n\n'
                    'The Rider shall maintain the confidentiality of any proprietary information or customer data obtained during the course of their engagement with the Company.\n\n'
                    '8. INSURANCE\n\n'
                    'The Rider acknowledges that they are responsible for obtaining and maintaining appropriate insurance coverage for their vehicle and personal liability. The Company is not obligated to cover expenses arising from accidents involving its riders.\n\n'
                    '9. TERMINATION\n\n'
                    'Either party may terminate this agreement at any time with or without cause. Upon termination, the Rider shall cease using the Company\'s platform and return any Company property in their possession.\n\n'
                    '10. INDEMNIFICATION\n\n'
                    'The Rider agrees to indemnify and hold harmless the Company from any claims, damages, or liabilities arising from their actions or omissions while providing delivery services.\n\n'
                    '11. MODIFICATION\n\n'
                    'The Company reserves the right to modify these Terms at any time. The Rider will be notified of any changes, and continued use of the platform constitutes acceptance of the modified Terms.\n\n'
                    '12. GOVERNING LAW\n\n'
                    'These Terms shall be governed by and construed in accordance with the laws of the Philippines. Any disputes arising out of or relating to these Terms shall be resolved through arbitration.\n\n'
                    '13. REGISTRATION FEE\n\n'
                    'The Rider is required to pay a registration fee that varies according to certain packages. This is mainly for the use of the platform that may include the following items depending on their procured package plan: Uniform, LeSgo bag, Helmet, Motorcycle Bag bracket.\n\n'
                    '14. LOAD PAYMENT\n\n'
                    'The Rider is required to remit a predetermined "load" amount of their choosing to the Company to facilitate the receipt of bookings and delivery assignments. Said amount constitutes the Company\'s share of each transaction conducted by the Rider. The load payment made by the Rider is nonrefundable but may be utilized for subsequent transactions until the entire sum is exhausted. Nevertheless, in the event of termination or resignation, the Company is obligated to refund the load amount to the Rider. This reimbursement shall be promptly executed upon the return of all Company equipment by the Rider.\n\n'
                    '15. DAMAGES COMPENSATION\n\n'
                    'Riders are mandated to either replace or provide compensation for any incurred damages to items, spillage of food or beverages, or mishandling of parcels transpiring during the execution of their delivery duties. Under the principle of "Your Delivery, Your Cargo," the Rider assumes full responsibility for such occurrences.\n\n'
                    '16. RIDER EARNINGS\n\n'
                    'Riders earn thru profit sharing with the Company and is varying mainly through their acquired rider package plan and type of service performed.\n\n'
                    '17. ONLINE PAYMENTS\n\n'
                    'Online payments will be disbursed directly to the Rider\'s account in that delivery by the clerk/system.\n\n'
                    '18. NON-DISCLOSURE AGREEMENT (NDA)\n\n'
                    'Riders are required to sign a Non-disclosure Agreement with LeSgo upon becoming a LeSgo Rider. The Company reserves all rights for legal and criminal action in the event of a violation of the NDA.\n\n'
                    '19. LEGAL LIABILITY\n\n'
                    'The Company holds no liability for any road rules or laws that the Rider may breach during their engagement.\n\n'
                    '20. GAS AND MAINTENANCE EXPENSES\n\n'
                    'Gas and maintenance expenses are the responsibility of the Rider.\n\n'
                    '21. MODIFICATION OF AGREEMENTS\n\n'
                    'Agreements may be subject to change without prior notice. Riders have the responsibility to regularly review the terms.\n\n'
                    '22. ACCURACY OF INFORMATION\n\n'
                    'Riders must accurately fill out forms or provide formal documents with truthful and precise contents. Riders shall provide any proof of identity as reasonably requested by the Company.\n\n'
                    '23. SINGLE ACCOUNT POLICY\n\n'
                    'Riders are limited to maintaining only one account.\n\n'
                    '24. REPORTING EXPLOITATION\n\n'
                    'Any known exploitation of the system aimed at harassing, undermining, or damaging the platform or the Company is the responsibility of the Rider to report to management.\n\n'
                    '25. REIMBURSEMENT FOR FAKE BOOKINGS\n\n'
                    'The supposed earning and value of the product bought by the Rider due to a fake booking will be reimbursed by the Company.\n\n'
                    '26. DELIVERY RATES\n\n'
                    'The Rider acknowledges that delivery rates may change without prior notice. It is the Rider\'s responsibility to stay updated on any changes in delivery rates.\n\n'
                    '27. LOYALTY PROGRAM\n\n'
                    'The Rider may be eligible to enjoy the loyalty program benefits once consistent duty is met with a straight 4 or 5 star rating and no records of warnings within the 3 consecutive months time.\n\n'
                    'By accepting these Terms, the Rider acknowledges that they have read, understood, and agree to abide by all provisions outlined herein.',
                  ),
                  SizedBox(height: ResponsiveUtils.spacing(context, 16)),
                ],
              ),
            ),
          ),

          // Purple Accent Line (Right Side)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF5F2D82).withValues(alpha: 0.3),
                    const Color(0xFF5F2D82),
                    const Color(0xFF5F2D82).withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, 16),
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSectionText(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'TT Fors',
        fontSize: ResponsiveUtils.fontSize(context, 12),
        fontWeight: FontWeight.w400,
        color: Colors.black87,
        height: 1.4,
      ),
    );
  }
}
