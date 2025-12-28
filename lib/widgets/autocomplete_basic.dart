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
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (value) => onFieldSubmitted(),
          style: TextStyle(
            color: controller.text.isNotEmpty ? const Color.fromARGB(255, 0, 238, 255) : Colors.white,
            fontWeight: controller.text.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
          ),
          decoration: const InputDecoration(
            hintText: 'Search artists',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: const BorderSide(color: Color.fromARGB(255, 0, 238, 255)),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelectedLocal, optionsLocal) {
        return Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 180, maxWidth: 380),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 9, 27, 29),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: optionsLocal.length,
              itemBuilder: (context, index) {
                final option = optionsLocal.elementAt(index);
                return ListTile(
                  dense: true,
                  title: Text(option, style: const TextStyle(color: Colors.white)),
                  onTap: () => onSelectedLocal(option),
                );
              },
            ),
          ),
        );
      },
      onSelected: onSelected,
    );
  }
}
