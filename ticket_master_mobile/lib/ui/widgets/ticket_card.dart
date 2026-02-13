import 'package:event_app/app/configs/colors.dart';
import 'package:event_app/data/achat_model.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

/// ============================================================================
/// PROFESSIONAL WHITE TICKET CARD - Image 2 Style
/// ============================================================================
/// Features:
/// - WHITE background with subtle shadow
/// - "PAID" badge in Emerald Green with light background
/// - Event image, title, location, date
/// - Info chips: ticket count, days left
/// - Large "Show QR Code" button in Emerald Green
/// ============================================================================

class TicketCard extends StatelessWidget {
  final AchatModel ticket;
  final VoidCallback onShowQRCode;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.onShowQRCode,
  });

  @override
  Widget build(BuildContext context) {
    final isUpcoming = ticket.isUpcoming;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white, // WHITE BACKGROUND
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.greyTextColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: ticket.eventImage ?? '',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.greyTextColor.withValues(alpha: 0.2),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.primaryLightColor,
                      child: const Icon(
                        Icons.confirmation_number,
                        size: 32,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Event details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              ticket.eventLieu,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Title - Show real data or error
                      Text(
                        ticket.eventTitre,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ticket.eventTitre.contains('ERREUR') ? Colors.red : AppColors.textPrimaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      
                      // Date
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: AppColors.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              DateFormat('MMM d, yyyy • hh:mm a').format(ticket.eventDate),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // PAID badge - Emerald Green
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PAYÉ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Info chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildInfoChip(
                  '${ticket.quantite} billet${ticket.quantite > 1 ? 's' : ''}',
                  Icons.confirmation_number_outlined,
                ),
                const SizedBox(width: 8),
                if (isUpcoming)
                  _buildInfoChip(
                    '${ticket.daysLeft} jour${ticket.daysLeft != 1 ? 's' : ''}',
                    Icons.access_time,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Show QR Code button - LARGE and CENTERED
          if (isUpcoming)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onShowQRCode,
                  icon: const Icon(Icons.qr_code, size: 22),
                  label: const Text(
                    'Show QR Code',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor, // Emerald Green
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryLightColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
