import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

class AsyncAutocomplete<T> extends StatefulWidget {
  const AsyncAutocomplete({
    super.key,
    required this.control,
    required this.source,
    required this.controlBuilder,
    required this.suggestionBuilder,
  });

  final AbstractControl<T> control;
  final Future<List<Suggestion<T>>> Function(T? query) source;
  final Widget Function(BuildContext context, FocusNode focusNode) controlBuilder;
  final Widget Function(BuildContext context, Suggestion<T> suggestion) suggestionBuilder;

  @override
  State<AsyncAutocomplete<T>> createState() => _AsyncAutocompleteState<T>();
}

class _AsyncAutocompleteState<T> extends State<AsyncAutocomplete<T>> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;
  List<Suggestion<T>> _lastSuggestions = [];

  final StreamController<List<Suggestion<T>>> _suggestionsStreamController =
  StreamController<List<Suggestion<T>>>.broadcast();

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        final isFocused = _focusNode.hasFocus;
        if (isFocused) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      });
    });

    widget.control.valueChanges.listen((query) {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () async {
        final suggestions = await widget.source(query);
        _lastSuggestions = suggestions;
        _suggestionsStreamController.add(suggestions);
      });
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.dispose();
    _suggestionsStreamController.close();
    _debounce?.cancel();
    super.dispose();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: MediaQuery.of(context).size.width - 32,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56),
            child: Material(
              type: MaterialType.card,
              elevation: 4,
              child: StreamBuilder<List<Suggestion<T>>>(
                initialData: _lastSuggestions,
                stream: _suggestionsStreamController.stream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 200,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final suggestion = snapshot.data![index];
                        return InkWell(
                          onTap: () {
                            widget.control.updateValue(suggestion.value);
                          },
                          child: widget.suggestionBuilder(context, suggestion),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: widget.controlBuilder(context, _focusNode),
    );
  }
}

class Suggestion<T> {
  final String label;
  final T value;

  Suggestion({required this.label, required this.value});
}
