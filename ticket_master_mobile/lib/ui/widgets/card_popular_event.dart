import 'package:event_app/app/configs/colors.dart';
import 'package:event_app/data/event_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CardPopularEvent extends StatelessWidget {
  final EventModel eventModel;

  const CardPopularEvent({required this.eventModel, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 270,
      margin: const EdgeInsets.only(left: 8, right: 8),
      child: Stack(
        children: [
          _buildCardImage(),
          _buildCardDesc(),
        ],
      ),
    );
  }

  _buildCardImage() => Container(
        width: 250,
        height: 250,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: eventModel.image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: AppColors.primaryLightColor,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.primaryLightColor,
                  child: const Icon(
                    Icons.event,
                    size: 60,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  height: 50,
                  width: 35,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd').format(eventModel.date),
                      ),
                      Text(
                        DateFormat('MMM').format(eventModel.date),
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      );

  _buildCardDesc() => Positioned(
        bottom: 0,
        right: 0,
        left: 0,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(12)),
          child: ClipRect(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        eventModel.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 10, color: AppColors.primaryColor),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              eventModel.locationName,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.greyTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLightColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions, size: 13, color: AppColors.primaryColor),
                )
              ],
            ),
          ),
        ),
      );
}
