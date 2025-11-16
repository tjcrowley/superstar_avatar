import 'package:flutter/material.dart';
import '../models/ticket.dart';
import '../services/qr_code_service.dart';
import '../constants/app_constants.dart';

class TicketQRCode extends StatelessWidget {
  final Ticket ticket;
  final double size;

  const TicketQRCode({
    super.key,
    required this.ticket,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final qrCodeService = QRCodeService();
    final qrData = qrCodeService.generateQRCodeData(ticket);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppConstants.shadowMedium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Event Ticket',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          qrCodeService.generateQRCodeWidget(
            data: qrData,
            size: size,
            backgroundColor: Colors.white,
            foregroundColor: AppConstants.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Ticket ID: ${ticket.ticketId.substring(0, 8)}...',
            style: TextStyle(
              fontSize: 12,
              color: AppConstants.textSecondaryColor,
            ),
          ),
          if (ticket.isCheckedIn) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppConstants.successColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Checked In',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConstants.successColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

