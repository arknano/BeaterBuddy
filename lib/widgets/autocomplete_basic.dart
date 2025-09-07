import 'package:flutter/material.dart';

class AutocompleteBasic extends StatelessWidget {
  const AutocompleteBasic({
    super.key,
    required this.options,
    required this.onSelected,
  });

  final List<String> options;
  final void Function(String) onSelected;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return options.where(
          (String option) => option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          ),
        );
      },
      onSelected: onSelected,
    );
  }
}
