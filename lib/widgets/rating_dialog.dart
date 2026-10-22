import 'package:flutter/material.dart';
import '../widgets/luobo/luobo_toast.dart';
import 'package:flutter/cupertino.dart';
import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';

/// 评分弹窗：5 星 + 可选反馈，提交后记录评分并标记已评分。
/// 自旧 `settings_about_tab.dart` 的 `_showRatingDialog` 抽出，逻辑不变，
/// 供设置根页「为 Musly 评分」行复用。
Future<void> showRatingDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final ratingController = TextEditingController();
  int selectedRating = 5;

  final result = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(l10n.rateMusly),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.howWouldYouRate),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= selectedRating
                          ? CupertinoIcons.star_fill
                          : CupertinoIcons.star,
                      color: const Color(0xFFFFCC00),
                    ),
                    onPressed: () {
                      setDialogState(() => selectedRating = starIndex);
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 100),
                child: TextField(
                  controller: ratingController,
                  decoration: InputDecoration(
                    hintText: l10n.optionalFeedback,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.submit),
          ),
        ],
      ),
    ),
  );

  if (result == true) {
    await AnalyticsService().recordRating(
      selectedRating,
      ratingController.text,
    );
    await AnalyticsService().markAppAsRated();
    if (context.mounted) {
      showLuoboToast(
      context,
      message: l10n.thankYouFeedback,
      tone: LuoboToastTone.info,
    );
    }
  }
  ratingController.dispose();
}
