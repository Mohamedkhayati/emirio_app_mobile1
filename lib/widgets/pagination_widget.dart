import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class PaginationWidget extends StatelessWidget {
  final int total;
  final int page;
  final int rowsPerPage;
  final Function(int) onPageChanged;
  final Function(int) onRowsPerPageChanged;
  final List<int> rowsOptions;

  const PaginationWidget({
    super.key,
    required this.total,
    required this.page,
    required this.rowsPerPage,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
    this.rowsOptions = const [3, 5, 10, 25, 50],
  });

  int get totalPages => total == 0 ? 1 : (total / rowsPerPage).ceil();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pagination controls
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.first_page, size: 20),
                onPressed: page == 1 ? null : () => onPageChanged(1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: page == 1 ? null : () => onPageChanged(page - 1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  '$page / $totalPages',
                  style: const TextStyle(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: page == totalPages ? null : () => onPageChanged(page + 1),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              IconButton(
                icon: const Icon(Icons.last_page, size: 20),
                onPressed: page == totalPages ? null : () => onPageChanged(totalPages),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Rows per page selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Rows per page: ', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButton<int>(
                value: rowsPerPage,
                underline: const SizedBox(),
                dropdownColor: AppColors.surface,
                items: rowsOptions.map((value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(value.toString(), style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) onRowsPerPageChanged(value);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}