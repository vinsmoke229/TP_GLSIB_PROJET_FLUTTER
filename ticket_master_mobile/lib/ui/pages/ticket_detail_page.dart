import 'package:event_app/app/configs/colors.dart';
import 'package:event_app/data/achat_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// ============================================================================
/// TICKET DETAIL PAGE - QR Code Display
/// ============================================================================
/// Features:
/// - Large, high-quality QR code
/// - Event details
/// - Scan instructions
/// - Professional ticket design
/// ============================================================================

class TicketDetailPage extends StatelessWidget {
  final AchatModel booking;

  const TicketDetailPage({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildAppBar(context),
              const SizedBox(height: 24),
              _buildTicketCard(context),
              const SizedBox(height: 32),
              _buildInstructions(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Build app bar
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.textPrimaryColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Your Ticket',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build ticket card
  Widget _buildTicketCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Event info section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event title
                Text(
                  booking.eventTitre ?? 'Événement',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                // Date
                _buildInfoRow(
                  Icons.calendar_today,
                  DateFormat('EEEE, MMMM d, yyyy')
                      .format(booking.eventDate ?? DateTime.now()),
                ),
                const SizedBox(height: 12),
                // Time
                _buildInfoRow(
                  Icons.access_time,
                  DateFormat('HH:mm')
                      .format(booking.eventDate ?? DateTime.now()),
                ),
                const SizedBox(height: 12),
                // Location
                _buildInfoRow(
                  Icons.location_on,
                  booking.eventLieu ?? 'Location TBD',
                ),
                const SizedBox(height: 16),
                // Divider
                Container(
                  height: 1,
                  color: AppColors.borderColor,
                ),
                const SizedBox(height: 16),
                // Ticket info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Type de Billet',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.ticketType ?? 'Standard',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Quantité',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'x${booking.quantite}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Dashed divider
          _buildDashedDivider(),
          // QR Code section
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.borderColor,
                      width: 2,
                    ),
                  ),
                  child:
                      booking.qrCodeUrl != null && booking.qrCodeUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: booking.qrCodeUrl!,
                              width: 220,
                              height: 220,
                              placeholder: (context, url) => const SizedBox(
                                width: 220,
                                height: 220,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => QrImageView(
                                data: booking.qrCode,
                                version: QrVersions.auto,
                                size: 220,
                                backgroundColor: Colors.white,
                                errorCorrectionLevel: QrErrorCorrectLevel.H,
                              ),
                            )
                          : QrImageView(
                              data: booking.qrCode,
                              version: QrVersions.auto,
                              size: 220,
                              backgroundColor: Colors.white,
                              errorCorrectionLevel: QrErrorCorrectLevel.H,
                            ),
                ),
                const SizedBox(height: 16),
                // Booking ID
                Text(
                  'ID: ${booking.qrCode}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryColor,
                    fontFamily: 'monospace',
                  ),
                ),
                // Status badge if used
                if (booking.estUtilise) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 16, color: Colors.red.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Ticket utilisé',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (booking.dateUtilisation != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Le ${DateFormat('dd/MM/yyyy à HH:mm').format(booking.dateUtilisation!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryColor,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.primaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Build dashed divider
  Widget _buildDashedDivider() {
    return Row(
      children: List.generate(
        40,
        (index) => Expanded(
          child: Container(
            height: 1,
            color: index.isEven ? AppColors.borderColor : Colors.transparent,
          ),
        ),
      ),
    );
  }

  /// Build instructions
  Widget _buildInstructions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLightColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.qr_code_scanner,
            size: 48,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 12),
          const Text(
            'Scan at Entrance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Present this QR code at the event entrance for verification. Make sure your screen brightness is at maximum for best scanning results.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
