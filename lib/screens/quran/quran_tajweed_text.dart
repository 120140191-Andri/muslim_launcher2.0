import 'package:flutter/material.dart';

class TajweedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextDirection textDirection;

  // Cache to store parsed spans and avoid redundant regex work
  static final Map<String, List<InlineSpan>> _parseCache = {};
  static final RegExp _tajweedRegex = RegExp(r'\[([a-z])(:\d+)?\[([^\]]+)\]');

  const TajweedText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.right,
    this.textDirection = TextDirection.rtl,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: textAlign,
      textDirection: textDirection,
      text: TextSpan(
        style: style ?? const TextStyle(color: Colors.black, fontSize: 24, fontFamily: 'Amiri', height: 2.2),
        children: _parseCache[text] ??= _parseTajweed(text),
      ),
    );
  }

  List<InlineSpan> _parseTajweed(String rawText) {
    final List<InlineSpan> spans = [];
    int lastMatchEnd = 0;
    
    for (final Match match in _tajweedRegex.allMatches(rawText)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: rawText.substring(lastMatchEnd, match.start)));
      }
      
      final String code = match.group(1)!;
      final String tajweedText = match.group(3)!;
      
      spans.add(TextSpan(
        text: tajweedText,
        style: TextStyle(color: _getColorForCode(code)),
      ));
      
      lastMatchEnd = match.end;
    }
    
    if (lastMatchEnd < rawText.length) {
      spans.add(TextSpan(text: rawText.substring(lastMatchEnd)));
    }
    
    return spans;
  }

  Color _getColorForCode(String code) {
    // GlobalQuran Tajweed Color Mappings
    switch (code) {
      case 'n': // Ghunnah
      case 'm': // Idgham Bighunnah
      case 'g': // Idgham Mutajanisayn
      case 'w': // Ikhfa Shafawi
      case 'i': // Iqlab
      case 'f': // Ikhfa
        return Colors.green.shade700;
        
      case 'a': // Idgham Mutamaathilayn
      case 'u': // Idgham Bila Ghunnah
      case 'c': // Ikhfa
        return Colors.green.shade500;
        
      case 'p': // Qalqalah
      case 'q': // Qalqalah
      case 'd': // Qalqalah
        return Colors.blue.shade700;
        
      case 'o': // Madd
      case 's': // Madd
      case 'l': // Madd
        return Colors.red.shade700;

      case 'h': // Hamzatul Wasl (usually grayed out)
        return Colors.grey.shade500;
        
      default:
        // Default to a distinct color if rule unknown to help debugging
        return Colors.deepPurple; 
    }
  }
}
