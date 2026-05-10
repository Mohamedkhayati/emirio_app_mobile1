class CmsArticle {
  final int id;
  final String title;
  final String? subtitle;
  final String? summary;
  final String? content;
  final String? imageUrl;
  final String? author;
  final String? createdAt;
  final bool published;

  const CmsArticle({
    required this.id,
    required this.title,
    this.subtitle,
    this.summary,
    this.content,
    this.imageUrl,
    this.author,
    this.createdAt,
    required this.published,
  });

  factory CmsArticle.fromJson(Map<String, dynamic> json) {
    return CmsArticle(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      summary: json['summary'] ?? json['description'],
      content: json['content'] ?? json['body'],
      imageUrl: json['imageUrl'] ?? json['image'],
      author: json['author'],
      createdAt: json['createdAt']?.toString(),
      published: json['published'] ?? true,
    );
  }
}