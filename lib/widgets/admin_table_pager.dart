import 'package:flutter/material.dart';

class AdminTablePager extends StatelessWidget {
  final int total;
  final int currentPage;
  final int rowsPerPage;
  final List<int> rowsOptions;
  final Function(int) onPageChanged;
  final Function(int) onRowsChanged;

  const AdminTablePager({
    super.key,
    required this.total,
    required this.currentPage,
    required this.rowsPerPage,
    required this.onPageChanged,
    required this.onRowsChanged,
    this.rowsOptions = const [3, 5, 10, 25, 50],
  });

  @override
  Widget build(BuildContext context) {
    final int totalPages = (total / rowsPerPage).ceil().clamp(1, 9999);
    final int start = total == 0 ? 0 : ((currentPage - 1) * rowsPerPage) + 1;
    final int end = (currentPage * rowsPerPage).clamp(0, total);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE9ECF8))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Showing X to Y of Z
          Text(
            'Showing $start to $end of $total entries',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),

          // Center: Rows per page dropdown
          Row(
            children: [
              const Text('Rows: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
              DropdownButton<int>(
                value: rowsPerPage,
                isDense: true,
                underline: const SizedBox(),
                items: rowsOptions.map((int val) {
                  return DropdownMenuItem<int>(value: val, child: Text('$val'));
                }).toList(),
                onChanged: (val) {
                  if (val != null) onRowsChanged(val);
                },
              ),
            ],
          ),

          // Right: Pagination Controls
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
                color: currentPage > 1 ? Colors.black : Colors.grey,
              ),
              Text('Page $currentPage of $totalPages', style: const TextStyle(fontSize: 13)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
                color: currentPage < totalPages ? Colors.black : Colors.grey,
              ),
            ],
          )
        ],
      ),
    );
  }
}