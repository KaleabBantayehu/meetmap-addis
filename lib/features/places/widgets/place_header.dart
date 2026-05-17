import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:meetmap_addis/core/constants/colors.dart';
import 'package:meetmap_addis/shared/models/place_model.dart';

class PlaceHeader extends StatelessWidget {
  const PlaceHeader({super.key, required this.place});

  final PlaceModel place;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 330,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.surface,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: _HeaderIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.maybePop(context),
          semanticLabel: 'Back',
        ),
      ),
      title: Text(
        'MeetMap Addis',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: FavoritePlaceButton(),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: place.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) {
                return const _HeaderImagePlaceholder();
              },
              errorWidget: (context, url, error) {
                return const _HeaderImageError();
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.34),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoritePlaceButton extends StatefulWidget {
  const FavoritePlaceButton({super.key});

  @override
  State<FavoritePlaceButton> createState() => _FavoritePlaceButtonState();
}

class _FavoritePlaceButtonState extends State<FavoritePlaceButton> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return _HeaderIconButton(
      icon: _isFavorite
          ? Icons.favorite_rounded
          : Icons.favorite_border_rounded,
      semanticLabel: _isFavorite ? 'Remove from saved places' : 'Save place',
      onTap: () {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      },
      iconColor: _isFavorite ? AppColors.error : AppColors.primary,
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: iconColor, size: 27),
          ),
        ),
      ),
    );
  }
}

class _HeaderImagePlaceholder extends StatelessWidget {
  const _HeaderImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.imagePlaceholder,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2.6,
        ),
      ),
    );
  }
}

class _HeaderImageError extends StatelessWidget {
  const _HeaderImageError();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.textSecondary,
          size: 42,
        ),
      ),
    );
  }
}
