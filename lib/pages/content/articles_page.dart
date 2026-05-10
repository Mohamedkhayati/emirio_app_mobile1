import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/cms_article_model.dart';
import '../../core/services/cms_service.dart';

class ArticlesPage extends StatelessWidget {
  const ArticlesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Articles'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<CmsArticle>>(
        future: CmsService.fetchArticles(),
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('No articles found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final a = items[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(a.summary ?? ''),
                  onTap: () => Navigator.pushNamed(context, '/articles/${a.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}