import 'package:flutter/material.dart';
import '../utility/responsive_helper.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  
  const PlaceholderScreen({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: ResponsiveHelper.iconSize(context) * 2.5,
            color: Colors.grey,
          ),
          SizedBox(height: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 12 : 16),
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 24),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveHelper.deviceSize(context) == DeviceSize.small ? 6 : 8),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: ResponsiveHelper.font(context, base: 16),
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
