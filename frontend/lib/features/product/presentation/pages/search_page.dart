import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';

/// Trang tim kiem voi goi y va lich su tim kiem (TM03)
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    final q = query.trim();
    if (q.isNotEmpty) {
      final productProv = context.read<ProductProvider>();
      productProv.addSearchKeyword(q);
      productProv.setSearchQuery(q);
      Navigator.pop(context); // Quay ve man danh sach san pham da loc
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProv = context.watch<ProductProvider>();
    final suggestions = productProv.getSuggestions(_searchCtrl.text);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm áo sơ mi, polo, jeans...',
            border: InputBorder.none,
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Text("✕", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: _performSearch,
        ),
        actions: [
          TextButton(
            child: const Text('Tìm', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
            onPressed: () => _performSearch(_searchCtrl.text),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Neu dang go chu -> Hien thi goi y tu dong (TM03)
            if (_searchCtrl.text.trim().isNotEmpty) ...[
              const Text('Gợi ý tìm kiếm:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              if (suggestions.isEmpty)
                Text('Không có gợi ý nào khớp với "${_searchCtrl.text}"',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final sug = suggestions[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      
                      title: Text(sug, style: const TextStyle(fontSize: 14)),
                      trailing: const Text("↗", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      onTap: () => _performSearch(sug),
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],

            // Lich su tim kiem gan day (TM03)
            if (productProv.searchHistory.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Lịch sử tìm kiếm gần đây', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  TextButton(
                    onPressed: () => productProv.clearSearchHistory(),
                    child: const Text('Xóa tất cả', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: productProv.searchHistory.map((keyword) {
                  return InputChip(
                    label: Text(keyword, style: const TextStyle(fontSize: 13)),
                    backgroundColor: Colors.grey.shade100,
                    deleteIcon: const Text("✕", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    onDeleted: () => productProv.removeSearchKeyword(keyword),
                    onPressed: () => _performSearch(keyword),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Tu khoa tim kiem pho bien
            const Text('Từ khóa phổ biến', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Áo sơ mi trắng',
                'Quần jeans slimfit',
                'Áo polo nam',
                'Quần tây công sở',
                'Áo khoác bomber',
                'Voucher giảm giá',
              ].map((term) {
                return ActionChip(
                  label: Text(term, style: const TextStyle(fontSize: 13)),
                  backgroundColor: Colors.grey.shade100,
                  
                  onPressed: () => _performSearch(term),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

