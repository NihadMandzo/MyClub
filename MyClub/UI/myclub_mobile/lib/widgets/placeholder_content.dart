import 'package:flutter/material.dart';
import '../utility/responsive_helper.dart';

class PlaceholderContent extends StatelessWidget {
  final String screenName;

  const PlaceholderContent({
    Key? key,
    required this.screenName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'This $screenName screen works',
        style: TextStyle(
          fontSize: ResponsiveHelper.font(context, base: 24),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
