import 'package:event_app/app/configs/colors.dart';
import 'package:event_app/data/event_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CardEventThisMonth extends StatelessWidget {
  final EventModel eventModel;

  const CardEventThisMonth({required this.eventModel, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate sales progress
    final totalStock = eventModel.totalStock ?? 1000;
    final stockRestant = eventModel.stockRestant ?? totalStock;
    final sold = totalStock - stockRestant;
    final progress = sold / totalStock;

    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.whiteColor,
        border: Border.all(color: AppColors.borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: eventModel.image,
              fit: BoxFit.cover,
              width: 70,
              height: double.infinity,
              placeholder: (context, url) => Container(
                width: 70,
                color: AppColors.primaryLightColor,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 70,
                color: AppColors.primaryLightColor,
                child: const Icon(
                  Icons.event,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  eventModel.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppColors.primaryColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        eventModel.locationName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.greyTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                // Sales Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.progressBackgroundColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.progressFillColor,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$sold/$totalStock vendus',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.greyTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 50,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLightColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('dd').format(eventModel.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(eventModel.date),
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
