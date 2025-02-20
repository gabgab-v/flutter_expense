import 'package:expense_tracker_new/utils/icons_list.dart';
import 'package:flutter/material.dart';

class CategoryDropdown extends StatelessWidget {
  CategoryDropdown({super.key, this.cattype, required this.onChanged});
  final String? cattype;
  final ValueChanged<String?> onChanged;
  var appIcons = AppIcons();

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: appIcons.homeExpensesCategories.any((e) => e['name'] == cattype)
          ? cattype
          : null,
      isExpanded: true,
      hint: const Text("Select Category"),
      items: appIcons.homeExpensesCategories.map((e) {
        return DropdownMenuItem<String>(
          value: e['name'],
          child: Row(
            children: [
              Icon(e['icon'], color: Colors.black54),
              const SizedBox(width: 10),
              Text(e['name'], style: const TextStyle(color: Colors.black54)),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
