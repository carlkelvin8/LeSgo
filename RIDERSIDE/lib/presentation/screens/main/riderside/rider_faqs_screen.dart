import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/api_service.dart';
import '../../../../core/utils/app_localization.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../widgets/common/retry_widget.dart';

class RiderFaqsScreen extends ConsumerStatefulWidget {
  const RiderFaqsScreen({super.key});

  @override
  ConsumerState<RiderFaqsScreen> createState() => _RiderFaqsScreenState();
}

class _RiderFaqsScreenState extends ConsumerState<RiderFaqsScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _categories = [];
  List<dynamic> _articles = [];
  int? _selectedCategoryId;
  bool _loading = true;
  bool _searching = false;
  String? _error;
  final Set<int> _votedArticleIds = {};

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getFaqCategories(),
        ApiService.getFaqArticles(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0];
        _articles = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.extractError(e);
        _loading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searching = false;
        _selectedCategoryId = null;
      });
      await _loadInitial();
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final articles = await ApiService.searchFaqArticles(trimmed);
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.extractError(e);
        _searching = false;
      });
    }
  }

  Future<void> _loadCategory(int? categoryId) async {
    setState(() {
      _selectedCategoryId = categoryId;
      _searchController.clear();
      _searching = false;
      _loading = true;
      _error = null;
    });
    try {
      final articles = categoryId == null
          ? await ApiService.getFaqArticles()
          : await ApiService.getFaqArticlesByCategory(categoryId);
      if (!mounted) return;
      setState(() {
        _articles = articles;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = ApiService.extractError(e);
        _loading = false;
      });
    }
  }

  Future<void> _voteHelpful(int articleId, {required bool helpful}) async {
    if (_votedArticleIds.contains(articleId)) return;
    try {
      await ApiService.markFaqHelpful(articleId, helpful: helpful);
      if (!mounted) return;
      setState(() => _votedArticleIds.add(articleId));
      final l = ref.read(appLanguageProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(helpful ? AppLocalization.translate('thank_you_feedback', l) : AppLocalization.translate('feedback_recorded', l)),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiService.extractError(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF5F2D82),
        title: Text(AppLocalization.translate('faqs', lang), style: const TextStyle(fontFamily: 'TT Fors')),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(ResponsiveUtils.spacing(context, 16)),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppLocalization.translate('search_faqs', lang),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _search,
              onChanged: (value) {
                if (value.isEmpty) _search('');
              },
            ),
          ),
          if (_categories.isNotEmpty && !_searching)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.spacing(context, 16),
                ),
                children: [
                  _CategoryChip(
                    label: 'All',
                    selected: _selectedCategoryId == null,
                    onTap: () => _loadCategory(null),
                  ),
                  ..._categories.map((cat) {
                    final map = cat as Map<String, dynamic>;
                    final id = (map['id'] as num?)?.toInt();
                    if (id == null) return const SizedBox.shrink();
                    return _CategoryChip(
                      label: map['name']?.toString() ??
                          map['title']?.toString() ??
                          'Category',
                      selected: _selectedCategoryId == id,
                      onTap: () => _loadCategory(id),
                    );
                  }),
                ],
              ),
            ),
          Expanded(
            child: _loading || _searching
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF5F2D82)),
                  )
                : _error != null && _articles.isEmpty
                    ? RetryWidget(message: _error!, onRetry: _loadInitial)
                    : RefreshIndicator(
                        color: const Color(0xFF5F2D82),
                        onRefresh: () => _selectedCategoryId == null && !_searching
                            ? _loadInitial()
                            : _loadCategory(_selectedCategoryId),
                        child: _articles.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 80),
                                  Center(
                                    child: Text(
                                      'No FAQs found',
                                      style: TextStyle(fontFamily: 'TT Fors'),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(
                                  ResponsiveUtils.spacing(context, 16),
                                ),
                                itemCount: _articles.length,
                                itemBuilder: (context, index) {
                                  final faq =
                                      _articles[index] as Map<String, dynamic>;
                                  final articleId =
                                      (faq['id'] as num?)?.toInt() ?? index;
                                  final voted =
                                      _votedArticleIds.contains(articleId);
                                  return Card(
                                    margin: EdgeInsets.only(
                                      bottom: ResponsiveUtils.spacing(context, 10),
                                    ),
                                    child: ExpansionTile(
                                      title: Text(
                                        faq['title']?.toString() ?? 'Question',
                                        style: const TextStyle(
                                          fontFamily: 'TT Fors',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                faq['content']?.toString() ?? '',
                                                style: const TextStyle(
                                                  fontFamily: 'TT Fors',
                                                ),
                                              ),
                                              if (!voted) ...[
                                                const SizedBox(height: 12),
                                                Text(
                                                  'Was this helpful?',
                                                  style: TextStyle(
                                                    fontFamily: 'TT Fors',
                                                    fontSize: ResponsiveUtils
                                                        .fontSize(context, 13),
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    TextButton.icon(
                                                      onPressed: () =>
                                                          _voteHelpful(
                                                        articleId,
                                                        helpful: true,
                                                      ),
                                                      icon: const Icon(
                                                        Icons.thumb_up_outlined,
                                                        size: 18,
                                                      ),
                                                      label: Text(AppLocalization.translate('yes', lang)),
                                                    ),
                                                    TextButton.icon(
                                                      onPressed: () =>
                                                          _voteHelpful(
                                                        articleId,
                                                        helpful: false,
                                                      ),
                                                      icon: const Icon(
                                                        Icons.thumb_down_outlined,
                                                        size: 18,
                                                      ),
                                                      label: Text(AppLocalization.translate('no', lang)),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontFamily: 'TT Fors')),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFFE8D9F5),
        checkmarkColor: const Color(0xFF5F2D82),
      ),
    );
  }
}
