import 'package:blacklist_plus_flutter/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:waypay_flutter_library/waypay_styles.dart';

class SearchDestination {
  const SearchDestination({
    required this.title,
    required this.route,
    required this.keywords,
  });

  final String title;
  final Routes route;
  final List<String> keywords;

  bool matches(String query) {
    final q = query.toLowerCase();
    bool softMatch(String a, String b) => a.contains(b) || b.contains(a);
    if (softMatch(title.toLowerCase(), q)) return true;
    return keywords.any((kw) => softMatch(kw.toLowerCase(), q));
  }
}

class SearchSuggester extends StatefulWidget {
  const SearchSuggester({super.key, required this.destinations});

  final List<SearchDestination> destinations;

  @override
  State<SearchSuggester> createState() => _SearchSuggesterState();
}

class _SearchSuggesterState extends State<SearchSuggester> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _link = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  final List<String> _history = [];
  List<String> _results = [];
  Size? _fieldSize;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _hideOverlay();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureField());
  }

  @override
  void dispose() {
    _hideOverlay();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _measureField() {
    final renderObject = _fieldKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox) return;
    if (!renderObject.hasSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureField());
      return;
    }
    if (!mounted) return;
    final size = renderObject.size;
    if (_fieldSize == size) return;
    setState(() {
      _fieldSize = size;
    });
  }

  void _onChanged(String raw) {
    final query = raw.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => _results = List.from(_history));
      _showOverlay();
      return;
    }
    final variants = _expandQueryVariants(query);
    final matches = widget.destinations
        .where((d) => variants.any((variant) => d.matches(variant)))
        .take(5)
        .map((d) => d.title)
        .toList();
    setState(() => _results = matches);
    if (_results.isNotEmpty) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _onSubmit(String raw) {
    final query = raw.trim().toLowerCase();
    if (query.isEmpty) return;
    final variants = _expandQueryVariants(query);
    final match = widget.destinations.firstWhere(
      (d) => variants.any((variant) => d.matches(variant)),
      orElse: () => const SearchDestination(
        title: '',
        route: Routes.homeScreen,
        keywords: [],
      ),
    );
    if (match.title.isEmpty) return;
    _goTo(match.title, match.route);
  }

  void _goTo(String title, Routes route) {
    context.pushNamed(route.toName);
    setState(() {
      _results = [];
      _controller.clear();
      _history
        ..removeWhere((item) => item.toLowerCase() == title.toLowerCase())
        ..insert(0, title);
      if (_history.length > 5) _history.removeRange(5, _history.length);
    });
    _hideOverlay();
    FocusScope.of(context).unfocus();
  }

  void _showOverlay() {
    if (_results.isEmpty) {
      _hideOverlay();
      return;
    }
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          offset: const Offset(0, 54),
          child: Material(
            color: Colors.transparent,
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: _fieldSize?.width ?? 360),
                child: _buildResultsCard(),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildResultsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: _results
            .map(
              (text) => ListTile(
                dense: true,
                title: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(AppColors.black),
                  ),
                ),
                onTap: () {
                  final match = widget.destinations.firstWhere(
                    (d) => d.title == text,
                    orElse: () => widget.destinations.first,
                  );
                  _goTo(text, match.route);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: SearchField(
        key: _fieldKey,
        hintText: 'Поиск',
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onChanged,
        onSubmitted: _onSubmit,
        onTap: () {
          if (_controller.text.isEmpty) {
            setState(() {
              _results = _history.isNotEmpty
                  ? List.from(_history)
                  : widget.destinations.take(5).map((d) => d.title).toList();
            });
            _showOverlay();
          }
        },
      ),
    );
  }

  List<String> _expandQueryVariants(String query) {
    final variants = <String>{query};
    final swapped = _swapKeyboardLayout(query);
    variants.add(swapped);
    return variants.toList();
  }

  String _swapKeyboardLayout(String input) {
    const ru = 'ёйцукенгшщзхъфывапролджэячсмитьбю';
    const en = '`qwertyuiop[]asdfghjkl;\'zxcvbnm,.';
    final map = <String, String>{};
    for (var i = 0; i < ru.length && i < en.length; i++) {
      map[ru[i]] = en[i];
      map[en[i]] = ru[i];
      map[ru[i].toUpperCase()] = en[i].toUpperCase();
      map[en[i].toUpperCase()] = ru[i].toUpperCase();
    }
    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      buffer.write(map[ch] ?? ch);
    }
    return buffer.toString().toLowerCase();
  }
}
