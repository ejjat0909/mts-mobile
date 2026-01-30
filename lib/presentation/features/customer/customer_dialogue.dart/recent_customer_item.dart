import 'package:flutter/material.dart';
import 'package:mts/core/config/constants.dart';
import 'package:mts/data/models/customer/customer_model.dart';

class RecentCustomerItem extends StatelessWidget {
  const RecentCustomerItem({
    super.key,
    required this.filteredCustomers,
    required this.press,
  });

  final CustomerModel filteredCustomers;
  final Function() press;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: white),
      ),
      title: Text(filteredCustomers.name ?? 'No Name'),
      subtitle: Text(filteredCustomers.phoneNo ?? ''),
      onTap: press,
    );
  }
}
