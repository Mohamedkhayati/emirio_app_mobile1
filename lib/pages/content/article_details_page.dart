import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/cms_article_model.dart';
import '../../core/services/cms_service.dart';

class ArticleDetailsPage extends StatelessWidget {
  final int articleId;
  const ArticleDetailsPage({super.key, required this.articleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<CmsArticle?>(
        future: CmsService.fetchArticleById(articleId),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          final article = snapshot.data;
          if (article == null) {
            return const Center(child: Text('Article not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                if (article.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(article.subtitle!, style: const TextStyle(color: AppColors.textGrey, fontSize: 16)),
                ],
                const SizedBox(height: 16),
                if (article.author != null || article.createdAt != null)
                  Text(
                    '${article.author ?? ''} ${article.createdAt ?? ''}'.trim(),
                    style: const TextStyle(color: AppColors.textGrey),
                  ),
                const SizedBox(height: 20),
                Text(article.content ?? article.summary ?? ''),
              ],
            ),
          );
        },
      ),
    );
  }
}