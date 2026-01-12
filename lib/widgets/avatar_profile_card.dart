import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/avatar.dart';
import '../services/ipfs_service.dart';

class AvatarProfileCard extends StatelessWidget {
  final Avatar avatar;

  const AvatarProfileCard({
    super.key,
    required this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.primaryColor.withOpacity(0.1),
              AppConstants.secondaryColor.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusL),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Row(
            children: [
              // Avatar Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusXL),
                  border: Border.all(
                    color: AppConstants.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: avatar.avatarImage != null && avatar.avatarImage!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusXL),
                        child: _buildAvatarImage(avatar.avatarImage!, avatar.name, context),
                      )
                    : Center(
                        child: Text(
                          avatar.name[0].toUpperCase(),
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
              ),
              
              const SizedBox(width: AppConstants.spacingM),
              
              // Avatar Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            avatar.name,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (avatar.isSuperstarAvatar)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.spacingS,
                              vertical: AppConstants.spacingXS,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppConstants.powerGradient,
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: AppConstants.spacingXS),
                                Text(
                                  'Superstar',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    if (avatar.bio != null) ...[
                      const SizedBox(height: AppConstants.spacingXS),
                      Text(
                        avatar.bio!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppConstants.textSecondaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: AppConstants.spacingS),
                    
                    // Stats Row
                    Row(
                      children: [
                        _buildStatChip(
                          'Level ${avatar.totalLevel}',
                          Icons.trending_up,
                          AppConstants.primaryColor,
                        ),
                        const SizedBox(width: AppConstants.spacingS),
                        _buildStatChip(
                          '${avatar.totalExperience} XP',
                          Icons.flash_on,
                          AppConstants.accentColor,
                        ),
                        if (avatar.badges.isNotEmpty) ...[
                          const SizedBox(width: AppConstants.spacingS),
                          _buildStatChip(
                            '${avatar.badges.length} Badges',
                            Icons.emoji_events,
                            AppConstants.warningColor,
                          ),
                        ],
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

  Widget _buildStatChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: AppConstants.spacingXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusS),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: AppConstants.spacingXS),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(String imageUri, String name, BuildContext context) {
    final ipfsService = IPFSService();
    String imageUrl;
    
    if (imageUri.startsWith('ipfs://')) {
      // Convert IPFS URI to gateway URL
      imageUrl = ipfsService.getIPFSUrl(imageUri.replaceFirst('ipfs://', ''));
    } else if (imageUri.startsWith('http://') || imageUri.startsWith('https://')) {
      // Use HTTP/HTTPS URL as-is
      imageUrl = imageUri;
    } else {
      // Invalid URI, show placeholder
      return Center(
        child: Text(
          name[0].toUpperCase(),
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: AppConstants.primaryColor,
          ),
        ),
      );
    }
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Center(
          child: Text(
            name[0].toUpperCase(),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: AppConstants.primaryColor,
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: AppConstants.primaryColor.withOpacity(0.1),
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }
} 